source("project_setup.R")

library(ggplot2)
library(knitr)
library(kableExtra)
library(scales)
library(patchwork)

theme_set(theme_minimal(base_size = 11))

# Visualise dose-response -----

df <- tibble(x = seq(0, 1, length.out = 1001)) %>%
  mutate(
    sigmoid = dr_foos$sigmoid(x),
    concave = dr_foos$concave(x)
  ) %>%
  pivot_longer(-x, names_to = "curve", values_to = "y")

dr_plot <- ggplot(df, aes(x, y, linetype = curve)) +
  geom_line(size = 1) +
  scale_linetype_manual(
    values = c(concave = "dashed", sigmoid = "solid"),
    labels = c(concave = "Concave", sigmoid = "Sigmoid")
  ) +
  scale_x_continuous(breaks = c(0, 0.5, 1)) +
  scale_y_continuous(breaks = c(0, 0.5, 0.8, 1), limits = c(0, 1)) +
  geom_hline(yintercept = c(0.5, 0.8), linetype = "dotted", color = "grey70") +
  geom_vline(xintercept = 0.5, linetype = "dotted", color = "grey70") +
  coord_cartesian(clip = "off") +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    panel.grid.minor = element_blank()
  ) +
  labs(x = "x", y = "efficacy") +
  ggtitle("Dose-response")

dr_plot

ggsave("paper/figures/dose_response.pdf", width = 10, height = 8, unit = "cm")
