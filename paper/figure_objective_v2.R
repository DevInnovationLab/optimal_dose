# Plot reductions in deaths relative to the full-dose policy.

library(ggplot2)
library(dplyr)
library(readr)
library(knitr)
library(kableExtra)
library(scales)
library(patchwork)

theme_set(theme_minimal(base_size = 11))

df_results <- readRDS("results/nlopt_results.rds") %>%
  filter(static == "Dynamic case")
full_dose <- df_results %>%
  filter(key == "full_dose") %>%
  select(q, scenario, dose_name, full_dose_deaths = value)
df_obj_plot <- df_results %>%
  select(-result_solution) %>%
  left_join(full_dose, by = c("q", "scenario", "dose_name"),
            relationship = "many-to-one") %>%
  mutate(y2 = 100 * (1 - value / full_dose_deaths))
stopifnot(!anyNA(df_obj_plot$full_dose_deaths))

for (filt in c(TRUE, FALSE)) {
  y_pos <- ifelse(filt, 25, 30)
  
  gg_obj_plot <- df_obj_plot %>% 
    filter((scenario == "fast-growth (R0 = 2)") == filt) %>% 
    filter(key != "full_dose") %>%
    ggplot(aes(x = 1 / q,
               y = y2,
               color = dose_name,
               linetype = key)) +
    geom_line(linewidth = 1) +
    scale_x_log10(
      breaks = c(0.01/100, 0.1/100, 1/100, 10/100),
      labels = c("0.01", "0.1", "1", "10"),
      name = "Vaccine supply\n(% population supplied per day, log scale)"
    ) +
    scale_y_continuous(
      name = "Reduction in deaths\nrelative to full doses (%)") +
    annotate("text", x = 0.0005, y = y_pos, label = "Concave", color = "blue", hjust = 0) +
    annotate("text", x = 0.02, y = 12, label = "Sigmoid", color = "red", hjust = 0) +
    scale_color_manual(values = c(concave = "blue", sigmoid = "red")) +
    scale_linetype_manual(values = c(frac_age = "dashed", frac_uniform = "solid")) +
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 45, hjust = 1)
    ) 
  if(filt) ggname <- "paper/figures/improvement.pdf" else ggname <- "paper/figures/improvement_slow.pdf"
  ggsave(filename = ggname, plot = gg_obj_plot, 
         width = 12, height = 8, units = "cm")
}


dir.create("overleaf/figures", showWarnings = FALSE)
stopifnot(file.copy(c("paper/figures/improvement.pdf",
            "paper/figures/improvement_slow.pdf"),
          "overleaf/figures", overwrite = TRUE))
