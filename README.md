# Optimal dose stretching

Run R scripts from the RStudio project root. The manuscript is
[`overleaf/optimal_stretching24.tex`](overleaf/optimal_stretching24.tex).

The single base case uses R0 = 1.5, with 0.53% of each cohort initially exposed,
99.47% susceptible, and nobody initially infectious or immune. Without
vaccination, about 49.8% are infected by day 360 and the epidemic peaks near
three months. These are illustrative choices. Other attack rates and peak
trajectories are calibrated in the sensitivity analysis, rather than stored as
separate fast- and slow-growth defaults.

## Main results and paper outputs

`optimise.R` fits both dose-response shapes over the dynamic supply grid and
the retained static cases, saving `results/nlopt_results.rds`. The result has a
single `Base case` scenario and records its parameters as an attribute.
Dynamic age-varying policies use five starts (the uniform optimum, 25%, 75%,
1%, and 100%), with up to 5,000 evaluations per start. Uniform and static fits
use one start. Start diagnostics are retained in `result_start_diagnostics`.
The random seed is fixed for reproducibility. Multiple starts do not certify
a global optimum.

Verify the rounded initial seed with `source("setup/calibrate_base_case.R")`,
then run `source("optimise.R")`. Regenerate the outputs with:

```r
source("paper/table_calibration_results.R")
source("paper/figure_objective_v2.R")
source("paper/figure_optimal_dose.R")
source("paper/figure_example.R")
source("paper/figure_dose_response.R")
source("figures.R") # supplementary base-case death tables

source("sensitivity/uptake.R")
source("sensitivity/analysis.R")
```

The calibration-table script writes `paper/tables/calibration_results.csv`
and reference rows in `overleaf/tables/calibration_rows.tex`. The sensitivity
script writes `overleaf/tables/sensitivity_rows.tex`. Copy these rows into the
corresponding inline tables in `optimal_stretching24.tex` so numerical changes
remain visible in manuscript diffs. Both tables have been updated for the
current base case.

The objective, age-dose and epidemic-illustration scripts write PDFs under
`paper/figures/` and copy the main inputs to `overleaf/figures/`. They generate
only base-case figures. `paper/figure_example.R` also generates the retained
multi-season illustration. The age-dose script saves
`paper/figures/age_solutions_coverage.csv`; cohorts are plotted only when
`frac_vac > .05`. This quantity sums vaccinated compartments at the overall
infection peak, rather than counting cumulative administrations.

The dose-response figure is also regenerated, but the manuscript uses the
separately edited `dose_response_edited.pdf`. The theoretical figures and model
diagram are separate assets. Finally, compile `overleaf/optimal_stretching24.tex`.

## Sensitivity analyses

See [`sensitivity/README.md`](sensitivity/README.md). The systematic analysis
calibrates R0 and E(0) jointly to compare attack rates of 30% and 70% at a
three-month peak, and 50% attack rates with peaks at two, four and six months.
The base case supplies the three-month timing comparison. All attack targets
and vaccination outcomes refer to day 360.

`R/scenario_calibration.R` contains the shared calibration helpers.
`setup/base_case_calibration.csv` records the rounded base case and its achieved
attack rate and peak. Changing the default requires updating the constants in
`setup/parametrisation.R`, recalibrating the sensitivities, and rerunning the
commands above. Sensitivity caches are checked against the case settings and
model source; use `refit <- TRUE` after other relevant code changes.

## Review

`review_nov2026/complete_review.html` contains the author's notes, the manuscript
diffs, and a directly rendered sensitivity table. Run
`python3 review_nov2026/build_complete_review.py` to rebuild it after updating
both the manuscript and the generated figures. The comparison baseline is
pinned to commit `907b3f8`, so committing later edits does not reset the review.
