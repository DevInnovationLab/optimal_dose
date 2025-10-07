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

q_table <- c(0.1, 0.02, 0.01, 0.005, 0.002, 0.001)
q_plot <- c(0.1, 0.02, 0.01, 0.005, 0.001)
q_labels <- scales::percent(q_table)

frac_vac_365 <- function(q_per_day, age_group, pop, days = 365) {
  pop_use <- tail(pop, length(unique(age_group)))
  rev_cum <- rev(cumsum(rev(pop_use)))
  i <- match(age_group, unique(age_group))
  pmin(1, pmax(0, (q_per_day * days - (rev_cum[i] - pop_use[i])) / pop_use[i]))
}

df_optimal_dose <- df_results %>% 
  filter(key == "frac_age") %>%
  filter(scenario == "fast-growth (R0 = 2)") %>% 
  select(q_per_day, static, dose_name, result_solution) %>% 
  unnest(result_solution) %>% 
  mutate(frac_vac_365 = frac_vac_365(q_per_day, age_group, pop))

df_optimal_dose %>% 
  filter(q_per_day %in% q_plot) %>% 
  filter(static == "Dynamic case") %>% 
  filter(frac_vac_365 > .0001) %>%
  mutate(dose_name = stringr::str_to_title(paste(dose_name, "dose response"))) %>% 
  mutate(q_per_day = factor(q_per_day, levels = q_table, labels = q_labels)) %>% 
  ggplot(aes(x = age_group, y = solution)) + 
  geom_point(aes(color = q_per_day)) + 
  geom_line(aes(group = q_per_day, color = q_per_day)) + 
  facet_grid(. ~ dose_name) +
  scale_color_manual(
    name = "Supply (standard doses) per day",
    values = scales::seq_gradient_pal("lightblue", "darkblue", "Lab")(seq(1, 0, length.out = 6))
  ) +
  labs(x = "Age cohort", y = "Optimal dose fraction") + 
  ylim(0, 1) +
  theme_minimal(base_size = 12) + 
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.spacing.y = unit(0, "cm"),
    legend.key.size = unit(0.7, "lines")
  ) +
  guides(color = guide_legend(nrow = 1)) 

ggsave("paper/figures/age_solutions_dr.pdf", width=16.5, height = 10, unit = "cm")
