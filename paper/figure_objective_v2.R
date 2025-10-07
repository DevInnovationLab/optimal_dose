library(ggplot2)
library(dplyr)
library(readr)
library(knitr)
library(kableExtra)
library(scales)
library(patchwork)

theme_set(theme_minimal(base_size = 11))

df <- readRDS("results/nlopt_results.rds") %>%
  filter(static == "Dynamic case",
         scenario == "fast-growth (R0 = 2)") %>%
  select(-result_solution) %>%
  group_by(q, static, scenario, dose_name) %>%
  mutate(deaths_vs_full_dose = value / max(value)) %>%
  ungroup()

df %>%
  filter(key != "full_dose") %>%
  ggplot(aes(x = 1 / q,
             y = (1 - deaths_vs_full_dose) * 100,   # percentage-point improvement
             color = dose_name,
             linetype = key)) +
  geom_line(linewidth = 1) +
  scale_x_log10(
    breaks = c(0.01/100, 0.1/100, 1/100, 10/100),
    labels = c("0.01", "0.1", "1", "10"),
    name = "Vaccine supply\n(% population supplied per day, log scale)"
  ) +
  scale_y_continuous(name = "Percentage-point improvement") +
  annotate("text", x = 0.0005, y = 25, label = "Concave", color = "blue", hjust = 0) +
  annotate("text", x = 0.02, y = 12, label = "Sigmoid", color = "red", hjust = 0) +
  scale_color_manual(values = c(concave = "blue", sigmoid = "red")) +
  scale_linetype_manual(values = c(frac_age = "dashed", frac_uniform = "solid")) +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) 

ggsave("paper/figures/improvement.pdf", width = 12, height = 8, units = "cm")
