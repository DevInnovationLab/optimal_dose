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

y <- lapply(speed_x, function(speed)
  model_fd_dynamic(
    "pars_le_fast", 
    length_campaign = speed, 
    fd = rep(0.5, Ngroups),
    phi_x = phi_covid,
    pdeath = "ifr_hic",
    rm = T,
    ret = 1,
    objective = "D",
    homogen = FALSE,
    immunity_length = 365)
) %>% do.call(abind::abind, .)
# dimnames(y)[[3]] <- paste(q_per_day, " each day")
ln2 <- ln; ln2[["cumV"]] <- "Vaccinated"
plot_example <- plot_rcs(y, 
                         ncol = 3,
                         long_names = ln2,
                         compartment = c("S", "I", "cumV"), 
                         start_date = NULL) +
  # end_date = as.Date("01-09-2021", format="%d-%m-%Y")) +
  theme(legend.position = "bottom")


plot_example + 
  scale_x_continuous(breaks = seq(30.5, 9*30.5, 2*30.5), labels = c(1,3,5,7,9)) +
  xlab("Month") + 
  ylab("Proportion of total population") +
  scale_color_manual(
    name = "Vaccinated each day (% total population)",
    # values = c("4" = "#E31A1C", "3" = "#FF7F00", "2" = "#1F78B4", "1" = "#33A02C"),
    values = c("3" = "#FF7F00", "2" = "#1F78B4", "1" = "#33A02C"),
    # labels = c("1" = "3%", "2" = "1%", "3" = "0.5%", "4" = "0.2%")
    labels = c("1" = "10%", "2" = "1%", "3" = "0.1%")
  )

ggsave("paper/figures/example_model.pdf", width = 16.5, height = 7.5, unit = "cm")

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
