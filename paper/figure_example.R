source("project_setup.R")

library(ggplot2)
library(knitr)
library(kableExtra)
library(scales)
library(patchwork)

theme_set(theme_minimal(base_size = 11))


# Visualise an example model ------

# speed_x <- c(10, 33, 100, 365, 1000)

# q_per_day <- c(3, 1, 0.5, 0.2)
q_per_day <- c(10, 1, 0.1)
speed_x <- 100/q_per_day
q_ids <- c("q10", "q1", "q0_1")
q_labels <- c("10%", "1%", "0.1%")
q_colours <- c("q10" = "#D55E00", "q1" = "#0072B2", "q0_1" = "#009E73")

ln2 <- ln; ln2[["cumV"]] <- "Vaccinated"

plot_example_model <- function(scenario) {
  y <- lapply(speed_x, function(speed)
    model_fd_dynamic(
      scenario,
      length_campaign = speed,
      fd = rep(0.5, Ngroups),
      phi_x = phi_covid,
      pdeath = "ifr_hic",
      rm = TRUE,
      ret = 1,
      objective = "D",
      homogen = FALSE,
      immunity_length = 365)
  ) %>% do.call(abind::abind, .)
  dimnames(y)[[3]] <- q_ids
  example_plot <- plot_rcs(y,
                           ncol = 3,
                           long_names = ln2,
                           compartment = c("S", "I", "cumV"),
                           start_date = NULL)
  example_plot$layers[[1]]$aes_params$linewidth <- 0.7
  example_plot +
    # end_date = as.Date("01-09-2021", format="%d-%m-%Y")) +
    theme(legend.position = "bottom") +
    scale_x_continuous(breaks = c(0, 5, 10) * 30.5,
                       labels = c(0, 5, 10)) +
    xlab("Month") +
    ylab("Proportion of total population") +
    scale_color_manual(
      name = "Vaccine supply\n(% population supplied per day)",
      values = q_colours,
      breaks = q_ids,
      labels = q_labels
    ) +
    guides(color = guide_legend(nrow = 1))
}

ggsave("paper/figures/example_model.pdf", plot = plot_example_model("pars_le_fast"),
       width = 16.5, height = 7.5, unit = "cm")
ggsave("paper/figures/example_model_slow.pdf", plot = plot_example_model("pars_le_slow"),
       width = 16.5, height = 7.5, unit = "cm")

# Long-term simulation ("recurring")
# speed_x <- c(10, 33, 100, 365, 1000)
speed_x <- c(10, 1000)
y <- lapply(speed_x, function(speed)
  model_fd_dynamic(
    "pars_le_fast", 
    length_campaign = speed, 
    fd = rep(0.5, Ngroups),
    phi_x = phi_covid,
    pdeath = "ifr_hic",
    rm = T,
    ret = 1,
    rep = c(0.8, 0.8, 0.8, 5),
    objective = "D",
    homogen = FALSE,
    immunity_length = 365)
) %>% do.call(abind::abind, .)
dimnames(y)[[3]] <- paste(speed_x, "days")
# explicitly sum susceptible without vaccines and those in whom vaccine didn't work:
y[, "S", 1] <- y[, "S", 1] + y[, "N1", 1]
y[, "S", 2] <- y[, "S", 2] + y[, "N1", 2]
plot_rcs(y, ncol = 3,
         compartment = c("S", "D", "I"), 
         end_date = as.Date("01-06-2024", format="%d-%m-%Y")) +
  theme(legend.position = "bottom",
        legend.box.spacing = unit(0, "cm")) + 
  xlab("") + ylab("Fraction of total population")

ggsave("paper/figures/example_multiseason.pdf", width = 14, height = 6, unit = "cm")
