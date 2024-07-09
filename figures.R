source("project_setup.R")
source("load_results.R")
source("optimisation-epi/nlopt_plot.R")
library(patchwork)

# If you want to express as share of total volume distributed to different groups
pop_scaling <- function(x){ 
  x$solution <- pop[3:9]*(x$solution)
  x
}

# Fig 1 idea
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
plot_rcs(y, 
         compartment = c("S", "I", "cumI", "cumV"), 
         end_date = as.Date("01-06-2021", format="%d-%m-%Y")) +
  theme(legend.position = "bottom") + xlab("") + ylab("Fraction of total population")

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
plot_rcs(y, 
         compartment = c("P1", "N1", "D", "I"), 
         end_date = as.Date("01-06-2027", format="%d-%m-%Y")) +
  theme(legend.position = "bottom") + xlab("") + ylab("Fraction of total population")




# Optimal solutions, main case
df_optimal_solutions <- results_base_case %>% 
  mutate(q = as.factor(q)) %>% 
  unnest(frac_age_sol)

# library(ggrepel)
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
  theme_bw(base_size = 10) +
  theme(legend.position = "bottom",axis.text.x = element_text(angle = 45, hjust = 1),
        legend.spacing.y = unit(0, "cm"),
        legend.key.size = unit(0.7, "lines")) +
  geom_line(aes(y = hic, group = scenario), col = "black", linewidth = 1.1, lty = "dotted",
            data = mutate(df_risk_profile, scenario = "fast-growth (R0 = 2)"))+
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
  theme_bw(base_size = 10) +
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




# Objective function plot -----

# Another work in progress one
optim_names <- c("Age-optimal", "Age-invariant", "Binary choice", "No f.d.")
optim_values <- c("#E69F00", "#56B4E9", "#009E73", "black")
optim_lvls <- c("frac_age", "frac_uni", "frac_01", "full_dose")

df_obj_f <- results_base_case %>% 
  rowwise() %>% 
  ungroup() %>% 
  mutate(setting = q) %>% 
  select(setting, static, scenario, 
         full_dose, frac_uni, frac_age, frac_01,
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
  ggplot(aes(x = setting, 
             group = key, 
             color = key, y = value)) + 
  geom_line() +
  scale_color_manual(labels = optim_names,
                     values = optim_values) +
  theme(legend.position = "none", 
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_grid(.~scenario, scales = "free") +
  labs(#x = "Speed/supply constraint", 
    x = "",
    y = "Proportion of deaths averted") +
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
  labs(x = "Speed/supply constraint", 
       y = "Improvement relative to full dose") +
  ggtitle("Mortality reductions relative to full dose, static case")

gg_objd1 <- df_obj_dynamic %>% 
  ggplot(aes(x = setting, 
             group = key, 
             color = key, y = value)) + 
  geom_line() +
  scale_color_manual(labels = optim_names,
                     values = optim_values) +
  theme(legend.position = "none", 
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_grid(.~scenario, scales = "free") +
  labs(#x = "Speed/supply constraint", 
    x = "",
    y = "Proportion of deaths averted") +
  ggtitle("Mortality reductions relative to no vaccination, dynamic case")

gg_objd2 <- df_obj_dynamic %>% 
  ggplot(aes(x = setting, 
             group = key, 
             color = key, y = value_prop)) + 
  geom_line() +
  scale_color_manual(labels = optim_names,
                     values = optim_values) +
  theme(legend.position = "none", 
        axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_grid(.~scenario, scales = "free") +
  labs(x = "Speed/supply constraint", 
       y = "Improvement relative to full dose")





# gg_objs1 / gg_objs2 + 
#   plot_layout(guides = "collect", nrow = 2) & 
#   theme(legend.position = "bottom",
#         legend.title = element_blank())
# 


gg_objs1 / gg_objd1 / gg_objs2 + 
  # plot_layout(guides = "collect", nrow = 3) & 
  theme(legend.title = element_blank())

ggsave("paper/figures/obj_f_solutions.pdf", width = 14, height = 21, unit = "cm")



# Objective function table -----


library(knitr)
library(kableExtra)

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
#   # filter(key == "Age-optimal") %>% 
#   # filter(key == "Age-optimal") %>% 
#   filter(scenario == "fast-growth epidemic") %>%
#   filter(setting %in% c(0.05, 0.1, 0.2, 0.3, 0.4, 0.5)) %>%
#   mutate(scenario = paste("q =", setting)) %>% 
#   mutate(value = round(value, 2)) %>%
#   select(scenario, key, value) %>% spread(scenario, value)
# # knitr::kable(format = "latex")


