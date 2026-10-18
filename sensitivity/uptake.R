# Check uptake sensitivity for the fast-growing epidemic, sigmoid dose response,
# and daily supply of 0.1% of the population in full-dose equivalents.
# Save fits separately from the main results; set refit to TRUE to rerun them.

library(tidyverse)
library(nloptr)
source("setup/model_2vaccine.R")
source("R/single_run.R")
source("setup/parametrisation.R")

uptake_values <- c(0.3, 0.5, 0.6, 0.8, 0.9)
refit <- FALSE

# Helpers -----
# Set uptake directly: model_fd_dynamic() does not pass first-season uptake
# through to apap_2v(). Keep the paper's other single-season parameters fixed.
deaths_at_dose <- function(dose, uptake) {
  dose <- c(1, 1, rep(dose, length.out = 7))
  pars <- apap_2v(pars_le_fast, len = 1000,
                  fractional_dose = dose, vhes = uptake)
  pars$e1 <- phi_sigmoid(dose)
  y <- sr(pars)
  sum(y[Ndays, "D", ] * pop)
}

# Fit and save -----
no_vaccine <- sr(pars_le_fast)
no_vaccine_deaths <- sum(no_vaccine[Ndays, "D", ] * pop)
fits <- if (!refit && file.exists("sensitivity/uptake_results.rds")) {
  readRDS("sensitivity/uptake_results.rds")
} else {
  list()
}

for (uptake in uptake_values) {
  key <- as.character(uptake)
  if (key %in% names(fits)) next
  message("Fitting uptake = ", uptake)
  pars <- apap_2v(pars_le_fast, len = 1000, vhes = uptake)
  stopifnot(all(pars$vstop[3:9] == uptake))

  objective <- function(dose) deaths_at_dose(dose, uptake)
  full_deaths <- objective(1)
  uniform <- optimize(objective, c(0.01, 1), tol = 1e-7)
  dose_grid <- tibble(dose = seq(0.01, 1, length.out = 101)) %>%
    mutate(deaths = map_dbl(dose, objective))
  # Check the bounded search against a grid and both dose boundaries.
  stopifnot(uniform$objective <= min(dose_grid$deaths) + 1e-9)

  age_fits <- map(c(uniform$minimum, 0.3, 0.7), function(start) {
    nloptr(x0 = rep(start, 7), eval_f = objective,
           lb = rep(0.01, 7), ub = rep(1, 7),
           opts = list(algorithm = "NLOPT_LN_COBYLA", xtol_rel = 1e-6,
                       maxeval = 1000, print_level = 0))
  })
  stopifnot(all(map_int(age_fits, "status") > 0))
  best_age <- age_fits[[which.min(map_dbl(age_fits, "objective"))]]
  stopifnot(best_age$objective <= uniform$objective + 1e-8)

  fits[[key]] <- list(
    uptake = uptake, no_vaccine_deaths = no_vaccine_deaths,
    full_deaths = full_deaths, uniform = uniform, dose_grid = dose_grid,
    age_fits = age_fits, best_age = best_age,
    full_dose_start_days = pars$ta1, uptake_targets = pars$vstop)
  saveRDS(fits, "sensitivity/uptake_results.rds")
}

# Summarise -----
uptake_summary <- map_dfr(fits, function(fit) {
  tibble(
    uptake = fit$uptake, uniform_dose = fit$uniform$minimum,
    no_vaccine_deaths = fit$no_vaccine_deaths,
    full_deaths = fit$full_deaths,
    uniform_deaths = fit$uniform$objective,
    age_deaths = fit$best_age$objective) %>%
    mutate(
      full_averted = 1 - full_deaths / no_vaccine_deaths,
      uniform_averted = 1 - uniform_deaths / no_vaccine_deaths,
      age_averted = 1 - age_deaths / no_vaccine_deaths,
      uniform_gain_pp = 100 * (uniform_averted - full_averted),
      age_gain_pp = 100 * (age_averted - uniform_averted),
      uniform_reduction_vs_full = 1 - uniform_deaths / full_deaths)
})
write_csv(uptake_summary, "sensitivity/uptake_summary.csv")
map_dfr(fits, function(fit) {
  tibble(uptake = fit$uptake, age_group = colnames(pbc_spread)[3:9],
         dose = fit$best_age$solution)
}) %>% write_csv("sensitivity/uptake_age_doses.csv")
print(uptake_summary %>%
        select(uptake, uniform_dose, ends_with("averted"), age_gain_pp))
