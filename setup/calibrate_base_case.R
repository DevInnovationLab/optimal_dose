# Calibrate and round the exposed seed at the base reproduction number.
# Verify the constants in parametrisation.R before rerunning the policy grid.

library(tidyverse)
source("setup/model_2vaccine.R")
source("R/single_run.R")
source("setup/parametrisation.R")
source("R/scenario_calibration.R")

seed <- signif(calibrate_exposure(base_r0, 3), 2)
calibration <- bind_cols(
  tibble(r0 = base_r0, exposed_seed = seed),
  epidemic_outcomes(epidemic_parameters(base_r0, seed)))
write_csv(calibration, "setup/base_case_calibration.csv")
print(calibration, width = Inf)
stopifnot(initial_exposed == seed,
  abs(calibration$peak_day - 91.5) < 1,
  abs(calibration$attack_360 - .5) < .005)
