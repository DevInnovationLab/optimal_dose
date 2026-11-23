# Generate the calibration rows used by both manuscript results tables.
# Read the same saved objectives and doses used by the paper's figures.

library(tidyverse)

q_table <- c(0.0001, 0.001, 0.01, 0.1)
df_results <- readRDS("results/nlopt_results.rds") %>%
  filter(static == "Dynamic case", q_per_day %in% q_table)
uniform_doses <- df_results %>%
  filter(key == "frac_uniform") %>%
  select(scenario, dose_name, q_per_day, result_solution) %>%
  unnest(result_solution) %>%
  group_by(scenario, dose_name, q_per_day) %>%
  summarise(uniform_dose = first(solution),
            n_doses = n_distinct(solution), .groups = "drop")
stopifnot(all(uniform_doses$n_doses == 1))

calibration_results <- df_results %>%
  mutate(averted = 100 * (1 - value / no_vac)) %>%
  select(scenario, dose_name, q_per_day, key, averted) %>%
  pivot_wider(names_from = key, values_from = averted) %>%
  left_join(uniform_doses, by = c("scenario", "dose_name", "q_per_day"),
            relationship = "one-to-one") %>%
  select(-n_doses) %>%
  arrange(scenario, dose_name, q_per_day)
stopifnot(nrow(calibration_results) == 8, !anyNA(calibration_results))
write_csv(calibration_results, "paper/tables/calibration_results.csv")

rows <- character()
for (dose_response in c("sigmoid", "concave")) {
  values <- calibration_results %>% filter(dose_name == dose_response)
  heading <- if (dose_response == "sigmoid") "Sigmoid" else "Concave"
  rows <- c(rows, "\\midrule",
    paste0("\\mc{7}{c}{\\bf ", heading, " Dose Response} \\\\[2ex]"),
    sprintf(
      r"(%.2g\%% & 100\%% & %d\%% & \mc{1}{c}{Fig.~\ref{fig:age_solutions_both}} & %d\%% & %d\%% & %d\%% \\)",
      100 * values$q_per_day, round(100 * values$uniform_dose),
      round(values$full_dose), round(values$frac_uniform),
      round(values$frac_age)))
}
writeLines(c("\\newcommand{\\calibrationrows}{%", rows, "}"),
           "paper/tables/calibration_rows.tex")
