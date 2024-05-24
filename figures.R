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
# Express as share of total volume distributed to different groups
pop_scaling <- function(x){ 
  x$solution <- pop[3:9]*(x$solution)
  x
}

results_base_case <- results_all %>% 
  filter(
    # static == F, 
    # q %in% c(720, 360),
    # dose_response == "covid_default",
    pdeath == "high-income",
    objective == "%Death",
    homogen_mixing == "hetero-mixing",
    recurring == "single-season") %>% 
  mutate(static = ifelse(static, "Static case", "Dynamic case")) %>% 
  mutate(scenario = paste(scenario, "epidemic"))

results_base_case %>% 
  filter(objective == "%Death", 
         pdeath == "high-income",
         homogen_mixing == "hetero-mixing",
         # static == TRUE,
         recurring == "single-season") %>% 
  mutate(q = as.factor(q)) %>% 
  # mutate(frac_age_sol = map(frac_age_sol, pop_scaling)) %>% 
  unnest(frac_age_sol) %>% 
  ggplot(aes(x = age_group, y = solution)) + 
  facet_grid(scenario ~ static) + 
  # facet_wrap(vars(scenario)) + 
  geom_point(aes(color = q)) + 
  geom_line(aes(
    # group = interaction(q, pdeath), 
    # linetype = pdeath,
    group = q,
    color = q
    )) + 
  scale_color_discrete(name = "supply/speed q =") +
  labs(x = "Age Group", y = "Optimal Dose Fraction") + 
  ylim(0, 1) + 
  theme_bw(base_size = 10) +
  theme(legend.position = "bottom",axis.text.x = element_text(angle = 45, hjust = 1))
ggsave("paper/figures/age_solutions.pdf", width = 12, height = 14, unit = "cm")

# model_fd_static(scenario = "pars_le_fast",
#                 fd = rep(1,9), 
#                 ret = 1,
#                 rep = c(0.8,0.2,0.5,1))



# Another work in progress one

results_base_case %>% 
  rowwise() %>% 
  mutate(setting = paste("q =", q)) %>% 
  ungroup() %>% 
  mutate(setting = factor(setting, levels = paste("q =", sort(unique(q))))) %>% 
  select(setting, static, scenario, full_dose, frac_uni, frac_age, pdeath) %>% 
  gather(key, value, -setting, -static, -scenario, -pdeath) %>% 
  group_by(setting, scenario, static) %>% mutate(value = value/max(value)) %>% ungroup %>%
  mutate(key = factor(key, levels = c("frac_age", "frac_uni", "full_dose"), 
                      labels = c("Age-optimal", "Age-invariant", "No f.d."))) %>% 
  mutate(value = value/100) %>% 
  ggplot(aes(x = setting, 
             # , linetype = pdeath,
             # group = interaction(key,pdeath), 
             group = key, 
             color = key, y = value)) + 
  geom_line() +
  # coord_flip() +
  scale_color_manual(labels = c("Age-optimal", "Age-invariant", "No f.d."),
  values = c("#E69F00", "#56B4E9", "#009E73")) +
  theme(legend.position = "bottom") +
  facet_grid(scenario~static, scales = "free") +
labs(x = "Speed/supply constraint", y = "Deaths relative to no vaccination")
ggsave("paper/figures/obj_f_solutions.pdf", width = 12, height = 9, unit = "cm")

