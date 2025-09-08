# Table with optimal solutions -----
q_table <- c(0.03, 0.01, 0.005, 0.003, 0.001, 0.0005, 0.0001)
q_labels <- paste(scales::percent(q_table), "per day")
df_obj_tab <- df_results %>% 
  select(-result_solution) %>% 
  mutate(key = factor(key, levels = optim_lvls, labels = optim_names)) %>% 
  mutate(reduction = 1 - value/no_vac) %>% 
  mutate(value = value*10000) %>% 
  filter(static == "Dynamic case") %>% 
  mutate(value = paste0(
    format(round(value, 1), nsmall = 1),
    " (", percent(reduction, 1), ")")) %>% 
  filter(q_per_day %in% q_table) %>% 
  mutate(q_per_day = factor(q_per_day, levels = q_table, labels = q_labels)) %>%
  select(scenario, static, q_per_day, dose_name, key, value) %>% 
  spread(key, value) %>% 
  arrange(dose_name, scenario) %>% 
  left_join (
    df_results %>% 
      filter(static == "Dynamic case") %>% 
      filter(key == "frac_uniform") %>% 
      unnest(result_solution) %>% 
      select(q_per_day, scenario, solution, dose_name) %>% distinct %>%
      arrange(scenario, q_per_day) %>% 
      filter(q_per_day %in% q_table) %>% 
      mutate(q_per_day = factor(q_per_day, levels = q_table, labels = q_labels)) %>% 
      mutate(solution = round(solution, 2)) %>% 
      rename(dose = solution)
  ) %>% 
  filter(scenario == "fast-growth (R0 = 2)")

df_obj_tab

latex_table <- df_obj_tab %>% 
  ungroup() %>% 
  select(-static, -scenario, -dose_name) %>% 
  knitr::kable(format = "latex", booktabs = TRUE) %>% 
  add_header_above(c("Standard doses per day", "Deaths per 10,000" = 3)) %>% 
  pack_rows("Concave dose-response, R0 = 2", 1, 7) %>% 
  pack_rows("Sigmoid dose-response, R0 = 1.1", 8, 14)

writeLines(latex_table, "paper/table_concave_sigmoid.tex")
