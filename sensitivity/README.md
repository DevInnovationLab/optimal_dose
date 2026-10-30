# Sensitivity and numerical checks

## Systematic sensitivity analysis

Run `source("sensitivity/analysis.R")` at daily supply of 0.1% and sigmoid dose
response. The single baseline has R0 = 1.5, 80% vaccine reach, recovered people
eligible for vaccination, and E(0) = 0.0053 in every cohort.

The script calibrates R0 and E(0) jointly to compare attack rates of 30% and 70%
with a peak at three months, and attack rates of 50% with peaks at two, four
and six months. The base case, with a 49.8% attack rate and a three-month peak,
is the remaining timing comparison. All attack targets refer to cumulative
infections by day 360. There is no 12-month case.

The remaining comparisons reduce reach to 60% or 30%, or exclude recovered
people from vaccination, or replace the high-income age distribution with the
low-income distribution already stored in `setup/default_input.Rdata`. The
demographic comparison holds the contact matrix, age-specific fatality rates,
R0 and initial exposure fixed; cohort sizes change both the vaccination
schedule and population-weighted outcomes. High-income demographics are the
base case. Every vaccination outcome uses the same 360-day
horizon and each scenario's own no-vaccination mortality as its denominator.
Diagnostic no-vaccination runs extend to 730 days to locate the peak and check
the tail, without changing the horizon used for policy benefits.

`R/scenario_calibration.R` contains the calibration helpers.
`setup/calibrate_base_case.R` reproduces the rounded base seed. The script saves:

- `analysis_calibration.csv`: targets, fitted R0 and seeds, and achieved outcomes.
- `analysis_timing.csv`: the two-, three-, four- and six-month cases.
- `analysis_results.rds`: parameters, solver settings, grids and local searches.
- `analysis_summary.csv`: doses and benefits for all ten scenarios.

Proportions are used for doses and death reductions; `_pp` denotes percentage
points. A 101-point dose grid identifies every local minimum, each of which is
refined separately; both dose boundaries are included. Cached fits are reused
only when case settings, parameters, population weights, solver settings and
model source match.
Set `refit <- TRUE` after other relevant code changes.

`overleaf/tables/sensitivity_rows.tex` contains generated reference rows,
copied inline into the manuscript for readable diffs. The review HTML renders
the results as a normal HTML table as well.

In the recovered-exclusion case, vaccination stops at susceptible depletion;
unused supply is not reassigned before the next cohort's scheduled start.
The shared ODE prevents vaccination of an exhausted eligible population and
counts only actual administrations. The baseline recipient pool never reaches
that guard, preserving its dynamics.

## Historical baseline comparison

`source("sensitivity/initial_conditions.R")` compares the original paper's
calibration (R0 = 2 and nonzero prior immunity) with the current base case at
supplies of 0.1% and 1%, using sigmoid dose response. Both transmission and
initial conditions differ in this historical comparison; it is not a
one-parameter sensitivity. Results are saved as `initial_conditions_*` files.

## Uptake sensitivity

`uptake.R` checks the base-case epidemic, sigmoid dose response, and daily
vaccine supply of 0.1% of the population in full-dose equivalents. It varies the
common uptake target among adult cohorts over 30%, 50%, 60%, 80%, and 90%; children
remain unvaccinated. Other parameters follow the current single-season model.

From the project root, run:

```r
source("sensitivity/uptake.R")
```

Existing fits are loaded from `uptake_results.rds`. Set `refit <- TRUE` in the
script to refit every uptake scenario, including after changing model code. Fits with different model parameters
are discarded automatically. Fits are saved after each scenario, so an interrupted run can resume.
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
