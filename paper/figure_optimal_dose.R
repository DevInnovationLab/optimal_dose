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

frac_vac_365 <- function(q_per_day, age_group, pop, days = 365) {
  pop_use <- tail(pop, length(unique(age_group)))
  rev_cum <- rev(cumsum(rev(pop_use)))
  i <- match(age_group, unique(age_group))
  pmin(1, pmax(0, (q_per_day * days - (rev_cum[i] - pop_use[i])) / pop_use[i]))
}

df_optimal_dose <- df_results %>% 
  filter(key == "frac_age") %>%
  select(scenario, q_per_day, static, dose_name, result_solution) %>% 
  unnest(result_solution) %>% 
  mutate(frac_vac_365 = frac_vac_365(q_per_day, age_group, pop))

plot_age_solutions_dr <- function(scenario_name) {
  df_optimal_dose %>%
    filter(q_per_day %in% q_plot) %>%
    filter(scenario == scenario_name) %>%
    filter(static == "Dynamic case") %>%
    filter(frac_vac_365 > .0001) %>%
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

plot_age_solutions_dr("fast-growth (R0 = 2)")
ggsave("paper/figures/age_solutions_dr.pdf", width = fig_width, height = fig_height,
       unit = "cm")

plot_age_solutions_dr("slow-growth (R0 = 1.1)")
ggsave("paper/figures/age_solutions_dr_slow.pdf", width = fig_width, height = fig_height,
       unit = "cm")
