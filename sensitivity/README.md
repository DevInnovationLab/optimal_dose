# Sensitivity and numerical checks

## Uptake sensitivity

`uptake.R` checks the fast-growing epidemic, sigmoid dose response, and daily
vaccine supply of 0.1% of the population in full-dose equivalents. It varies the
common uptake target among adult cohorts over 30%, 50%, 60%, 80%, and 90%; children
remain unvaccinated. Other parameters follow the current single-season model.

From the project root, run:

```r
source("sensitivity/uptake.R")
```

Existing fits are loaded from `uptake_results.rds`. Set `refit <- TRUE` in the
script to refit every uptake scenario, including after changing model code or
parameters. Fits are saved after each scenario, so an interrupted run can resume.
The script always regenerates:

- `uptake_summary.csv`: doses, deaths, reductions relative to no vaccination and
  full doses, and the extra benefit of age-varying dosing. Dose and mortality
  reduction columns are proportions; columns ending in `_pp` are percentage points.
- `uptake_age_doses.csv`: the selected dose in each adult cohort.

The RDS also retains the uniform-dose search, its 101-point grid check, and three
COBYLA fits for age-varying doses at each uptake. Uptake is passed directly to
`apap_2v(vhes = ...)`, changing both the cap and vaccination schedule; the current
`model_fd_dynamic()` wrapper does not pass first-season uptake through.

The 60% scenario supplies both the numerical results footnote in Section 6 and
the alternative mentioned in the uptake-assumption footnote.
These checks do not examine differences in uptake between age cohorts.

## Archived numerical optimisation check

The exploratory script has been removed; multiple starts are now integrated in
`optimise.R`. `opt_general()` defaults to `n_starts = 1` for interactive calls.
The main script sets `age_n_starts <- 5L` for dynamic age-varying cases only and
retains per-start diagnostics in the saved main results. Uniform and static
cases use one start.

The following archived files record the preliminary comparison of five starts
in 12 scenarios (both epidemic speeds and response shapes, at daily supplies of
0.01%, 0.1%, and 1%):

- `optimisation_results.rds`: fits, uniform-dose grid checks, elapsed times and
  the main estimates used for comparison.
- `optimisation_starts.csv`: per-start objectives, termination statuses,
  iteration counts and elapsed times. Status 4 meets the relative tolerance;
  status 5 reaches the evaluation limit.
- `optimisation_summary.csv`: comparisons against the old main fits and between
  three and five starts. Columns ending in `_pp` are percentage points of
  no-vaccine deaths; `gain_vs_saved_pct` is the percentage reduction in deaths
  relative to the saved age-varying fit.
- `optimisation_session.txt`: R and package versions for the check.

The lower-bound start improved slow-epidemic sigmoid results by 2.15 percentage
points of no-vaccine deaths at 0.01% daily supply and 0.73 points at 0.1% supply.
The largest reduction in deaths relative to a saved age-varying fit was 2.40%.
The fast-epidemic sigmoid benchmark changed by less than 0.001 percentage points.
These checks assess starting-value sensitivity and do not establish global
optimality. Regenerate the main fits with `source("optimise.R")`; the archived
check files are not updated by that run.
