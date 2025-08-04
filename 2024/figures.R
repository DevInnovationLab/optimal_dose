# Script used to prepare figures and tables for the calibration section of the paper
# Author: WW
# July 2024

# Prep -------------------------------------------------------------------------

source("project_setup.R")
source("load_results.R")
source("optimisation-epi/nlopt_plot.R")
library(patchwork)
library(knitr)
library(kableExtra)

# Basic plotting setting
theme_set(theme_minimal(base_size = 11))

# Helper objects ---------------------------------------------------------------

# IFRs data frame
df_risk_profile <- data.frame(
  # extract labels:
  age_group = results_bc_hic$frac_age_sol %>% 
    bind_rows %>% 
    pull(age_group) %>% 
    unique,
  pop_hic = hic_pop[3:9],
  pop_lic = lic_pop[3:9],
  ifr_hic = ifr_hic[3:9],
  ifr_lic = ifr_lic[3:9]
) 





# Dose-response and heterogeneous risk functions -------------------------------

x <- seq(0, 1, length = 1000)
phi <- phi_covid(x)
plot(phi ~ x, type = "l", ylab = "phi(x)", 
     xlab = "x", main = "Dose-response", ylim = c(0,1))


# Figure 1: model demonstration ------------------------------------------------

speed_x <- c(10, 33, 100, 365, 1000)
y <- lapply(speed_x, function(speed)
  model_fd_dynamic(
    "pars_le_fast", 
    length_campaign = speed, 
    fd = rep(0.5, Ngroups),
    phi_x = "covid_default",
    pdeath = "ifr_hic",
    rm = T,
    ret = 1,
    objective = "D",
    homogen = FALSE,
    immunity_length = 365)
) %>% do.call(abind::abind, .)
dimnames(y)[[3]] <- paste(speed_x, "days")
ln2 <- ln
ln2[["cumV"]] <- "Vaccinated"
plot_rcs(y, 
         long_names = ln2,
         compartment = c("S", "I", "cumI", "cumV"), 
         end_date = as.Date("01-06-2021", format="%d-%m-%Y")) +
  theme(legend.position = "bottom") + xlab("") + 
  ylab("Fraction of total population")

ggsave("paper/figures/example_model.pdf", width = 14, height = 10, unit = "cm")

# Long-term simulation ("recurring")
# speed_x <- c(10, 33, 100, 365, 1000)
speed_x <- c(10, 1000)
y <- lapply(speed_x, function(speed)
  model_fd_dynamic(
    "pars_le_fast", 
    length_campaign = speed, 
    fd = rep(0.5, Ngroups),
    phi_x = "covid_default",
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





# Optimal solutions, main case -------------------------------------------------

df_optimal_solutions <- results_bc_hic %>% 
  mutate(q = as.factor(q)) %>% 
  unnest(frac_age_sol)

age_solutions_static <- df_optimal_solutions %>% 
  # mutate(label = if_else(age_group == "80+", 
  #                        as.character(q), 
  #                        NA_character_)) %>%
  filter(static == "Static case") %>% 
  ggplot(aes(x = age_group, y = solution)) + 
  facet_grid(. ~ scenario) + 
  # facet_wrap(vars(scenario)) + 
  geom_point(aes(color = q)) + 
  geom_line(aes(
    # group = interaction(q, pdeath), 
    # linetype = pdeath,
    group = q,
    color = q
  )) + 
  # geom_label_repel(aes(label = label),
  #                  nudge_x = 1,
  #                  na.rm = TRUE) +
  scale_color_discrete(name = "supply \n(fraction of \npopulation)") +
  labs(x = "Age Group", y = "Optimal Dose Fraction") + 
  ylim(0, 1) + 
  # theme_bw(base_size = 10) +
  theme(legend.position = "bottom",axis.text.x = element_text(angle = 45, hjust = 1),
        legend.spacing.y = unit(0, "cm"),
        legend.key.size = unit(0.7, "lines")) +
  geom_line(aes(y = ifr_hic, group = scenario), 
            col = "black", linewidth = 1.1, lty = "dotted",
            data = mutate(df_risk_profile, 
                          scenario = "fast-growth (R0 = 2)"))+
  ggtitle("Optimal dose: static case") +
  theme(axis.title.x = element_blank())

age_solutions_dynamic <- df_optimal_solutions %>% 
  filter(static != "Static case") %>% 
  # filter(static != "Static case", scenario != "slow-growth epidemic") %>% 
  filter(frac_vac > .04) %>%
  # mutate(frac_vac = ifelse(scenario == "slow-growth epidemic", 1, frac_vac)) %>% 
  # ggplot(aes(x = age_group, y = solution, alpha = frac_vac)) + 
  ggplot(aes(x = age_group, y = solution)) + 
  facet_grid(. ~ scenario) + 
  geom_point(aes(color = q)) + 
  geom_line(aes(
    group = q,
    color = q
  )) + 
  scale_color_discrete(name = "length of \n campaign (days)") +
  labs(x = "Age Group", y = "Optimal Dose Fraction") + 
  ylim(0, 1) + 
  # theme_bw(base_size = 10) +
  theme(
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1),
    # legend.key.size = unit(0.7, "lines"),
    legend.spacing.y = unit(0, "cm"),
    legend.key.size = unit(0.7, "lines")
    # legend.title = element_text(hjust = 0.5) 
  ) +
  ggtitle("Optimal dose: dynamic case")

# ggsave("paper/figures/age_solutions_static.pdf", 
# width = 14, height = 10, unit = "cm")
# ggsave("paper/figures/age_solutions_dynamic.pdf",
# width = 14, height = 10, unit = "cm")

age_solutions_static  / age_solutions_dynamic
ggsave("paper/figures/age_solutions_both.pdf",
       width = 14, height = 20, unit = "cm")

# model_fd_static(scenario = "pars_le_fast",
#                 fd = rep(1,9), 
#                 ret = 1,
#                 rep = c(0.8,0.2,0.5,1))






# Objective function values, comparison plots ----------------------------------

# Another work in progress one
optim_names <- c("Age-specific", "Age-invariant", "Full dose")
optim_values <- c("#E69F00", "#56B4E9", "black")
optim_lvls <- c("frac_age", "frac_uniform", "full_dose")

df_obj_f <- results_bc_hic %>% 
  rowwise() %>% 
  ungroup() %>% 
  mutate(setting = q) %>% 
  select(setting, static, scenario, 
         full_dose, frac_uniform, frac_age, 
         pdeath) %>% 
  gather(key, value, -setting, -static, -scenario, -pdeath) %>% 
  group_by(setting, scenario, static) %>% 
  mutate(value = ifelse(key == "full_dose", max(value), value)) %>% 
  mutate(value_prop = value/max(value)) %>%
  # mutate(value_prop = value) %>%
  ungroup %>%
  mutate(key = factor(key, levels = optim_lvls, 
                      labels = optim_names)) 
# mutate(value = 1 - value/100)

df_obj_f_static <- df_obj_f %>% 
  filter(static == "Static case")
df_obj_f_dynamic <- df_obj_f %>% 
  filter(static == "Dynamic case")
  
gg_objs1 <- df_obj_f_static %>% 
  mutate(value=value/100) %>% 
  ggplot(aes(x = setting, 
             group = key, 
             color = key, y = value)) + 
  geom_line() +
  scale_color_manual(labels = optim_names,
                     values = optim_values) +
  theme(legend.position = "none", 
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_grid(.~scenario, scales = "free") +
  ylim(0,1)+
  labs(x = "supply constraint", 
    x = "",
    y = "deaths vs no vaccine") +
  ggtitle("Mortality reductions relative to no vaccination, static case")

gg_objs2 <- df_obj_f_static %>% 
  ggplot(aes(x = setting, 
             group = key, 
             color = key, y = value_prop)) + 
  geom_line() +
  scale_color_manual(labels = optim_names,
                     values = optim_values) +
  theme(legend.position = "bottom", 
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_grid(.~scenario, scales = "free") +
  labs(x = "supply constraint", 
       y = "deaths vs full dose") +
  ggtitle("Mortality reductions relative to full dose, static case")

gg_objd1 <- df_obj_f_dynamic %>% 
  mutate(value=value/100) %>% 
  ggplot(aes(x = setting, 
             group = key, 
             color = key, y = value)) + 
  geom_line() +
  scale_color_manual(labels = optim_names,
                     values = optim_values) +
  theme(legend.position = "none", 
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_grid(.~scenario, scales = "free") +
  ylim(0, 1) +
  labs(
    # x = "length of vaccination campaign (days)", 
    x = "",
    y = "deaths vs no vaccine") +
  ggtitle("Mortality reductions relative to no vaccination, dynamic case")

gg_objd2 <- df_obj_f_dynamic %>% 
  ggplot(aes(x = setting, 
             group = key, 
             color = key, y = value_prop)) + 
  geom_line() +
  scale_color_manual(labels = optim_names,
                     values = optim_values) +
  theme(legend.position = "none", 
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_grid(.~scenario, scales = "free") +
  labs(x = "length of vaccination campaign (days)", 
       y = "deaths vs full dose") +
  ggtitle("Mortality reductions relative to full dose, dynamic case")





# gg_objs1 / gg_objs2 + 
#   plot_layout(guides = "collect", nrow = 2) & 
#   theme(legend.position = "bottom",
#         legend.title = element_blank())
# 


gg_objs1 / gg_objd1 / gg_objs2 + 
  # plot_layout(guides = "collect", nrow = 3) & 
  theme(legend.title = element_blank())

ggsave("paper/figures/obj_f_solutions.pdf", width = 14, height = 21, unit = "cm")




# Objective function table -----------------------------------------------------

df_obj_tbl <- df_obj_f %>% 
  # filter(key != "Binary choice") %>% 
  filter(static == "Static case") %>% 
  filter(setting %in% c(0.05, 0.1, 0.2, 180, 360, 720)) %>% 
  # mutate(q = paste(static, "q =", setting)) %>% 
  # mutate(q = setting) %>% 
  mutate(q = paste("Supply =", setting)) %>%
  mutate(value = round(value/100, 2)) %>% 
  select(scenario, static, q, key, value) %>% 
  spread(key, value) 
  # knitr::kable(format = "latex")

latex_table <- df_obj_tbl %>% 
  select(-scenario, -static) %>% 
  knitr::kable(format = "latex", booktabs = TRUE) %>% 
  pack_rows("Fast-growing epidemic, R0 = 2", 1, 3) %>% 
  pack_rows("Slow-growing epidemic, R0 = 1.1", 4, 6)

writeLines(latex_table, "paper/table.tex")

# df_obj_f %>% 
#   # filter(key == "Age-specific") %>% 
#   # filter(key == "Age-specific") %>% 
#   filter(scenario == "fast-growth epidemic") %>%
#   filter(setting %in% c(0.05, 0.1, 0.2, 0.3, 0.4, 0.5)) %>%
#   mutate(scenario = paste("q =", setting)) %>% 
#   mutate(value = round(value, 2)) %>%
#   select(scenario, key, value) %>% spread(scenario, value)
# # knitr::kable(format = "latex")



# LIC vs HIC comparison --------------------------------------------------------

gg_risk <- df_risk_profile %>% 
  select(age_group, ifr_hic, ifr_lic) %>% 
  gather(var, val, -age_group) %>% 
  mutate(var = factor(var, levels = c("ifr_hic", "ifr_lic"), c("HIC", "LIC"))) %>% 
  ggplot(aes(x=age_group, y = val, group = var, lty = var)) +
  geom_line() + geom_point() + ylim(0, .1) + 
  ylab("IFR (log scale)") + xlab("") +
  theme_minimal(base_size = 9) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1), 
        legend.position = "bottom",
        legend.title = element_blank()) +
  scale_y_log10(
    breaks = c(0.001, 0.01, 0.1),
    labels = c("0.1%", "1%", "10%")
  )
  # scale_y_continuous(labels = scales::percent)

gg_lic_vs_hic <- results_base_case %>% 
  filter(static == "Static case",
         scenario == "fast-growth (R0 = 2)") %>% 
  mutate(q = as.factor(q)) %>% 
  unnest(frac_age_sol) %>% 
  ggplot(aes(x = age_group, y = solution)) + 
  facet_grid(. ~ pdeath) + 
  geom_point(aes(color = q)) + 
  geom_line(aes(
    group = q,
    color = q
  )) + 
  scale_color_discrete(name = "supply \n(fraction of \npopulation)") +
  labs(x = "Age Group", y = "Optimal Dose Fraction") + 
  ylim(0, 1) + 
  theme_minimal(base_size = 9) +
  theme(legend.position = "bottom",
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.spacing.y = unit(0, "cm"),
        legend.key.size = unit(0.7, "lines")) +
  theme(axis.title.x = element_blank())

gg_lic_vs_hic + gg_risk + 
  plot_layout(widths = c(2.2, 1))
  
ggsave("paper/figures/age_solutions_lic_hic.pdf", width = 14, height = 9, unit = "cm")
