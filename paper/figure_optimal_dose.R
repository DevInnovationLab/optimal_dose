# Plot doses for cohorts vaccinated by the population-wide infection peak.
# Use the saved vaccinated fraction and the 5% display threshold.

source("project_setup.R")

library(ggplot2)
library(knitr)
library(kableExtra)
library(scales)
library(patchwork)

theme_set(theme_minimal(base_size = 11))

optim_names <- c("Age-specific", "Age-invariant", "Standard dose")
optim_values <- c("#E69F00", "#56B4E9", "black")
optim_lvls <- c("frac_age", "frac_uniform", "full_dose")

df_results <- readRDS("results/nlopt_results.rds")

q_plot <- c(0.1, 0.01, 0.001, 0.0001)
q_labels <- c("10%", "1%", "0.1%", "0.01%")
q_colours <- c(
  "10%" = "#D55E00",
  "1%" = "#0072B2",
  "0.1%" = "#009E73",
  "0.01%" = "#CC79A7"
)
fig_width <- 15.9
fig_height <- fig_width * 10 / 16.5

df_optimal_dose <- df_results %>%
  filter(key == "frac_age", static == "Dynamic case", q_per_day %in% q_plot) %>%
  select(scenario, q, q_per_day, dose_name, result_solution) %>%
  unnest(result_solution)
write_csv(df_optimal_dose, "paper/figures/age_solutions_coverage.csv")

plot_age_solutions_dr <- function() {
  df_optimal_dose %>%
    filter(q_per_day %in% q_plot) %>%
    # frac_vac sums P1 + N1 + P2 + N2 at peak total infectious prevalence.
    # Keep cohorts with more than 5% vaccinated at that peak.
    filter(frac_vac > .05) %>%
    mutate(
      dose_name = factor(
        dose_name,
        levels = c("sigmoid", "concave"),
        labels = c("Sigmoid dose response", "Concave dose response")
      ),
      q_per_day = factor(q_per_day, levels = q_plot, labels = q_labels)
    ) %>%
    ggplot(aes(x = age_group, y = solution)) +
    geom_point(aes(color = q_per_day)) +
    geom_line(aes(group = q_per_day, color = q_per_day)) +
    facet_grid(. ~ dose_name) +
    scale_colour_manual(
      name = "Vaccine supply\n(% population supplied per day)",
      values = q_colours
    ) +
    labs(x = "Age cohort", y = "Optimal dose fraction") +
    ylim(0, 1) +
    theme(
      legend.position = "bottom",
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.spacing.y = unit(0, "cm"),
      legend.key.size = unit(0.7, "lines")
    ) +
    guides(color = guide_legend(nrow = 1))
}

plot_age_solutions_dr()
ggsave("paper/figures/age_solutions_dr.pdf", width = fig_width,
       height = fig_height, unit = "cm")
