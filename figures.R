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

ggsave("paper/figures/example_model.pdf", width = 12, height = 10, unit = "cm")

# Optimal solutions, main case
df_optimal_solutions <- results_base_case %>% 
  filter(objective == "%Death", 
         pdeath == "high-income",
         homogen_mixing == "hetero-mixing",
         # static == TRUE,
         recurring == "single-season") %>% 
  # mutate(q = q/sum(pop[3:9])) %>% 
  mutate(q = as.factor(q)) %>% 
  # mutate(frac_age_sol = map(frac_age_sol, pop_scaling)) %>% 
  unnest(frac_age_sol)

# library(ggrepel)
df_optimal_solutions %>% 
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
  scale_color_discrete(name = "supply (fraction of population)") +
  labs(x = "Age Group", y = "Optimal Dose Fraction") + 
  ylim(0, 1) + 
  theme_bw(base_size = 10) +
  theme(legend.position = "bottom",axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("paper/figures/age_solutions_static.pdf", width = 12, height = 8, unit = "cm")


df_optimal_solutions %>% 
  filter(static != "Static case", scenario != "slow-growth epidemic") %>% 
  filter(frac_vac > .2) %>%
  # mutate(frac_vac = ifelse(scenario == "slow-growth epidemic", 1, frac_vac)) %>% 
  # ggplot(aes(x = age_group, y = solution, alpha = frac_vac)) + 
  ggplot(aes(x = age_group, y = solution)) + 
  facet_grid(. ~ scenario) + 
  geom_point(aes(color = q)) + 
  geom_line(aes(
    group = q,
    color = q
  )) + 
  scale_color_discrete(name = "length of vaccination campaign (days)") +
  labs(x = "Age Group", y = "Optimal Dose Fraction") + 
  ylim(0, 1) + 
  theme_bw(base_size = 10) +
  theme(legend.position = "bottom",axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("paper/figures/age_solutions_dynamic.pdf", width = 12, height = 8, unit = "cm")


# model_fd_static(scenario = "pars_le_fast",
#                 fd = rep(1,9), 
#                 ret = 1,
#                 rep = c(0.8,0.2,0.5,1))



# Another work in progress one

df_obj_f <- results_base_case %>% 
  rowwise() %>% 
  # mutate(setting = paste("q =", q)) %>%
  # mutate(setting = as.character(q)) %>%
  # filter(scenario == "fast-growth epidemic") %>% 
  filter(static == "Static case") %>% 
  ungroup() %>% 
  # mutate(setting = factor(setting, levels = paste("q =", sort(unique(q))))) %>% 
  # mutate(setting = factor(q, levels = sort(unique(q)))) %>% 
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
  mutate(key = factor(key, levels = c("frac_age", "frac_uni", "frac_01", "full_dose"), 
                      labels = c("Age-optimal", "Age-invariant", "On or off", "No f.d.")))
  # mutate(value = 1 - value/100)

gg_obj1 <- df_obj_f %>% 
  ggplot(aes(x = setting, 
             group = key, 
             color = key, y = value)) + 
  geom_line() +
  scale_color_manual(labels = c("Age-optimal", "Age-invariant", "On or off", "No f.d."),
                     values = c("#E69F00", "#56B4E9", "#009E73", "black")) +
  theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_grid(.~scenario, scales = "free") +
  labs(#x = "Speed/supply constraint", 
    x = "",
    y = "Proportion of deaths averted")

gg_obj2 <- df_obj_f %>% 
  ggplot(aes(x = setting, 
             group = key, 
             color = key, y = value_prop)) + 
  geom_line() +
  scale_color_manual(labels = c("Age-optimal", "Age-invariant", "On or off", "No f.d."),
                     values = c("#E69F00", "#56B4E9", "#009E73", "black")) +
  theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1)) +
  facet_grid(.~scenario, scales = "free") +
  labs(x = "Speed/supply constraint", 
       y = "Improvement relative to full dose")

gg_obj1 / gg_obj2 

ggsave("paper/figures/obj_f_solutions.pdf", width = 14, height = 9, unit = "cm")

library(knitr)
library(kableExtra)

df_obj_f %>% 
  filter(setting %in% c(0.05, 0.1, 0.2, 180, 360, 720)) %>% 
  mutate(scenario = paste(static, "q =", setting)) %>% 
  mutate(value = round(value, 2)) %>% 
  select(scenario, key, value) %>% spread(scenario, value)  %>% 
  knitr::kable(format = "latex")

df_obj_f %>% 
  # filter(key == "Age-optimal") %>% 
  # filter(key == "Age-optimal") %>% 
  filter(scenario == "fast-growth epidemic") %>%
  filter(setting %in% c(0.05, 0.1, 0.2, 0.3, 0.4, 0.5)) %>%
  mutate(scenario = paste("q =", setting)) %>% 
  mutate(value = round(value, 2)) %>%
  select(scenario, key, value) %>% spread(scenario, value)
  # knitr::kable(format = "latex")
