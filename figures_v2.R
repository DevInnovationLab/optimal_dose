# Table 1

library(scales)
optim_names <- c("Age-specific", "Age-invariant", "Full dose")
optim_values <- c("#E69F00", "#56B4E9", "black")
optim_lvls <- c("frac_age", "frac_uniform", "full_dose")

df_obj_tbl <- results_bc_hic %>% 
  rowwise() %>% 
  ungroup() %>% 
  mutate(vacc_daily = 1/q) %>% 
  mutate(setting = q) %>% 
  select(setting, static, scenario, vacc_daily,
         full_dose, frac_uniform, frac_age, no_vac,
         pdeath) %>% 
  gather(key, value, -setting, -vacc_daily, -static, -scenario, -pdeath, -no_vac) %>% 
  group_by(setting, scenario, static) %>% 
  mutate(value = ifelse(key == "full_dose", max(value), value)) %>% 
  mutate(reduction = 1 - value/100) %>% 
  mutate(value_prop = value/max(value)) %>%
  ungroup %>%
  mutate(key = factor(key, levels = optim_lvls, 
                      labels = optim_names)) %>% 
  filter(static == "Dynamic case") %>% 
  mutate(value = (value/100)*no_vac*10000) %>% 
  mutate(value = paste0(
    format(round(value, 1), nsmall = 1),
    " (", percent(reduction, 1), ")")) %>% 
  filter(setting %in% c(90, 180, 360, 1440)) %>% 
  mutate(q = factor(setting, levels = c(90, 180, 360, 1440), labels = c(
    "Three month campaign", "Six month campaign", "One year campaign", "60+ yo only in one year"))) %>%
  select(scenario, static, q, key, value) %>% 
  spread(key, value)

df_doses <- results_bc_hic %>% 
  filter(static == "Dynamic case") %>% 
  unnest(frac_uniform_sol) %>% 
  select(q, scenario, solution) %>% distinct %>%
  arrange(scenario, q) %>% 
  filter(q %in% c(90, 180, 360, 1440)) %>% 
  mutate(q = factor(q, levels = c(90, 180, 360, 1440), labels = c(
    "Three month campaign", "Six month campaign", "One year campaign", "60+ yo only in one year"))) %>% 
  mutate(solution = round(solution, 2)) %>% 
  rename(dose = solution)


latex_table <- df_obj_tbl %>% 
  left_join(df_doses, by = c("q", "scenario")) %>% 
  select(-scenario, -static) %>% 
  knitr::kable(format = "latex", booktabs = TRUE) %>% 
  add_header_above(c(" ", "Deaths per 10,000" = 3)) %>% 
  pack_rows("Fast-growing epidemic, R0 = 2", 1, 4) %>% 
  pack_rows("Slow-growing epidemic, R0 = 1.1", 5,8)

writeLines(latex_table, "paper/table.tex")





# Figure 1

library(dplyr)
library(ggplot2)
library(tidyr)

# Reshape data to include both metrics
df_combined <- df_obj_f_dynamic %>%
  mutate(
    deaths_vs_no_vaccine = value/100,
    deaths_vs_full_dose = value_prop
  ) %>%
  select(-value, -value_prop) %>%
  pivot_longer(
    cols = c(deaths_vs_no_vaccine, deaths_vs_full_dose),
    names_to = "metric_type",
    values_to = "metric_value"
  ) %>%
  mutate(
    metric_label = factor(metric_type,
                          levels = c("deaths_vs_no_vaccine", "deaths_vs_full_dose"),
                          labels = c(
                            "Mortality relative to no vaccination",
                            "Mortality relative to standard dose")
    )
  )
gg_combined <- df_combined %>%
  ggplot(aes(x = setting, 
             group = key, 
             color = key, 
             y = metric_value)) + 
  geom_line() +
  scale_color_manual(labels = optim_names,
                     values = optim_values) +
  theme(legend.position = "bottom", 
        legend.title = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1),
        strip.text = element_text(size = 10),
        strip.text.y = element_text(angle = 0),  # Keep text horizontal
        strip.placement = "outside") +           # Place strips outside plot area
  facet_grid(metric_label ~ scenario, 
             scales = "free_y",
             switch = "y",                        # Move row labels to left
             labeller = labeller(metric_label = label_wrap_gen(width = 25))) +
  labs(x = "length of vaccination campaign (days)", 
       y = NULL) +                              # Remove y-axis label
  ggtitle("Mortality reductions")


# (gg_objd1 + ggtitle("Mortality relative to no vaccine")) / 
#   (gg_objd2 + ggtitle("Mortality relative to standard dose") + theme(legend.title = element_blank())) /
#   age_solutions_dynamic + ggtitle("Optimal age-specific dose") + 
#   plot_layout(heights = c(1, 1, 2))
gg_combined /
  (age_solutions_dynamic + ggtitle("Optimal age-specific dose")) +
  plot_layout(heights = c(3.2, 2))

ggsave("paper/figures/obj_solution.pdf", width = 16, height = 22.5, unit = "cm")


