
dr_df <- tibble::enframe(dr_foos, name = "dose_name", value = "dose_response")

# Generate all combinations of options. Since q is defined differently for 
# dynamic and static problems, we generate the grids separately and rbind later. 
cases_dynamic <- expand_grid(q_per_day = c(5, 3, 2, 1.5, 1, 0.75, 0.5, 0.4, 0.3, 0.2, 0.1, 0.05, 0.01)/100, 
                             # q = c(7, 28, 45, 90, 120, 150, 180, 270, 360, 720, 1440), 
                             objective = c("D"), 
                             homogen_mixing = F,
                             static = F,
                             pdeath = c("ifr_hic"), 
                             scenario = c("pars_le_slow", "pars_le_fast"),
                             recurring = list(c(0.8,0.2,0.5,1)),
                             iterations = 1000) %>% 
  mutate(q = 1/q_per_day) %>% 
  # Initial value set as random uniform draw
  mutate(initial_value = runif(nrow(.), 0.1, 0.9)) %>% 
  relocate(initial_value, .after = q) %>% 
  # Now also expand across functions of interest
  tidyr::crossing(dr_df) 

# For the 2025 version of the paper we don't use the static optimisation
# which is wonky! (e.g. opt_general cannot vaccinate part of a given age group)
# at very low q it also breaks down in some ways, I think because of the above
cases_static <- expand_grid(q = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1),
                            objective = c("D"),
                            homogen_mixing = F,
                            static = T,
                            pdeath = c("ifr_hic"),
                            scenario = c("pars_le_slow", "pars_le_fast"),
                            recurring = list(c(0.8,0.2,0.5,1)),
                            iterations = 1000) %>%
  mutate(initial_value = q / 7) %>% # Initial value set as 1/7 of total vaccine supply
  relocate(initial_value, .after = q) %>% 
  tidyr::crossing(dr_df) %>% 
  mutate(q_per_day = NA)

cases_df <- rbind(cases_dynamic, cases_static)
# cases_df <- cases_dynamic


# Run optimisations (a few mins)

results_novac <- cases_df %>% 
  select(-dose_name) %>% 
  select(objective, homogen_mixing, pdeath, scenario, recurring) %>% 
  distinct() %>% 
  mutate(no_vac = pmap_dbl(., obj_no_vac_v2))

results_full_dose <- cases_df %>%
  select(-initial_value, -iterations, -dose_name, -q_per_day) %>% 
  mutate(result = pmap(., obj_full)) %>% 
  unnest_wider(result, names_sep = "_") %>%
  bind_cols(cases_df %>% select(dose_name, q_per_day))

results_frac_uniform_dynamic <- cases_dynamic %>% 
  select(-dose_name, -q_per_day) %>% 
  mutate(result = pmap(., opt_general, n_x = 1, unroll_x = unroll_1)) %>%
  unnest_wider(result, names_sep = "_") %>%
  bind_cols(cases_dynamic %>% select(dose_name, q_per_day))

results_frac_uniform_static <- cases_static %>% 
  select(-dose_name, -q_per_day) %>%
  mutate(result = pmap(., opt_01)) %>%
  unnest_wider(result, names_sep = "_") %>%
  bind_cols(cases_static %>% select(dose_name, q_per_day))

results_frac_age <- cases_df %>% 
  select(-dose_name, -q_per_day) %>% 
  mutate(result = pmap(., opt_general, n_x = 7, unroll_x = unroll_7)) %>%
  unnest_wider(result, names_sep = "_") %>%
  bind_cols(cases_df %>% select(dose_name, q_per_day))

df_results <- list(
  mutate(results_full_dose,            solution = "full_dose"),
  mutate(results_frac_uniform_static,  solution = "frac_uniform"),
  mutate(results_frac_uniform_dynamic, solution = "frac_uniform"),
  mutate(results_frac_age,             solution = "frac_age")
) %>% 
  bind_rows() %>% 
  select(-objective, -homogen_mixing, -pdeath, -recurring, -iterations, -initial_value,
         -result_n_iterations, -result_message, -dose_response) %>% 
  left_join(
    results_novac %>% select(scenario, no_vac),
    by = c("scenario")
  ) %>% 
  mutate(static = ifelse(static, "Static case", "Dynamic case"),
         scenario = ifelse(scenario == "pars_le_slow", "slow-growth (R0 = 1.1)", "fast-growth (R0 = 2)")) %>% 
  rename(key = solution, value = result_objective) 

saveRDS(df_results, file = "results/nlopt_results.rds")
