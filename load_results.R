# run project setup first

load("results/results_all.Rdata")
results_all <- results_all %>% 
  mutate(recurring = map(recurring, pluck, 4), 
         recurring = ifelse(recurring == 1, "single-season", "multi-season"), 
         objective = ifelse(objective == "D", "%Death", "%Infection"),
         homogen_mixing = ifelse(homogen_mixing, "homogen-mixing", "hetero-mixing"), 
         pdeath = ifelse(pdeath == "ifr_hic", "high-income", "low-income"), 
         scenario = ifelse(scenario == "pars_le_slow", "slow-growth (R0 = 1.1)", "fast-growth (R0 = 2)")
  ) %>% 
  # In static cases I use the "binary" permutations of age groups, in dynamic cases
  # I use optimisation with a single parameter. Hence ifelse(). See .tex for details.
  mutate(full_dose = full_dose / no_vac * 100,
         frac_uniform = ifelse(static, frac_01 / no_vac * 100, frac_uni / no_vac * 100),
         frac_age = frac_age / no_vac * 100) %>% 
  mutate(frac_uniform_sol = ifelse(static, frac_01_sol, frac_uni_sol)) %>% 
  select(-frac_uni, -frac_01, -frac_uni_sol, -frac_01_sol) %>% 
  filter(!(q %in% c(5,15)))

results_base_case <- results_all %>% 
  filter(
    # static == F, 
    # q %in% c(720, 360),
    # dose_response == "covid_default",
    pdeath == "high-income",
    objective == "%Death",
    homogen_mixing == "hetero-mixing",
    recurring == "single-season") %>% 
  mutate(vacc_daily = ifelse(static, NA, as.pct(1/q))) %>% 
  mutate(static = ifelse(static, "Static case", "Dynamic case")) 
  # mutate(scenario = paste(scenario, "epidemic")) 
