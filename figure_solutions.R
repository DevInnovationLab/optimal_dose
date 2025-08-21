q_table <- c(0.03, 0.02, 0.01, 0.005, 0.003, 0.001, 0.0005)
q_labels <- scales::percent(q_table)

df_optimal_dose <- df_results %>% 
  filter(key == "frac_age") %>%
  filter(scenario == "fast-growth (R0 = 2)") %>% 
  select(q_per_day, static, dose_name, result_solution) %>% 
  unnest(result_solution) %>% 
  filter(q_per_day %in% q_table)


df_optimal_dose %>% 
  filter(static == "Dynamic case") %>% 
  filter(frac_vac > .01) %>%
  mutate(dose_name = paste(dose_name, "dose response")) %>% 
  mutate(q_per_day = factor(q_per_day, levels = q_table, labels = q_labels)) %>% 
  ggplot(aes(x = age_group, y = solution)) + 
  geom_point(aes(color = q_per_day)) + 
  geom_line(aes(group = q_per_day, color = q_per_day)) + 
  facet_grid(. ~ dose_name) +
  scale_color_discrete(name = "supply (standard doses) per day") +
  labs(x = "", y = "Optimal Dose Fraction") + 
  ylim(0, 1) +
  theme_minimal(base_size = 12) + 
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.spacing.y = unit(0, "cm"),
    legend.key.size = unit(0.7, "lines")
  ) +
  guides(color = guide_legend(nrow = 2)) 

ggsave("paper/figures/age_solutions_dr.pdf", width=16, height = 11, unit = "cm")
