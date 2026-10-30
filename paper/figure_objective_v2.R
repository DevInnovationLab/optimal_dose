# Plot reductions in deaths relative to full-dose and no-vaccine deaths.
# Save the manuscript figures and comparisons of the two denominators.

library(ggplot2)
library(geomtextpath)
library(dplyr)
library(readr)
library(knitr)
library(kableExtra)
library(scales)
library(patchwork)

theme_set(theme_minimal(base_size = 11))

# Match Figure 8; its 11 pt labels render at 9.1 pt after LaTeX scaling.
curve_colours <- c(sigmoid = "#D7301F", concave = "#2C7FB8")
label_colours <- c(sigmoid = "#B70000", concave = "#0080C0")

df_results <- readRDS("results/nlopt_results.rds") %>%
  filter(static == "Dynamic case")
full_dose <- df_results %>%
  filter(key == "full_dose") %>%
  select(q, scenario, dose_name, full_dose_deaths = value)
df_obj_plot <- df_results %>%
  select(-result_solution) %>%
  left_join(full_dose, by = c("q", "scenario", "dose_name"),
            relationship = "many-to-one") %>%
  mutate(
    improvement_pp_no_vaccine_deaths = 100 * (full_dose_deaths - value) / no_vac,
    improvement_pct_full_dose_deaths = 100 * (1 - value / full_dose_deaths)
  )
stopifnot(!anyNA(df_obj_plot$full_dose_deaths))

plot_improvement <- function(y_var, plot_title, y_label) {
  df_obj_plot %>% 
    filter(key != "full_dose") %>%
    mutate(dose_name = factor(dose_name, levels = c("sigmoid", "concave"))) %>% 
    ggplot(aes(x = 1 / q,
               y = .data[[y_var]],
               color = dose_name,
               linetype = key)) +
    geom_line(linewidth = 1) + 
    scale_x_log10(
      breaks = c(0.01/100, 0.1/100, 1/100, 10/100),
      labels = c("0.01", "0.1", "1", "10"),
      name = "Vaccine supply\n(% population supplied per day, log scale)"
    ) +
    labs(title = plot_title, y = y_label) +
    geom_textpath(
      data = ~ filter(.x, key == "frac_age", dose_name == "concave") %>%
        arrange(1 / q), aes(x = 1 / q, y = .data[[y_var]], label = "Concave"),
      inherit.aes = FALSE,
      color = label_colours["concave"], family = "Helvetica",
      size = 9.1 / .pt, linetype = "blank", straight = TRUE,
      offset = unit(2, "pt"), hjust = .22
    ) +
    geom_textpath(
      data = ~ filter(.x, key == "frac_age", dose_name == "sigmoid") %>%
        arrange(1 / q), aes(x = 1 / q, y = .data[[y_var]], label = "Sigmoid"),
      inherit.aes = FALSE,
      color = label_colours["sigmoid"], family = "Helvetica",
      size = 9.1 / .pt, linetype = "blank", straight = TRUE,
      offset = unit(2, "pt"), hjust = .75
    ) +
    scale_color_manual(values = curve_colours) +
    scale_linetype_manual(values = c(frac_age = "dashed", frac_uniform = "solid")) +
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.margin = margin(5.5, 5.5, 5.5, 18)
    )
}


pp_no_vaccine_plot <- plot_improvement(
  y_var = "improvement_pp_no_vaccine_deaths",
  plot_title = "Relative to no-vaccine deaths: [D(1) - D(x*)] / D(0)",
  y_label = "Percentage points of\nno-vaccine deaths"
)
pct_full_dose_plot <- plot_improvement(
  y_var = "improvement_pct_full_dose_deaths",
  plot_title = "Relative to full-dose deaths: [D(1) - D(x*)] / D(1)",
  y_label = "Percent reduction in\nfull-dose deaths"
)

# Keep the manuscript figures on the full-dose denominator.
manuscript_plot <- plot_improvement(
  y_var = "improvement_pct_full_dose_deaths",
  plot_title = NULL,
  y_label = "Reduction in deaths\nrelative to full doses (%)"
)
ggsave(
  filename = "paper/figures/improvement.pdf",
  plot = manuscript_plot, width = 12, height = 8, units = "cm"
)

pp_name <- "paper/figures/improvement_pp_no_vaccine_deaths.pdf"
pct_name <- "paper/figures/improvement_pct_full_dose_deaths.pdf"
comparison_name <- "paper/figures/improvement_denominator_comparison.pdf"

ggsave(filename = pp_name, plot = pp_no_vaccine_plot,
       width = 12, height = 8, units = "cm")
ggsave(filename = pct_name, plot = pct_full_dose_plot,
       width = 12, height = 8, units = "cm")
ggsave(filename = comparison_name,
       plot = pp_no_vaccine_plot + pct_full_dose_plot,
       width = 26, height = 8, units = "cm")

dir.create("overleaf/figures", showWarnings = FALSE)
stopifnot(file.copy("paper/figures/improvement.pdf",
          "overleaf/figures", overwrite = TRUE))
