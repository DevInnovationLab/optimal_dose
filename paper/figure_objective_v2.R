# Plot reductions in deaths relative to full-dose and no-vaccine deaths.
# Save the manuscript figures and comparisons of the two denominators.

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
  mutate(
    improvement_pp_no_vaccine_deaths = 100 * (full_dose_deaths - value) / no_vac,
    improvement_pct_full_dose_deaths = 100 * (1 - value / full_dose_deaths)
  )
stopifnot(!anyNA(df_obj_plot$full_dose_deaths))

plot_improvement <- function(fast_growth, y_var, plot_title, y_label,
                             concave_y, sigmoid_y) {
  df_obj_plot %>% 
    filter((scenario == "fast-growth (R0 = 2)") == fast_growth) %>% 
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
    annotate("text", x = 0.0005, y = concave_y, label = "Concave", color = "blue", hjust = 0) +
    annotate("text", x = 0.02, y = sigmoid_y, label = "Sigmoid", color = "red", hjust = 0) +
    scale_color_manual(values = c(sigmoid = "red", concave = "blue")) +
    scale_linetype_manual(values = c(frac_age = "dashed", frac_uniform = "solid")) +
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.margin = margin(5.5, 5.5, 5.5, 18)
    )
}

for (filt in c(TRUE, FALSE)) {
  pp_no_vaccine_plot <- plot_improvement(
    fast_growth = filt,
    y_var = "improvement_pp_no_vaccine_deaths",
    plot_title = "Relative to no-vaccine deaths: [D(1) - D(x*)] / D(0)",
    y_label = "Percentage points of\nno-vaccine deaths",
    concave_y = ifelse(filt, 25, 30),
    sigmoid_y = 12
  )
  pct_full_dose_plot <- plot_improvement(
    fast_growth = filt,
    y_var = "improvement_pct_full_dose_deaths",
    plot_title = "Relative to full-dose deaths: [D(1) - D(x*)] / D(1)",
    y_label = "Percent reduction in\nfull-dose deaths",
    concave_y = ifelse(filt, 35, 45),
    sigmoid_y = 18
  )

  # Keep the manuscript figures on the full-dose denominator.
  manuscript_plot <- plot_improvement(
    fast_growth = filt,
    y_var = "improvement_pct_full_dose_deaths",
    plot_title = NULL,
    y_label = "Reduction in deaths\nrelative to full doses (%)",
    concave_y = ifelse(filt, 25, 30), sigmoid_y = 12
  )
  ggsave(
    filename = if (filt) "paper/figures/improvement.pdf" else
      "paper/figures/improvement_slow.pdf",
    plot = manuscript_plot, width = 12, height = 8, units = "cm"
  )

  if (filt) {
    pp_name <- "paper/figures/improvement_pp_no_vaccine_deaths.pdf"
    pct_name <- "paper/figures/improvement_pct_full_dose_deaths.pdf"
    comparison_name <- "paper/figures/improvement_denominator_comparison.pdf"
  } else {
    pp_name <- "paper/figures/improvement_slow_pp_no_vaccine_deaths.pdf"
    pct_name <- "paper/figures/improvement_slow_pct_full_dose_deaths.pdf"
    comparison_name <- "paper/figures/improvement_slow_denominator_comparison.pdf"
  }

  ggsave(filename = pp_name, plot = pp_no_vaccine_plot,
         width = 12, height = 8, units = "cm")
  ggsave(filename = pct_name, plot = pct_full_dose_plot,
         width = 12, height = 8, units = "cm")
  ggsave(filename = comparison_name,
         plot = pp_no_vaccine_plot + pct_full_dose_plot,
         width = 26, height = 8, units = "cm")
}

dir.create("overleaf/figures", showWarnings = FALSE)
stopifnot(file.copy(c("paper/figures/improvement.pdf",
            "paper/figures/improvement_slow.pdf"),
          "overleaf/figures", overwrite = TRUE))
