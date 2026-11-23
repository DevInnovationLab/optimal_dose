# Compare one-at-a-time sensitivities at 0.1% daily supply, sigmoid response,
# and a common 360-day outcome horizon. Calibrate attack rate and peak timing
# jointly so each comparison changes one epidemiological outcome at a time.

library(tidyverse)
source("setup/model_2vaccine.R")
source("R/single_run.R")
source("setup/parametrisation.R")

source("R/scenario_calibration.R")

refit <- FALSE
model_code <- c(readLines("setup/model_2vaccine.R"),
                readLines("R/scenario_calibration.R"),
                readLines("setup/parametrisation.R"),
                readLines("R/single_run.R"))
solver <- calibration_solver

# Helpers -----
simulate <- function(pars) do.call(sr, c(list(pars = pars), solver))

deaths_at_dose <- function(dose, pars, reach, pop_sizes) {
  dose <- c(1, 1, rep(dose, 7))
  pars <- apap_2v(pars, len = 1000, fractional_dose = dose, vhes = reach,
                  pop_sizes = pop_sizes)
  pars$e1 <- phi_sigmoid(dose)
  y <- simulate(pars)
  stopifnot(min(y[, c("S", "E", "I", "R", "D", "P1", "N1"), ]) > -1e-8)
  sum(y[Ndays, "D", ] * pop_sizes)
}

# Calibrate attack-rate and timing alternatives -----
calibration <- bind_rows(
  bind_cols(tibble(id = "baseline", r0_value = base_r0,
    seed = initial_exposed, target_attack = .5, target_peak_months = 3),
    epidemic_outcomes(pars_base)),
  map_dfr(c(.3, .7), function(attack) {
    message("Calibrating attack rate ", attack)
    bind_cols(tibble(id = paste0("attack_", 100 * attack)),
      calibrate_epidemic(attack, 3))
  }),
  map_dfr(c(2, 4, 6), function(months) {
    message("Calibrating peak near ", months, " months")
    bind_cols(tibble(id = paste0("peak_", months)),
      calibrate_epidemic(.5, months))
  }))
write_csv(calibration, "sensitivity/analysis_calibration.csv")
calibration %>% filter(id == "baseline" | str_starts(id, "peak_")) %>%
  arrange(target_peak_months) %>%
  write_csv("sensitivity/analysis_timing.csv")

cases <- tribble(
  ~id, ~group, ~label, ~reach, ~vaccinate_recovered,
  "baseline", "Baseline", "Baseline", .8, 1,
  "attack_30", "Attack rate", "30% attack rate", .8, 1,
  "attack_70", "Attack rate", "70% attack rate", .8, 1,
  "reach_60", "Vaccine reach", "60% reachable", .6, 1,
  "reach_30", "Vaccine reach", "30% reachable", .3, 1,
  "no_recovered", "Eligible recipients", "Recovered excluded", .8, 0,
  "peak_2", "Peak timing", "Peak near 2 months", .8, 1,
  "peak_4", "Peak timing", "Peak near 4 months", .8, 1,
  "peak_6", "Peak timing", "Peak near 6 months", .8, 1,
  "demography_lic", "Demographics", "Low-income countries", .8, 1
) %>%
  mutate(calibration_id = if_else(id %in% calibration$id, id, "baseline")) %>%
  left_join(calibration %>% select(calibration_id = id, r0_value, seed,
    target_attack, target_peak_months), by = "calibration_id") %>%
  select(-calibration_id) %>%
  mutate(across(c(target_attack, target_peak_months),
    ~ if_else(id == "demography_lic", NA_real_, .x)))

# Fit the scenarios -----
fits <- if (!refit && file.exists("sensitivity/analysis_results.rds")) {
  readRDS("sensitivity/analysis_results.rds")
} else list()
if (!identical(attr(fits, "model_code"), model_code)) fits <- list()
for (i in seq_len(nrow(cases))) {
  case <- cases[i, ]
  pars <- epidemic_parameters(case$r0_value, case$seed)
  pars$vrf <- case$vaccinate_recovered
  pop_sizes <- if (case$id == "demography_lic") lic_pop / sum(lic_pop) else pop
  cached <- fits[[case$id]]
  if (!is.null(cached) && identical(cached$parameters, pars) &&
      identical(cached$case, case) && identical(cached$solver, solver) &&
      identical(cached$population, pop_sizes)) next
  message("Fitting ", case$id)
  no_vaccine <- simulate(pars)
  no_vaccine_deaths <- sum(no_vaccine[Ndays, "D", ] * pop_sizes)
  stopifnot(no_vaccine_deaths > 0)
  objective <- function(dose) deaths_at_dose(dose, pars, case$reach, pop_sizes)
  full_deaths <- objective(1)
  grid <- tibble(dose = seq(.01, 1, length.out = 101)) %>%
    mutate(deaths = map_dbl(dose, objective))
  # Refine every grid-local minimum, rather than assuming a unimodal objective.
  minima <- which(grid$deaths <= c(Inf, head(grid$deaths, -1)) &
                  grid$deaths <= c(tail(grid$deaths, -1), Inf))
  searches <- map(minima, function(j) optimize(objective,
    grid$dose[c(max(1, j - 1), min(nrow(grid), j + 1))], tol = 1e-7))
  candidates <- bind_rows(grid,
    map_dfr(searches, ~ tibble(dose = .x$minimum, deaths = .x$objective)))
  best <- candidates %>% slice_min(deaths, n = 1, with_ties = FALSE)
  stopifnot(best$deaths <= min(grid$deaths) + 1e-10,
            best$deaths <= full_deaths + 1e-10)
  fits[[case$id]] <- list(case = case, parameters = pars, solver = solver,
    population = pop_sizes, no_vaccine_deaths = no_vaccine_deaths,
    outcomes = epidemic_outcomes(pars, pop_sizes),
    full_deaths = full_deaths, uniform_dose = best$dose,
    uniform_deaths = best$deaths, grid = grid, searches = searches)
  attr(fits, "model_code") <- model_code
  saveRDS(fits, "sensitivity/analysis_results.rds")
}

# Save outcomes and appendix rows -----
summary <- map_dfr(fits[cases$id], function(fit) {
  bind_cols(fit$case, tibble(peak_day = fit$outcomes$peak_day,
    peak_months = fit$outcomes$peak_months, attack_360 = fit$outcomes$attack_360,
    no_vaccine_deaths = fit$no_vaccine_deaths, full_deaths = fit$full_deaths,
    uniform_dose = fit$uniform_dose, uniform_deaths = fit$uniform_deaths)) %>%
    mutate(full_averted = 1 - full_deaths / no_vaccine_deaths,
      uniform_averted = 1 - uniform_deaths / no_vaccine_deaths,
      uniform_gain_pp = 100 * (uniform_averted - full_averted),
      reduction_vs_full = 1 - uniform_deaths / full_deaths)
})
write_csv(summary, "sensitivity/analysis_summary.csv")

appendix <- summary %>% mutate(
  label = case_when(id == "baseline" ~ "Base case",
    id %in% c("attack_30", "attack_70") ~
      sprintf("%s ($\\Rzero = %.2f$)", label, r0_value),
    TRUE ~ label),
  group = recode(group,
    `Attack rate` = "Attack rate (base case = 50\\%)",
    `Vaccine reach` = "Vaccine reach (base case = 80\\% of each age cohort)",
    `Eligible recipients` = "Eligible recipients (base case includes recovered individuals)",
    `Peak timing` = "Timing of epidemic peak (base case = 3 months)",
    `Demographics` = "Demographics (base case = high-income countries)"))
rows <- character()
for (group_name in unique(appendix$group)) {
  data <- appendix %>% filter(.data$group == .env$group_name)
  if (group_name != "Baseline") rows <- c(rows, "\\addlinespace[1ex]",
    paste0("\\multicolumn{5}{@{}l}{\\textbf{", group_name, "}}\\\\"))
  labels <- str_replace_all(data$label, fixed("%"), function(x) rep("\\%", length(x)))
  rows <- c(rows, sprintf(
    "%s & %.1f\\%% & %.1f\\%% & %.1f\\%% & %.1f\\%% \\\\",
    labels, 100 * data$uniform_dose,
    100 * data$full_averted, 100 * data$uniform_averted,
    100 * data$reduction_vs_full))
}
writeLines(rows, "paper/tables/sensitivity_rows.tex")
print(summary %>% select(id, r0_value, seed, attack_360, peak_months, uniform_dose,
  full_averted, uniform_averted, reduction_vs_full), n = Inf, width = Inf)
