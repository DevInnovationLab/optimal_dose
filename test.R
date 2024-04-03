plot_rcs(model_fd_dynamic("pars_le_fast", 
                          length_campaign = 90, 
                          fd = c(1, 1, 0.9892046, 0.9905274, 0.9722408, 0.9786102, 0.9861875, 0.9909890, 0.9924568), 
                          phi_x = "covid_default",
                          pdeath = "ifr_hic",
                          rm = T,
                          ret = 0,
                          objective = "D",
                          homogen = FALSE,
                          immunity_length = 365,
                          rep = c(0.8,0.2,0.5,5)),
         compartment = "cumI")


results_all %>% 
  filter(q == 90, objective == "%Death", scenario == "fast-growth", 
         pdeath == "high-income", homogen_mixing == "hetero-mixing", 
         recurring == "multi-season") %>% 
  unnest(frac_age_sol) %>% 
  pull(solution)


opt_general(0.3, 
              0.01, 
              "D", 
              "covid_default",
              T, 
              T, 
              "ifr_hic", 
              "pars_le_slow", 
              c(0.8,0.2,0.5,1), 
              100)
    
    

    
    
    