# Compare the original calibration with the current baseline and
# an exposed-only seed rounded to give a no-vaccine peak near three months.
# Use the current baseline; compare sigmoid policies at 0.1% and 1% daily supply.

library(tidyverse)
library(nloptr)
source("setup/model_2vaccine.R")
source("R/single_run.R")
source("setup/parametrisation.R")

peak_target <- 3 * 30.5

# Prepare the original and rounded starting values -----
original_immunity <- c(0.5, 0.5, rep(0.2, 7))
original_y0 <- y0_gen(13, Ngroups, original_immunity, ii = 0)
original_y0[2, ] <- original_y0[3, ] <- 0.001 * (1 - original_immunity) / 2
original_y0[1, ] <- 1 - colSums(original_y0[2:13, ])
pars_original <- list_modify(pars_base, y0 = original_y0,
  q = rep(2 / (5 * eigen(default_cm * (1 - original_immunity))$values[1]),
          Ngroups))
pars_simplified <- pars_base
seed <- pars_simplified$y0[2, 1]

# Interpolate a fine output grid to avoid calibrating to rounded peak days.
peak_time <- function(pars) {
  pars$Ndays <- NULL
  pars$e1 <- rep(pars$e1, length.out = Ngroups)
  pars$e2 <- rep(pars$e2, length.out = Ngroups)
  model <- odin_ode_2vaccines_v2$new(user = pars)
  # Match sr(), whose output clock starts at day 1.
  times <- seq(1, Ndays, by = 0.25)
  y <- model$run(times)
  infectious <- drop(y[, 1 + 2 * Ngroups + seq_len(Ngroups)] %*% pop)
  peak <- which.max(infectious)
  interval <- times[c(max(1, peak - 1), min(length(times), peak + 1))]
  optimize(splinefun(times, infectious), interval, maximum = TRUE,
           tol = 1e-7)$maximum
}

stopifnot(seed == initial_exposed,
  abs(peak_time(pars_simplified) - peak_target) < 2,
  all(pars_simplified$y0[3:4, ] == 0),
  all(abs(colSums(pars_simplified$y0) - 1) < 1e-12))

# Optimise policies -----
# Use the same bounds, tolerance and five age-varying starts as optimise.R.
deaths_at_dose <- function(dose, pars, q_pct) {
  dose <- c(1, 1, rep(dose, length.out = 7))
  pars <- apap_2v(pars, len = 100 / q_pct, fractional_dose = dose)
  pars$e1 <- phi_sigmoid(dose)
  y <- sr(pars)
  sum(y[Ndays, "D", ] * pop)
}

fits <- list()
for (setting in c("original", "simplified")) {
  pars <- if (setting == "original") pars_original else pars_simplified
  no_vaccine <- sr(pars)
  stopifnot(abs(which.max(drop(no_vaccine[, "I", ] %*% pop)) -
                peak_time(pars)) < 0.6)
  no_vaccine_deaths <- sum(no_vaccine[Ndays, "D", ] * pop)
  for (q_pct in c(0.1, 1)) {
    message("Fitting ", setting, ", supply = ", q_pct, "% per day")
    objective <- function(dose) deaths_at_dose(dose, pars, q_pct)
    full_deaths <- objective(1)
    uniform <- optimize(objective, c(0.01, 1), tol = 1e-7)
    dose_grid <- tibble(dose = seq(0.01, 1, length.out = 101)) %>%
      mutate(deaths = map_dbl(dose, objective))
    stopifnot(uniform$objective <= min(dose_grid$deaths) + 1e-9)
    age_fits <- map(c(uniform$minimum, 0.25, 0.75, 0.01, 1),
      function(start) nloptr(
        x0 = rep(start, 7), eval_f = objective,
        lb = rep(0.01, 7), ub = rep(1, 7),
        opts = list(algorithm = "NLOPT_LN_COBYLA", xtol_rel = 1e-6,
                    maxeval = 5000, print_level = 0)))
    stopifnot(all(map_int(age_fits, "status") > 0))
    best_age <- age_fits[[which.min(map_dbl(age_fits, "objective"))]]
    stopifnot(best_age$objective <= uniform$objective + 1e-8)
    fits[[paste(setting, q_pct, sep = "_")]] <- list(
      setting = setting, q_pct = q_pct, parameters = pars,
      no_vaccine_deaths = no_vaccine_deaths,
      no_vaccine_peak_day = which.max(drop(
        no_vaccine[, "I", ] %*% pop)),
      no_vaccine_peak_time = peak_time(pars),
      full_deaths = full_deaths, uniform = uniform, dose_grid = dose_grid,
      age_fits = age_fits, best_age = best_age)
    saveRDS(list(seed = seed, peak_target = peak_target, fits = fits),
            "sensitivity/initial_conditions_results.rds")
  }
}

# Save comparisons -----
comparison <- map_dfr(fits, function(fit) {
  tibble(setting = fit$setting, q_pct = fit$q_pct,
    exposed_seed_min = min(fit$parameters$y0[2, ]),
    exposed_seed_max = max(fit$parameters$y0[2, ]),
    no_vaccine_peak_time = fit$no_vaccine_peak_time,
    uniform_dose = fit$uniform$minimum,
    no_vaccine_deaths = fit$no_vaccine_deaths,
    full_deaths = fit$full_deaths,
    uniform_deaths = fit$uniform$objective,
    age_deaths = fit$best_age$objective) %>%
    mutate(full_averted = 1 - full_deaths / no_vaccine_deaths,
      uniform_averted = 1 - uniform_deaths / no_vaccine_deaths,
      age_averted = 1 - age_deaths / no_vaccine_deaths,
      uniform_gain_pp = 100 * (uniform_averted - full_averted),
      age_gain_pp = 100 * (age_averted - uniform_averted),
      uniform_reduction_vs_full = 1 - uniform_deaths / full_deaths)
})
write_csv(comparison, "sensitivity/initial_conditions_summary.csv")
map_dfr(fits, function(fit) {
  tibble(setting = fit$setting, q_pct = fit$q_pct,
    age_group = colnames(pbc_spread)[3:9], dose = fit$best_age$solution)
}) %>% write_csv("sensitivity/initial_conditions_age_doses.csv")
map_dfr(fits, function(fit) {
  tibble(setting = fit$setting, q_pct = fit$q_pct,
    initial_dose = map_dbl(fit$age_fits, ~ .x$x0[1]),
    objective = map_dbl(fit$age_fits, "objective"),
    status = map_int(fit$age_fits, "status"),
    iterations = map_int(fit$age_fits, "iterations"))
}) %>% write_csv("sensitivity/initial_conditions_starts.csv")
cat("Rounded E_i(0) =", format(seed, digits = 10), "\n")
print(comparison, width = Inf)
