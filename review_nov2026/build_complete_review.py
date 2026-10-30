"""Build the two-task review from verbatim notes and the complete manuscript diff.
Run from the project root: python3 review_nov2026/build_complete_review.py.
"""

from pathlib import Path
import base64
import csv
import difflib
import hashlib
import html
import json
import re
import subprocess
import tempfile

out = Path("review_nov2026")
path = "overleaf/optimal_stretching24.tex"
# Keep the review baseline fixed when later manuscript edits are committed.
base_revision = "907b3f82af0ad3ca08004d1043cf0618689739fa"
old_text = subprocess.check_output(
    ["git", "show", base_revision + ":" + path], text=True)
new_text = Path(path).read_text()
notes = (out / "revision_nov2026.md").read_text()
old = old_text.splitlines(keepends=True)
new = new_text.splitlines(keepends=True)

# Partition the changes by the two tasks, in their order in the notes.
# The intermediate version applies only task 1 to the baseline; task 2 takes it to
# the current manuscript. No changed line is omitted from the comparison.
def old_line(fragment):
    return next(i for i, line in enumerate(old) if fragment in line)

sensitivity_ranges = [
    (old_line('A more complex policy that attempts to reduce'), 1),
    (old_line('We conduct a sensitivity analysis where we reduce'), 1),
    (old_line('We conducted a sensitivity analysis in which'),
     old_line('cohorts. Fractional dosing can improve on full dosing') + 2
     - old_line('We conducted a sensitivity analysis in which')),
    (old_line('sigmoid dose-response function and for the slow-growing epidemic'), 2),
    (old_line('\\Section{Calibration for Slow-Growing Epidemic}'),
     old_line('\\begin{thebibliography}')
     - old_line('\\Section{Calibration for Slow-Growing Epidemic}')),
]
sensitivity_ranges = [(a, a + length) for a, length in sensitivity_ranges]
intermediate = []
changes = {1: [], 2: []}
for tag, i, j, k, l in difflib.SequenceMatcher(
        None, old, new, autojunk=False).get_opcodes():
    if tag == "equal":
        intermediate.extend(old[i:j])
        continue
    task = 2 if any(i < end and j > start or
                    i == j and start <= i < end
                    for start, end in sensitivity_ranges) else 1
    changes[task].append(dict(kind=tag, old_start=i + 1, old_end=j,
                              new_start=k + 1, new_end=l))
    intermediate.extend(new[k:l] if task == 1 else old[i:j])
assert changes[1] and changes[2]

# Applying the remaining changes to the intermediate text must give exactly
# the current file. These two patches therefore cover the complete diff.
assert len(changes[1]) + len(changes[2]) == sum(
    tag != "equal" for tag, *_ in
    difflib.SequenceMatcher(None, old, new, autojunk=False).get_opcodes())

def complete_blocks(lines):
    blocks = []
    abstract = next((i for i, line in enumerate(lines)
                     if r"\noindent {\bf Abstract:}" in line), None)
    if abstract is not None:
        end = next(i for i in range(abstract, len(lines)) if r"\vfill" in lines[i])
        while end > abstract and not lines[end - 1].strip():
            end -= 1
        blocks.append((abstract, end))
    for label in ["tab:results", "tab:compartment_values", "tab:sensitivity"]:
        index = next((i for i, line in enumerate(lines)
                      if "\\label{" + label + "}" in line), None)
        if index is not None:
            start = max(i for i in range(index) if r"\begin{table}" in lines[i])
            end = next(i for i in range(index, len(lines))
                       if r"\end{table}" in lines[i])
            blocks.append((start, end + 1))
    return blocks


def review_patch(before, after, context=3):
    rows = []
    old_offset = new_offset = 0
    for tag, i, j, k, l in difflib.SequenceMatcher(
            None, before, after, autojunk=False).get_opcodes():
        if tag == "equal":
            for old_index, new_index in zip(range(i, j), range(k, l)):
                rows.append((" ", before[old_index], old_offset, new_offset))
                old_offset += 1
                new_offset += 1
        else:
            for line in before[i:j]:
                rows.append(("-", line, old_offset, new_offset))
                old_offset += 1
            for line in after[k:l]:
                rows.append(("+", line, old_offset, new_offset))
                new_offset += 1
    changed = {i for i, row in enumerate(rows) if row[0] != " "}
    selected = set()
    for index in changed:
        selected.update(range(max(0, index - context),
                              min(len(rows), index + context + 1)))
    # Keep meaningful blocks whole, without importing adjacent sections.
    for side, lines in [(2, before), (3, after)]:
        for start, end in complete_blocks(lines):
            block_rows = {i for i, row in enumerate(rows)
                          if row[0] != ("+" if side == 2 else "-")
                          and start <= row[side] < end}
            if changed & block_rows:
                selected.update(block_rows)
    patch = "diff --git a/" + path + " b/" + path + "\n"
    patch += "--- a/" + path + "\n+++ b/" + path + "\n"
    indices = sorted(selected)
    groups = []
    for index in indices:
        if not groups or index != groups[-1][-1] + 1:
            groups.append([])
        groups[-1].append(index)
    for group in groups:
        hunk = [rows[i] for i in group]
        old_count = sum(row[0] != "+" for row in hunk)
        new_count = sum(row[0] != "-" for row in hunk)
        old_start = hunk[0][2] + bool(old_count)
        new_start = hunk[0][3] + bool(new_count)
        patch += f"@@ -{old_start},{old_count} +{new_start},{new_count} @@\n"
        patch += "".join(kind + line for kind, line, *_ in hunk)
    assert changed <= selected
    return patch


diff_pages = {}
for task, before, after, stem in [
    (1, old, intermediate, "initial_values"),
    (2, intermediate, new, "sensitivity_task"),
]:
    patch = review_patch(before, after)
    (out / (stem + ".diff")).write_text(patch)
    # The final page embeds these documents; intermediate HTML stays temporary.
    with tempfile.TemporaryDirectory(prefix="nov-review-html-") as work:
        display_patch = patch
        if task == 1:
            # The base-case introduction diff is displayed in the first section.
            # Keep the complete patch on disk for composition checks.
            header, *hunks = re.split(r"(?m)(?=^@@ )", patch)
            start = old_line(r"\paragraph{Virus Transmission.}") + 1
            end = old_line(r"\paragraph{Fatality Rate.}") + 1
            kept = []
            for hunk in hunks:
                match = re.match(r"@@ -(\d+)(?:,(\d+))? \+", hunk)
                position, count = int(match[1]), int(match[2] or 1)
                if not (position < end and position + count > start):
                    kept.append(hunk)
            display_patch = header + "".join(kept)
        rendered_patch = Path(work) / "display.diff"
        rendered_patch.write_text(display_patch)
        rendered = Path(work) / "diff.html"
        subprocess.run(["diff-review", "--patch", str(rendered_patch),
                        "--no-open", "--context", "3", "--output", str(rendered)],
                       check=True, capture_output=True, text=True)
        diff_pages[stem] = rendered.read_text()

# Show the model-introduction change alongside the base-case note as well.
header, *hunks = re.split(r"(?m)(?=^@@ )", review_patch(old, new))
start = next(i + 1 for i, line in enumerate(new)
             if r"\paragraph{Virus Transmission.}" in line)
end = next(i + 1 for i, line in enumerate(new)
           if r"\paragraph{Fatality Rate.}" in line)
default_hunks = []
for hunk in hunks:
    match = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@", hunk)
    position, count = int(match[1]), int(match[2] or 1)
    if position < end and position + count > start:
        default_hunks.append(hunk)
assert default_hunks
(out / "default_scenario.diff").write_text(header + "".join(default_hunks))
with tempfile.TemporaryDirectory(prefix="nov-review-default-") as work:
    rendered = Path(work) / "diff.html"
    subprocess.run(["diff-review", "--patch", str(out / "default_scenario.diff"),
                    "--no-open", "--output", str(rendered)], check=True,
                   capture_output=True, text=True)
    diff_pages["default_scenario"] = rendered.read_text()

# Verify that the complete Section 6 table is visible on both sides of task 1.
def covered_lines(patch, side):
    covered = set()
    line_number = None
    for line in patch.splitlines():
        if line.startswith("@@"):
            match = re.match(r"@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
            line_number = int(match.group(1 if side == "old" else 2))
        elif line_number is not None and line[:1] in (
                (" ", "-") if side == "old" else (" ", "+")):
            covered.add(line_number)
            line_number += 1
    return covered

for side, lines in [("old", old), ("new", intermediate)]:
    label = next(i for i, line in enumerate(lines) if "\\label{tab:results}" in line)
    start = max(i for i in range(label) if "\\begin{table}" in lines[i])
    end = next(i for i in range(label, len(lines)) if "\\end{table}" in lines[i])
    assert set(range(start + 1, end + 2)) <= covered_lines(
        (out / "initial_values.diff").read_text(), side)

# Read the original task headings and author passages; only Markdown markers
# are converted to HTML. Wording, spelling, and mathematical text are retained.
headings = list(re.finditer(r"(?m)^\\?# (.+)$", notes))
assert len(headings) == 2
sections = []
for i, heading in enumerate(headings):
    block = notes[heading.end():headings[i + 1].start()
                  if i + 1 < len(headings) else len(notes)]
    quote_part, solution = re.split(r"(?m)^Solution:?\s*$", block, maxsplit=1)
    quotes = [line[2:] for line in quote_part.splitlines() if line.startswith("> ")]
    result = ""
    if re.search(r"(?m)^Result:\s*$", solution):
        solution, result = re.split(r"(?m)^Result:\s*$", solution, maxsplit=1)
    sections.append(dict(title=heading.group(1), quotes=quotes,
                         solution=solution.strip(), result=result.strip()))
assert [len(s["quotes"]) for s in sections] == [1, 2]


def prose(source):
    """Render paragraphs and list markers without paraphrasing their content."""
    blocks = []
    for paragraph in re.split(r"\n\s*\n", source.strip()):
        if not paragraph.strip():
            continue
        lines = paragraph.splitlines()
        if all(line.startswith("* ") for line in lines):
            blocks.append("<ul>" + "".join(
                "<li>" + html.escape(line[2:]) + "</li>" for line in lines) + "</ul>")
        else:
            blocks.append("<p>" + html.escape(paragraph) + "</p>")
    return "\n".join(blocks)


def frame_source(stem, identifier):
    source = diff_pages[stem]
    system_theme = "setTheme(window.matchMedia('(prefers-color-scheme: dark)').matches);"
    assert system_theme in source
    source = source.replace(system_theme, "setTheme(false);")
    source = source.replace('<html lang="en">', '<html lang="en" data-theme="light">')
    # Keep diff-review's line highlighting, controls and commenting; remove
    # repeated navigation and promotional/instructional chrome from the embeds.
    source = source.replace("</head>", """<style>
      .topbar,.sidebar,.pagehead,.summary,.endnote,.exporthint,.exportfoot{display:none!important}
      .layout{display:block!important;min-height:0!important}.shell{min-height:0!important}
      main{padding:12px!important;max-width:none!important}.toolbar{margin-top:0!important}
      html,body{min-height:0!important}body{background:#fff}
    </style></head>""")
    observer = """<script>
      addEventListener('load',()=>{
        const wrap=document.getElementById('wrapToggle');
        if(wrap&&!wrap.checked)wrap.click();
        const report=()=>parent.postMessage({reviewFrame:IDENTIFIER,
          height:Math.ceil(document.querySelector('main').getBoundingClientRect().height)+32},'*');
        new ResizeObserver(report).observe(document.querySelector('main'));report();
      });
    </script>""".replace("IDENTIFIER", json.dumps(identifier))
    return source.replace("</body>", observer + "</body>")


def data_image(filename):
    return "data:image/png;base64," + base64.b64encode((out / filename).read_bytes()).decode()


default_note = """I modified R_0 so that the attack rate is close to the older versions of the paper. There is nothing special about 50% attack rate. I don't think there is right or wrong here, because attack rate will depend on non-pharm. interventions, people avoiding risk etc. So we should not try to "have a citation" to support this choice. Instead I say that the alternatives are examined in sensitivity table."""
timing_update = """Actually I do not want a 12-month peak after all; peak at 2, 3, 4, and 6 months is what we would compare in the table"""
table_data = list(csv.DictReader(open("sensitivity/analysis_summary.csv")))
group_labels = {
    "Attack rate": "Attack rate (base case = 50%)",
    "Vaccine reach": "Vaccine reach (base case = 80% of each age cohort)",
    "Eligible recipients": "Eligible recipients (base case includes recovered individuals)",
    "Peak timing": "Timing of epidemic peak (base case = 3 months)",
    "Demographics": "Demographics (base case = high-income countries)",
}


def sensitivity_table():
    rows = []
    last_group = None
    for row in table_data:
        if row["group"] != last_group and row["group"] != "Baseline":
            rows.append('<tr class="group"><th colspan="5">' +
                        html.escape(group_labels[row["group"]]) + '</th></tr>')
        last_group = row["group"]
        cells = []
        for key, scale, suffix in [
            ("uniform_dose", 100, "%"), ("full_averted", 100, "%"),
            ("uniform_averted", 100, "%"), ("reduction_vs_full", 100, "%")
        ]:
            cells.append('<td>' + format(float(row[key]) * scale, '.1f') +
                         suffix + '</td>')
        label = "Base case" if row["id"] == "baseline" else row["label"]
        if row["id"] in ("attack_30", "attack_70"):
            label += ' (R₀ = ' + format(float(row["r0_value"]), '.2f') + ')'
        rows.append('<tr data-case="' + html.escape(row["id"]) + '"><th scope="row">' +
                    html.escape(label) + '</th>' + ''.join(cells) + '</tr>')
    return ('<div class="table-scroll"><table class="sensitivity-table">'
            '<caption>Sensitivity of Optimal Uniform Dosing and Averted Deaths</caption>'
            '<thead><tr><th>Scenario</th><th>Optimal<br>uniform dose</th>'
            '<th>Deaths averted:<br>full dose</th><th>Deaths averted:<br>optimal dose</th>'
            '<th>Reduction versus<br>full dose</th></tr></thead><tbody>' +
            ''.join(rows) + '</tbody></table></div>')


parts = ['<section id="default-scenario"><h1>(Re-)Defining Base Case</h1>' +
         '<h2>My note</h2><blockquote>' + html.escape(default_note) +
         '</blockquote><h2>Diff</h2><iframe id="diff-default" ' +
         'title="Base case — manuscript diff" srcdoc="' +
         html.escape(frame_source("default_scenario", "diff-default"), quote=True) +
         '"></iframe></section>']
for i, section in enumerate(sections, 1):
    stem = "initial_values" if i == 1 else "sensitivity_task"
    parts.append('<section id="task-' + str(i) + '"><h1>' +
                 html.escape(section["title"]) + '</h1><h2>Chris says</h2>')
    for quote in section["quotes"]:
        parts.append('<blockquote>' + html.escape(quote) + '</blockquote>')
    parts.append('<h2>Solution</h2>' + prose(section["solution"]))
    if i == 2:
        parts.append('<h2>Updated timing</h2><blockquote>' +
                     html.escape(timing_update) + '</blockquote>')
        parts.append('<h2>Result</h2>' + sensitivity_table())
    parts.append('<h2>Diff</h2><iframe id="diff-' + str(i) +
                 '" title="' + html.escape(section["title"], quote=True) +
                 ' — manuscript diff" srcdoc="' +
                 html.escape(frame_source(stem, "diff-" + str(i)), quote=True) + '"></iframe>')
    if i == 1:
        parts.append('<figure><img src="' + data_image("main_results.png") +
                     '" alt="Deaths averted moving from full to fractional dosing"></figure>')
    parts.append('</section>')

page = '''<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>revision_nov2026 — complete review</title>
<style>
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f7f6f2;color:#252622;font:18px/1.65 Georgia,serif}
nav{position:sticky;top:0;z-index:30;background:#faf9f5f2;border-bottom:1px solid #d8d6cf;padding:12px 26px;display:flex;flex-wrap:wrap;gap:8px 28px;font:14px/1.5 system-ui,sans-serif;backdrop-filter:blur(8px)}
a{color:#315a6d}main{max-width:1220px;margin:35px auto;padding:0 24px 60px}section{scroll-margin-top:78px;margin-bottom:68px}h1{font-size:30px;line-height:1.3;font-weight:normal;border-bottom:1px solid #c9c8c0;padding-bottom:15px}h2{font-size:21px;margin:30px 0 14px}blockquote,p,ul{max-width:980px}blockquote{margin:0 0 20px;padding:5px 24px;border-left:3px solid #9dacae;white-space:pre-wrap}p{margin:0 0 20px;white-space:pre-wrap}ul{padding-left:25px}li{margin-bottom:12px}iframe{display:block;width:100%;height:650px;border:1px solid #d4d8dc;background:white;border-radius:4px}figure{margin:30px 0}img{display:block;max-width:100%;height:auto;width:760px;margin:auto}@media(max-width:650px){body{font-size:16px}main{padding:0 12px}h1{font-size:25px}nav{padding:9px 12px;gap:14px;font-size:12px}blockquote{padding-left:15px}}
.table-scroll{overflow:auto;margin:20px 0 30px}.sensitivity-table{border-collapse:collapse;width:100%;font:14px/1.45 system-ui,sans-serif;background:white}.sensitivity-table caption{text-align:left;font:600 18px/1.5 Georgia,serif;padding:0 0 14px}.sensitivity-table th,.sensitivity-table td{padding:9px 10px;border-bottom:1px solid #deded7;text-align:right;vertical-align:bottom}.sensitivity-table th:first-child{text-align:left;min-width:150px}.sensitivity-table tbody th{font-weight:400}.sensitivity-table thead{background:#eeede7}.sensitivity-table .group th{font-style:normal;font-weight:700;text-align:left;background:#f7f6f2;padding-top:16px}nav a{min-width:0}
</style></head><body><nav><a href="#default-scenario">(Re-)Defining Base Case</a>''' + ''.join(
    '<a href="#task-' + str(i) + '">' + html.escape(section["title"]) + '</a>'
    for i, section in enumerate(sections, 1)) + '</nav><main>' + '\n'.join(parts) + '''</main>
<script>
addEventListener('message',event=>{
 const message=event.data;if(!message||!message.reviewFrame)return;
 const frame=document.getElementById(message.reviewFrame);
 if(frame&&event.source===frame.contentWindow&&Number.isFinite(message.height)){
  const height=Math.max(300,Math.min(message.height,100000));
  if(Math.abs(frame.getBoundingClientRect().height-height)>2)frame.style.height=height+'px';
 }
});
</script></body></html>'''
(out / "complete_review.html").write_text(page)

# Store the source extracts and partition record for an exact reproducibility check.
audit = dict(head=subprocess.check_output(["git", "rev-parse", base_revision], text=True).strip(),
             manuscript_sha256=hashlib.sha256(new_text.encode()).hexdigest(),
             notes_sha256=hashlib.sha256(notes.encode()).hexdigest(),
             sections=sections, changes=changes,
             default_note=default_note, timing_update=timing_update,
             sensitivity_table=table_data,
             old_lines=len(old), intermediate_lines=len(intermediate), new_lines=len(new))
(out / "complete_review_audit.json").write_text(json.dumps(audit, ensure_ascii=False, indent=2))
print("Complete review:", out / "complete_review.html")
print("All", sum(len(c) for c in changes.values()), "change blocks partitioned; whole results table included.")
