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

# Optimal doses -----

# results_frac_uniform_dynamic %>% unnest(result_solution) %>% 
#   select(q, dose_name, scenario, solution) %>% distinct() %>% 
#   arrange(scenario) %>% 
#   spread(dose_name, solution)



# Visualise optimal dose -----

df_optimal_dose <- df_results %>% 
  filter(key == "frac_age") %>%
  select(q, static, scenario, dose_name, result_solution) %>% 
  unnest(result_solution)

df_optimal_dose %>% 
  filter(static == "Dynamic case") %>% 
  filter(frac_vac > .04) %>%
  mutate(dose_name = paste(dose_name, "dose response")) %>% 
  mutate(q = factor(q)) %>% 
  ggplot(aes(x = age_group, y = solution)) + 
  facet_grid(scenario ~ dose_name) + 
  geom_point(aes(color = q)) + 
  geom_line(aes(
    group = q,
    color = q
  )) + 
  scale_color_discrete(name = "length of\nvaccination\ncampaign (days)") +
  labs(x = "", y = "Optimal Dose Fraction") + 
  ylim(0, 1) +
  theme_minimal() + 
  # theme_bw(base_size = 10) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1),
    # legend.key.size = unit(0.7, "lines"),
    legend.spacing.y = unit(0, "cm"),
    legend.key.size = unit(0.7, "lines")
    # legend.title = element_text(hjust = 0.5) 
  ) 

ggsave("paper/figures/age_solutions_dr.pdf", width=14, height = 14, unit = "cm")


# Currently not showing static case
df_optimal_dose %>%
  filter(static == "Static case") %>%
  mutate(q = factor(q)) %>%
  ggplot(aes(x = age_group, y = solution)) +
  facet_grid(dose_name ~ scenario) +
  geom_point(aes(color = q)) +
  geom_line(aes(
    group = q,
    color = q
  )) +
  scale_color_discrete(name = "supply \n(fraction of \npopulation)") +
  labs(x = "Age Group", y = "Optimal Dose Fraction") +
  ylim(0, 1) +
  # theme_bw(base_size = 10) +
  theme(legend.position = "bottom",axis.text.x = element_text(angle = 45, hjust = 1),
        legend.spacing.y = unit(0, "cm"),
        legend.key.size = unit(0.7, "lines")) +
  ggtitle("Optimal dose: static case") +
  theme(axis.title.x = element_blank())



# Table with optimal solutions -----
q_val <- c(100, 200, 500, 2000)
# q_lab <- c("Three month campaign", "Six month campaign", "One year campaign", "60+ yo only in one year")
q_lab <- c(100, 200, 500, 2000)

df_obj_tab <- df_results %>% 
  select(-result_solution) %>% 
  mutate(key = factor(key, levels = optim_lvls, labels = optim_names)) %>% 
  mutate(reduction = 1 - value/no_vac) %>% 
  mutate(value = value*10000) %>% 
  filter(static == "Dynamic case") %>% 
  mutate(value = paste0(
    format(round(value, 1), nsmall = 1),
    " (", percent(reduction, 1), ")")) %>% 
  filter(q %in% q_val) %>% 
  mutate(q = factor(q, levels = q_val, labels = q_lab)) %>%
  select(scenario, static, q, dose_name, key, value) %>% 
  spread(key, value) %>% 
  arrange(dose_name, scenario) %>% 
  left_join (
    df_results %>% 
      filter(static == "Dynamic case") %>% 
      filter(key == "frac_uniform") %>% 
      unnest(result_solution) %>% 
      select(q, scenario, solution, dose_name) %>% distinct %>%
      arrange(scenario, q) %>% 
      filter(q %in% q_val) %>% 
      mutate(q = factor(q, levels = q_val, labels = q_lab)) %>% 
      mutate(solution = round(solution, 2)) %>% 
      rename(dose = solution)
  ) 

df_obj_tab



# concave case
latex_table <- df_obj_tab[1:8,] %>% 
  ungroup() %>% 
  select(-static, -scenario, -dose_name) %>% 
  knitr::kable(format = "latex", booktabs = TRUE) %>% 
  add_header_above(c(" ", "Deaths per 10,000" = 3)) %>% 
  pack_rows("Fast-growing epidemic, R0 = 2", 1, 4) %>% 
  pack_rows("Slow-growing epidemic, R0 = 1.1", 5,8)

writeLines(latex_table, "paper/table_concave.tex")

# sigmoid case
latex_table <- df_obj_tab[9:16,] %>% 
  ungroup() %>% 
  select(-static, -scenario, -dose_name) %>% 
  knitr::kable(format = "latex", booktabs = TRUE) %>% 
  add_header_above(c(" ", "Deaths per 10,000" = 3)) %>% 
  pack_rows("Fast-growing epidemic, R0 = 2", 1, 4) %>% 
  pack_rows("Slow-growing epidemic, R0 = 1.1", 5,8)

writeLines(latex_table, "paper/table_sigmoid.tex")



# Visualise objective function (death burden) -----

# Simple version
df_results %>% 
  filter(static == "Dynamic case") %>% 
  ggplot(aes(x = 1/q, y = value, 
             color = interaction(key, dose_name))) + 
  geom_point() + 
  geom_line() +
  facet_wrap(scenario ~ ., scales = "free")



# Now make prettier
# Reshape data to include both metrics
df_objf_combined <- df_results %>% 
  filter(static == "Dynamic case") %>% 
  select(-result_solution) %>% 
  group_by(q,static,scenario,dose_name) %>% 
  mutate(
    deaths_vs_no_vaccine = value/no_vac,
    deaths_vs_full_dose = value/max(value)
  ) %>%
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

# define the breaks you actually want shown
x_breaks <- c(28, 180, 360, 720, 1440)
x_labels <- c("1 mo", "6 mo", "1 yr", "2 yr", "4 yr")

gg_combined <- df_objf_combined %>%
  filter(q < 2000) %>% 
  filter(!(dose_name == "concave" & key == "full_dose")) %>% 
  ggplot(aes(x = q, 
             group = interaction(key, dose_name), 
             color = key, 
             linetype = dose_name,
             y = metric_value)) + 
  geom_line(size = 1) +
  scale_color_manual(
    name = "dose choice",
    labels = optim_names,
    values = optim_values
  ) +
  scale_linetype_manual(
    name = "dose response",
    values = c(concave = "dotted", sigmoid = "solid"),
    labels = c(concave = "Concave", sigmoid = "Sigmoid")
  ) +
  scale_x_continuous(
    breaks = c(28, 180, 360, 720, 1440),
    labels = c("1 mo", "6 mo", "1 yr", "2 yr", "4 yr"),
    expand = expansion(mult = c(0, 0.02))
  ) +
  guides(
    linetype = guide_legend(
      order = 1,
      nrow = 1,
      byrow = TRUE,
      title.position = "left",
      override.aes = list(color = "black", linewidth = 1.2)
    ),
    color = guide_legend(
      order = 2,
      nrow = 1,
      byrow = TRUE,
      title.position = "left",
      override.aes = list(linewidth = 1.2)
    )
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.box = "vertical",        # stack the two legends (dose response above dose choice)
    legend.box.just = "center",
    legend.spacing.y = unit(4, "pt"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(size = 10),
    strip.text.y = element_text(angle = 0),  
    strip.placement = "outside"
  ) +
  facet_grid(
    metric_label ~ scenario, 
    scales = "free_y",
    switch = "y",
    labeller = labeller(metric_label = label_wrap_gen(width = 25))
  ) +
  labs(
    x = "length of vaccination campaign", 
    y = NULL,
    title = "Mortality reductions"
  )


gg_combined

ggsave("paper/figures/reductions_dr.pdf", width=14, height = 16, unit = "cm")

