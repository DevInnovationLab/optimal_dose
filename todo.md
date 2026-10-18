Note to self:
#2; #5; #9: ODEs do not account for expansion in supply when doses drop. There is also need to normalise to 1. I will look into this, I think easy to solve: I am confident the models are OK, but can improve equations and write-up.
#10: ditto, just need to list a few more parameters in a footnote
#13: we just need to note once again that our model is a big simplification
#6: "cannot track vaccinated recoveries": I think just clumsy description or extra shortcoming of the model I need to describe better
#8; #14: some notes about conflicts between reported values; I will investigate, but I would not worry about this, figures and tables are generated from the same source result, so there has to be a sensible explanation
#29; #31; #40: clumsy wording in description of efficacy -> doses averted & "definition" of R_0, easy to solve; specify number of age cohorts (I think it's because 0-19 yo can be counted)
#34: update the caption to say what scenario is being demonstrated & check correct values are used
Lack of diagnostics for non-linear optimisation. Good point. I had 2 RA's work on this, both of them very good, but I didn't actually check myself. Also easy to do and worth doing, can report this a bit more in supplement or footnote. 
#45, #46: need to go into the papers and check their claims again. I can do that if needed or we can discuss later.

Chris also asked for me to look into #7 and #21






********



Below is a handover spec for Codex. I have treated the numbered Refine comments by their substance rather than blindly by number, because `todo.md` calls the “vaccinated recoveries” problem `#6`, while the Refine report labels that detailed comment `#7`. I would not touch Refine’s actual comment #6 on comparative-static regularity unless instructed separately. Your selected scope is #2/#5/#9, #10, the vaccinated-recoveries issue, #8/#14, #13, #29/#31/#40, #34, optimisation diagnostics, #45/#46, plus Chris’s request to examine #7/#21. 

# Codex spec: Refine.ink fixes for vaccine dose-stretching paper

## Objective

Work through **only the Refine.ink issues listed below**. Other Refine comments are being handled elsewhere.

The main paper is `optimal_stretching21.tex`. The repository contains the R/model code and generated figures/tables. Use the code as the authoritative source for what the simulations actually do. Do not modify theoretical sections or address unrelated Refine comments.

For each issue:

1. Inspect the relevant source code, generated outputs, and manuscript text.
2. Make fixes where the correct change is unambiguous.
3. Where investigation reveals a substantive modelling choice or uncertainty, stop short of silently changing the model. Document what you found and propose the smallest manuscript/code change.
4. Regenerate affected figures/tables where necessary.
5. At the end, produce a short issue-by-issue log containing:

   * what you checked;
   * what you found;
   * files changed;
   * whether numerical results changed;
   * anything requiring Witek/Chris to decide.

Do not undertake broad refactoring.

---

## 1. Textual fixes that can be implemented directly

### Refine #13 — 80% uptake is a modelling simplification

The manuscript assumes that 80% of every age cohort is willing to be vaccinated, while the supporting footnote gives national aggregate vaccination rates and itself acknowledges substantial variation by risk group. Refine correctly notes that those data do not establish a uniform age-specific 80% uptake rate. 

**Change:** retain 80% as the benchmark but explicitly label it a simplifying calibration assumption rather than an empirically estimated age-invariant rate.

Suggested wording around the existing sentence:

> We assume, as a simplifying benchmark, that 80% of each cohort are willing to be vaccinated and 20% are not, perhaps because of logistical frictions or vaccine hesitancy. Actual uptake differed substantially across age groups and countries, so the uniform 80% assumption should not be interpreted as an empirical estimate of cohort-specific uptake.

Then simplify the footnote so that the country figures merely establish that 80% is a plausible order of magnitude, rather than supporting uniformity across cohorts.

Also add one sentence, either here or when discussing the small gains from age-varying dosing:

> The quantitative comparison between uniform and age-varying dosing is therefore conditional on this common uptake assumption.

Do **not** add a new sensitivity analysis unless Witek later asks for one.

---

### Refine #29 — 95% efficacy is not a ceiling on deaths averted

Current text says that full dosing averting 95% of deaths is “the maximum possible given the vaccine is calibrated to be 95% effective”. That inference is wrong because preventing infection also reduces onward transmission; individual efficacy is not a ceiling on population deaths averted. 

Replace that sentence with something like:

> Full doses already avert 95% of deaths in this calibration, leaving essentially no scope for fractional dosing to improve outcomes further.

Do not describe 95% as a theoretical maximum.

---

### Refine #31 — distinguish \(R_0\) from effective/control reproduction numbers

The existing footnote attributes time variation in \(R_0\) to distancing and lockdowns. Refine is right that distancing changes realised/effective transmission rather than the basic reproduction number under a fixed environment. The paper's \(R_0=2\) and \(R_0=1.1\) exercises are better described as alternative fixed epidemic calibrations. 

Replace the current footnote with approximately:

> The basic reproductive number is context-specific and can differ across variants and baseline contact environments. Changes in realised contacts due to social distancing or lockdowns instead affect effective or control reproduction numbers. We use fixed values of \(\mathscr R_0=2\) and \(1.1\) simply to represent relatively fast- and slow-growing epidemic environments.

Keep terminology consistent elsewhere if the same claim recurs.

---

### Refine #40 — eight cohorts, seven vaccine-eligible cohorts

The introduction currently says the model uses seven age cohorts, whereas Section 6.2 correctly defines eight: children under 19 plus seven adult groups. The optimisation is seven-dimensional because children are not vaccine eligible. 

Change the introduction from:

> ...across seven age cohorts...

to something like:

> ...across eight age cohorts, seven of which are vaccine-eligible adult cohorts...

Check for any other prose that conflates “seven optimisation variables” with “seven epidemiological cohorts”.

---

## 2. Coding-agent investigations before making the textual change

### Refine #2 / #5 / #9 — vaccination throughput, dose strength and state normalisation

Treat these three comments as one investigation. This is the highest-priority item.

The displayed ODEs currently contain vaccination flow \(qv_a(t)\), independent of dose \(x_a\). As written, smaller doses lower efficacy without vaccinating anybody faster, contradicting the mechanism described in the results. Refine also points out that the units are ambiguous: whether an age-specific compartment is represented as a cohort prevalence, population share or mass determines both the vaccination term and whether \(\lambda_a\) needs a cohort-size denominator.  

#### Investigation

Trace the implementation from:

* dose vector \(x_a\);
* supply parameter `q`;
* age population shares;
* `v_a(t)`/priority switching;
* vaccination flows into protected/unprotected states;
* force of infection;
* the ODE state initialisation.

Determine explicitly:

1. Are \(S_a,E_a,\ldots\) represented as:

   * fractions of the **whole population**,
   * fractions **within age cohort**, or
   * counts/masses?
2. What exactly is `q` in code?
3. For a cohort receiving dose \(x_a\), is recipient throughput actually \(q/x_a\), or is the same accounting implemented in some other way?
4. How does this work when \(x_a\) varies by age?
5. Is the contact matrix already normalised such that

   $$
   \lambda_a=\beta\sum_{a'}c_{aa'}I_{a'}
   $$

   is correct for the state definition, or should infectious prevalence be divided by the population share of cohort \(a'\)?

#### Expected manuscript fix

After establishing the implementation, rewrite equations (26)–(32) so that they reproduce the code exactly.

If the state variables are whole-population shares and supply is \(q\) full-dose equivalents per unit time, I expect the vaccination-flow component for the active cohort to involve something of the form

$$
\frac{q}{x_a}v_a(t),
$$

but **do not insert this merely because Refine suggested it**. Establish what the code actually does first.

Immediately before/after the equations, explicitly define:

* units/normalisation of every compartment;
* units of \(q\);
* how fractional dose \(x_a\) converts antigen capacity into recipient flow;
* how the active age cohort is selected;
* how cohort population size enters this calculation.

Run a minimal numerical check: holding everything else fixed, halving a uniform dose should approximately double the number of vaccine recipients per unit antigen until a cohort boundary/uptake constraint intervenes.

If the code itself does **not** implement accelerated coverage, stop and report this as a substantive problem rather than rewriting the paper around it.

---

### Refine vaccinated-recoveries comment — labelled #7 in Refine, called #6 in `todo.md`

The criticism is that vaccinated recovered individuals remain in \(R_a\), so the ODE expression may repeatedly allocate vaccination capacity to the same recovered mass. Refine argues this conflicts with the prose saying willing cohort members are vaccinated once. 

#### Investigation

Establish from the implementation:

* how campaign completion for an age cohort is tracked;
* whether total vaccinations administered are tracked separately from compartment mass;
* whether somebody sampled from \(R_a\) can effectively be “vaccinated” repeatedly;
* whether `v_a(t)` is switched off according to elapsed supplied doses, remaining unvaccinated people, or some other variable.

Then quantify whether the apparent repeated-vaccination issue is:

1. only a misleading feature of the ODE notation while the campaign code separately tracks vaccination once per person;
2. a genuine simplification deliberately allowing repeated wasted draws from \(R_a\); or
3. an implementation error.

#### Action

If (1), fix the model exposition so the tracking mechanism is explicit.

If (2), **do not redesign the model**. Rewrite the text to state the approximation accurately and explain briefly that the model does not maintain vaccination status among naturally immune individuals. Note it as another simplification.

If (3), report it before changing results, because correcting it could alter the simulations.

This investigation also satisfies Chris's request to look into Refine #7.

---

### Refine #8 and #14 — apparent disagreements in Appendix slow-epidemic results

There are two related complaints:

* Figure A3, concave response at 0.01% supply, appears to show only the 80+ cohort receiving a tiny dose, which seems inconsistent with available antigen. 
* Table A1 and Figure A2 appear to disagree for concave 0.01% supply: the table suggests uniform and age-varying policies have essentially the same gain, while the plotted age-varying gain looks materially higher. 

The expectation is that figures and tables ultimately derive from the same simulation outputs, so first look for differences in transformations, rounding, stale files, or plotting inputs.

#### Investigation

For the exact slow-epidemic / concave / 0.01% case:

1. Locate the raw optimisation result used for:

   * Table A1;
   * Figure A2;
   * Figure A3.
2. Print the exact, unrounded values:

   * full-dose deaths;
   * uniform-optimal deaths;
   * age-varying-optimal deaths;
   * the gain statistic plotted in A2;
   * all seven adult optimal doses;
   * cohorts actually reached;
   * total antigen used / unused.
3. Recompute the plotted metric directly from those death totals.
4. Verify Figure A2 and Table A1 use the same result file/run.
5. Check for stale generated PDF/image files.
6. Check Figure A3's convention for omitting cohorts. Is a cohort omitted because it gets literally zero supply, because the vaccination stage is never entered before day 365, or because of a plotting/NA convention?
7. Check the capacity arithmetic after fixing/confirming the \(q/x_a\) issue above.

#### Action

If this is just a stale figure or transformation error, fix and regenerate all affected appendix outputs.

If the values genuinely differ because different optimisations/runs are being used, unify them and document which is authoritative.

If there is a deeper capacity-accounting problem, stop and report rather than masking it with a plotting change.

---

### Refine #10 — missing calibration parameters

Refine notes that the paper does not state cohort population shares, initial compartments, \(\epsilon_a\), \(\xi_a\), or \(\psi_a\). 

The desired fix is **small**: probably a footnote or compact sentence, not a new calibration section.

#### Investigation

Read the code and identify the exact values actually used for:

* cohort population proportions;
* \(S_a(0),E_a(0),I_a(0),R_a(0),P_a(0),N_a(0),D_a(0)\), including whether initial infections are age-specific;
* incubation/exposed exit rate \(\epsilon_a\);
* infectious exit rate \(\xi_a\);
* vaccine-immunity waning \(\psi_a\).

Determine which are common across age groups and which vary.

Also identify their source or derivation if this is already documented in code/comments or inherited directly from Wiecek et al.

#### Action

Add the minimum self-contained manuscript description. Prefer prose plus a footnote, e.g. “We set the mean latent period to X days (\(\epsilon=1/X\)), infectious period to Y days (\(\xi=1/Y\)), …”; give initialisation and population weights similarly.

Do not add parameters that are unused.

---

### Refine #34 — identify the policy shown in Figure 9

Figure 9's caption says only that it shows the calibrated SEIRDV model at different supply levels. Refine observes that the coverage paths appear to involve fractional dosing, but neither the dose-response curve nor dosing policy is identified. 

#### Investigation

Find the script/data that generates `example_model_edited.pdf` and establish for each trajectory:

* full versus fractional dosing;
* if fractional, whether uniform or age-varying;
* dose-response shape;
* whether the optimal dose changes with each supply level;
* \(R_0\), uptake and horizon, if not already obvious.

#### Action

Then update the caption so the figure is reproducible from the description.

For example, **only if verified**:

> Simulates the SEIRDV model under optimal uniform fractional dosing with the [sigmoid/concave] dose-response function for the indicated full-dose-equivalent vaccine capacities...

If the figure is instead full-dose only, say so and verify that its coverage path is consistent with the capacity definition.

---

### Numerical optimisation diagnostics

Refine raises a sensible concern that the seven-dimensional age-specific problem is nonconvex and `nloptr` may find local rather than global optima. 

Add a focused reproducibility/diagnostic exercise. Do **not** replace the main optimiser unless necessary.

#### Required checks

For every published age-varying optimum, or at minimum every combination of:

* benchmark and appendix \(R_0\);
* sigmoid and concave response;
* the four tabulated supply values;

run a robust multistart check.

Suggested minimum:

* existing starting point;
* at least 50–100 random starts in \([0,1]^7\);
* deterministic starts including all-full-dose, all-uniform-optimum, low-dose boundary, and several mixed boundary solutions;
* retain the best objective across starts.

Also run one independent global-ish validation where computationally feasible, for example a coarse grid followed by local refinement, differential evolution, ISRES, or another global optimiser already available in the project environment.

For each published solution record:

* best deaths/objective;
* second-best distinct objective;
* spread of final objective values;
* number/proportion of starts reaching the best solution within a tight tolerance;
* whether any optimal coordinate sits on 0 or 1;
* convergence/status codes;
* maximum discrepancy between the currently reported optimum and the best diagnostic result.

#### Action

If the published optima survive, add a short sentence/footnote to Calibration Methods, e.g.:

> Because the age-specific problem is nonconvex, we validated each reported optimum using [N] dispersed starting values [and global-search method]. All reported solutions were reproduced to within [tolerance].

Put fuller diagnostics in the appendix only if useful.

If materially better optima are found, regenerate all affected results and flag this prominently.

---

### Refine #21 — immunological non-inferiority versus clinical efficacy

The current conclusion infers from immunological non-inferiority of fractional yellow-fever/mpox doses that the full doses lie far out on a long **clinical efficacy** plateau, and then says the full dose was five times more concentrated than needed “for the same efficacy”. Refine correctly notes that an immunological endpoint does not automatically establish equality of the paper's \(\phi\), which represents clinical protection. 

#### Investigation

Inspect the actual Juan-Giner and CDC/mpox sources already cited. Establish:

* what endpoint was tested;
* whether non-inferiority was immunological only;
* whether there are direct clinical-effectiveness data comparing fractional and standard dosing;
* whether “one fifth” applies cleanly to both examples.

Do not undertake a literature review beyond the citations already used unless needed to understand them.

#### Likely textual direction

Unless the sources directly establish clinical non-inferiority, soften the paragraph substantially. Something along the lines of:

> In both cases, trials found immunological responses to fractional doses to be non-inferior to standard doses. If such immune-response preservation translates into similar clinical protection, these examples would suggest relatively flat dose-response relationships over part of the relevant range.

And replace:

> five times more concentrated than needed for the same efficacy

with something tied to the measured immune response, for example:

> five times the antigen dose could produce little detectable improvement in the measured immunological endpoint.

But make the exact edit only after checking the papers.

---

## 3. Items requiring Witek's review before substantive editing

### Refine #45 — Matrajt et al. (2021)

Refine says the paper wrongly characterises Matrajt et al. as using a single age threshold; according to the report, Matrajt optimises allocation of one versus two doses over five age groups. 

**Do not silently rewrite this literature claim.**

Prepare for Witek:

* the exact current manuscript sentence;
* the relevant description from Matrajt et al.;
* whether the paper genuinely allows a multi-age allocation of different dosing regimens;
* a proposed corrected sentence covering Wu, Matrajt and Leung without falsely forcing them into one common design.

No manuscript edit until reviewed.

---

### Refine #46 — Benest et al. (2020)

Current paper cites Benest et al. as evidence that sigmoid dose-response curves fit empirical vaccine data. Refine says Benest instead finds evidence favouring a peaked rather than saturating response. 

**Do not silently alter the citation claim.**

Prepare:

* the exact Benest result;
* whether “peaking” in that paper is inconsistent with the particular statement being made here;
* what de Jonge and Roozendaal actually support;
* one or two proposed replacements:

  * remove Benest from the sigmoid-support sentence and use it only in the later peaked-efficacy discussion; or
  * rewrite the paragraph to say empirical vaccine dose-response curves display both saturating/sigmoid and peaked shapes.

Leave final choice to Witek.

---

## Explicit exclusions

Do **not** address other Refine issues merely because they appear nearby in the report. In particular, do not start repairing Propositions 2/6, Lemmas 7/8, the theoretical KKT arguments, chain-rule mistakes, fixed-cost comparative statics, or other proof comments. Those are outside this handover.

Likewise, do not independently change the definition of the deaths-averted metric unless required by one of the scoped tasks above.

## Final deliverable

Commit the straightforward fixes and verified code/manuscript corrections. Then provide a Markdown report with one heading per scoped issue and a status of:

* **fixed**;
* **checked — no change needed**;
* **substantive problem found**;
* **requires Witek review**.

For all numerical investigations, include enough exact values and paths to source scripts/results that someone else can reproduce the conclusion without rerunning an archaeological expedition through the repository.
