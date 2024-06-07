# run project setup first

load("results/results_all.Rdata")
results_all <- results_all %>% 
  mutate(recurring = map(recurring, pluck, 4), 
         recurring = ifelse(recurring == 1, "single-season", "multi-season"), 
         objective = ifelse(objective == "D", "%Death", "%Infection"),
         homogen_mixing = ifelse(homogen_mixing, "homogen-mixing", "hetero-mixing"), 
         pdeath = ifelse(pdeath == "ifr_hic", "high-income", "low-income"), 
         scenario = ifelse(scenario == "pars_le_slow", "slow-growth", "fast-growth"),
         full_dose = full_dose / no_vac * 100,
         frac_uni = frac_uni / no_vac * 100, 
         frac_age = frac_age / no_vac * 100)

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
