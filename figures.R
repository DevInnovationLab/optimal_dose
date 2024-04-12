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
         end_date = as.Date("01-06-2021", format="%d-%m-%Y"))


# Optimal solutions, main case

# Express as share of total volume distributed to different groups
pop_scaling <- function(x){ 
  x$solution <- pop[3:9]*(x$solution)
  x
}

results_all %>% 
  filter(objective == "%Death", 
         # pdeath == "high-income",
         homogen_mixing == "hetero-mixing",
         # static == TRUE,
         recurring == "single-season") %>% 
  mutate(q = as.factor(q)) %>% 
  mutate(frac_age_sol = map(frac_age_sol, pop_scaling)) %>% 
  unnest(frac_age_sol) %>% 
  ggplot(aes(x = age_group, y = solution)) + 
  facet_grid(static ~ scenario) + 
  # facet_wrap(vars(scenario)) + 
  geom_point(aes(color = q)) + 
  geom_line(aes(group = interaction(q, pdeath), 
                color = q,
                linetype = pdeath)) + 
  labs(x = "Age Group", y = "Optimal Dose Fraction") + 
  ylim(0, 1) + 
  theme_bw() + 
  theme(legend.position = "bottom") 
# + 
  # scale_color_manual(values = c("#D55E00", "#0072B2", "#009E73", "#882E72"))





model_fd_static(scenario = "pars_le_fast",
                fd = rep(1,9), 
                ret = 1,
                rep = c(0.8,0.2,0.5,1))

