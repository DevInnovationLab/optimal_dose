source("project_setup.R")

library(ggplot2)
library(knitr)
library(kableExtra)
library(scales)
library(patchwork)

theme_set(theme_minimal(base_size = 11))

optim_names <- c("Age-specific", "Age-invariant", "Standard dose")
optim_values <- c("#E69F00", "#56B4E9", "black")
optim_lvls <- c("frac_age", "frac_uniform", "full_dose")

df_results <- readRDS("results/nlopt_results.rds")


# Table with optimal solutions -----
q_val <- c(100, 200, 500, 2000)
# q_lab <- c("Three month campaign", "Six month campaign", "One year campaign", "60+ yo only in one year")
q_lab <- c(100, 200, 500, 2000)

df_obj_tab <- df_results %>% 
  select(-result_solution) %>% 
  mutate(key = factor(key, levels = optim_lvls, labels = optim_names)) %>% 
  mutate(reduction = 1 - value/no_vac) %>% 
  mutate(value = value*10000) %>% 
  filter(static == "Dynamic case") %>% 
  mutate(value = paste0(
    format(round(value, 1), nsmall = 1),
    " (", percent(reduction, 1), ")")) %>% 
  filter(q %in% q_val) %>% 
  mutate(q = factor(q, levels = q_val, labels = q_lab)) %>%
  select(scenario, static, q, dose_name, key, value) %>% 
  spread(key, value) %>% 
  arrange(dose_name, scenario) %>% 
  left_join (
    df_results %>% 
      filter(static == "Dynamic case") %>% 
      filter(key == "frac_uniform") %>% 
      unnest(result_solution) %>% 
      select(q, scenario, solution, dose_name) %>% distinct %>%
      arrange(scenario, q) %>% 
      filter(q %in% q_val) %>% 
      mutate(q = factor(q, levels = q_val, labels = q_lab)) %>% 
      mutate(solution = round(solution, 2)) %>% 
      rename(dose = solution)
  ) 

df_obj_tab



# concave case
latex_table <- df_obj_tab[1:8,] %>% 
  ungroup() %>% 
  select(-static, -scenario, -dose_name) %>% 
  knitr::kable(format = "latex", booktabs = TRUE) %>% 
  add_header_above(c(" ", "Deaths per 10,000" = 3)) %>% 
  pack_rows("Fast-growing epidemic, R0 = 2", 1, 4) %>% 
  pack_rows("Slow-growing epidemic, R0 = 1.1", 5,8)

writeLines(latex_table, "paper/table_concave.tex")

# sigmoid case
latex_table <- df_obj_tab[9:16,] %>% 
  ungroup() %>% 
  select(-static, -scenario, -dose_name) %>% 
  knitr::kable(format = "latex", booktabs = TRUE) %>% 
  add_header_above(c(" ", "Deaths per 10,000" = 3)) %>% 
  pack_rows("Fast-growing epidemic, R0 = 2", 1, 4) %>% 
  pack_rows("Slow-growing epidemic, R0 = 1.1", 5,8)

writeLines(latex_table, "paper/table_sigmoid.tex")




