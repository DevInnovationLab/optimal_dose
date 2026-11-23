# Replication package for Optimal Dose Stretching Under Vaccine Supply Constraints

Kremer, Michael, Christopher M. Snyder, and Witold Więcek. “Optimal Dose Stretching Under Vaccine Supply Constraints.” Working paper, November 2026.

## Set up R

Open `optimal_dose.Rproj` in RStudio or set your R working directory to the repository root. Install the packages below. You will also need a C toolchain for R to compile the epidemic model.

```r
install.packages(c(
  "abind", "assertthat", "furrr", "geomtextpath", "ggpubr", "kableExtra",
  "knitr", "latex2exp", "nloptr", "odin", "patchwork", "scales", "shades",
  "tidyverse"
))
```

The model inputs are included in `setup/`. The base case uses a reproduction number of 1.5 and an initial exposed share of 0.53%. Without vaccination, 49.8% of the population is infected by day 360, with the epidemic peaking at about three months.

## Reproduce the results

The repository includes the main optimisation results in `results/nlopt_results.rds`. For a full rerun, run the first two lines below to check the base-case calibration and recompute the optimal uniform and age-specific doses. To regenerate the figures and tables from the saved results, start at `paper/table_calibration_results.R`. The sensitivity scripts can reuse saved fits. Set `refit <- TRUE` in both before running them if you want to recompute all sensitivity fits.

```r
source("setup/calibrate_base_case.R")
source("optimise.R")

source("paper/table_calibration_results.R")
source("paper/figure_objective_v2.R")
source("paper/figure_optimal_dose.R")
source("paper/figure_example.R")
source("paper/figure_dose_response.R")
source("figures.R")

source("sensitivity/uptake.R")
source("sensitivity/analysis.R")
```

The main optimisation uses five starting values for age-specific doses in the dynamic model and saves diagnostics for each start. Details of the scenarios and output files are in the [sensitivity README](sensitivity/README.md).

The paper's figures and tables are in [`paper/figures/`](paper/figures/) and [`paper/tables/`](paper/tables/). Sensitivity results are in [`sensitivity/`](sensitivity/).

## Licence

Copyright © 2026 Michael Kremer, Christopher M. Snyder, Witold Więcek, and contributors.

- The original replication code is available under the [BSD 3-Clause licence](LICENSE).
- The original replication documentation and analysis outputs are available under [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/). Please use the citation above when crediting the work.

Third-party materials, including externally sourced model inputs, remain subject to their original terms.
