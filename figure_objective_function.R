df_objf_combined <- df_results %>% 
  filter(static == "Dynamic case") %>% 
  filter(scenario == "fast-growth (R0 = 2)") %>% 
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
  ) 

# define the breaks you actually want shown

x_breaks <- c(28, 180, 360, 720, 1440)
x_labels <- c("1 mo", "6 mo", "1 yr", "2 yr", "4 yr")
fig_foo <- function(df){

df %>%
  filter(!(dose_name == "concave" & key == "full_dose")) %>% 
  ggplot(aes(x = 1/q, 
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
    axis.text.x = element_text(angle = 45, hjust = 1),
    strip.text = element_text(size = 10),
    strip.text.y = element_text(angle = 0),  
    strip.placement = "outside"
  ) +
  labs(
    x = "supply per day", 
    y = NULL
  )
}

left_p <- fig_foo(df_objf_combined %>% filter(metric_type == "deaths_vs_no_vaccine")) + 
  coord_cartesian(xlim = c(0, .02)) + 
  scale_x_continuous(breaks = c(0.0025, 0.01, 0.02), labels = c("0.25%", "1%", "2%")) + 
  theme(legend.position = "none") +
  ggtitle("vs no vaccine") + ylab("relative mortality")
right_p <- fig_foo(df_objf_combined %>% filter(metric_type != "deaths_vs_no_vaccine")) + 
  coord_cartesian(xlim = c(0, .05)) + 
  scale_x_continuous(breaks = c(0.0025, seq(0.01, 0.05, by = 0.01)), labels = c("0.25%", paste0(1:5, "%"))) +
  ggtitle("vs standard dose")

left_p + 
  right_p + 
  plot_layout(widths = c(3, 4), guides = "collect") &
  theme(legend.position = "bottom",
        legend.box = "vertical",        # stack the two legends (dose response above dose choice)
        legend.box.just = "center",
        legend.spacing.y = unit(4, "pt"))

ggsave("paper/figures/reductions_dr.pdf", width=16, height = 11, unit = "cm")
