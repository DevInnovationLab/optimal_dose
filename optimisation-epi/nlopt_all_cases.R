# ------------------------------------------------------------------------------
# Generate the aggregate list of optimization results with different options. 
# 
# General categories of results are:
# 1. Full dose (no optimization needed)
# 2. Optimal universal fractional dose (1-dimensional optimization)
# 3. Optimal fractional dose for each age group (7-dimensional optimization)
# 4. No vaccination (no optimization needed, as a basic benchmark)
# 5. (For static cases only) Pre-vaccination of optimally selected age groups
# 
# Output: Combined results under different options, named "results_all"
#   - The first 9 columns are combinations of options
#   - Columns "full_dose_sol", "frac_uni_sol", "frac_age_sol", "frac_01_sol" 
#     contain tibbles as elements, each with columns:
#      - age_group
#      - solution: (optimal) dose fraction
#      - frac_vac: vaccinated fraction in each group, all 1 for static cases, 
#           and the sum of P and N compartments on the day of maximum infections
#           for dynamic cases
#      - max_I_day: the day of maximum infections, 0 for static cases
#   - Columns "full_dose", "frac_uni", "frac_age", "no_vac" "frac_01" are 
#     are numeric objective values under the option combination and the solution
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# 0. Setup
# ------------------------------------------------------------------------------

# For multi-thread performance, set the number of workers to the number of 
# logical processors. This does not work if Rtools is used to generate a 
# temporary optimized copy of the odin package. 
plan(multisession, workers = 4)

# Generate all combinations of options. Since q is defined differently for 
# dynamic and static problems, we generate the grids separately and rbind later. 
cases_dynamic <- expand_grid(q = c(3, 5, 10, 15, 30, 90, 180, 360, 720, 1440), 
                             objective = c("D", "cumI"), 
                             dose_response = "covid_default",
                             homogen_mixing = c(T, F),
                             static = F,
                             pdeath = c("ifr_hic", "ifr_lic"), 
                             scenario = c("pars_le_slow", "pars_le_fast"),
                             recurring = list(c(0.8,0.2,0.5,1),
                                              c(0.8,0.2,0.5,5)),
                             iterations = 20000) %>% 
  # Initial value set as random uniform draw
  mutate(initial_value = runif(320, 0.1, 0.9)) %>% 
  relocate(initial_value, .after = q)
    
cases_static <- expand_grid(q = c(0.01, 0.05, 0.1, 0.2, 0.3, 0.5, 
                                  0.4, 0.6, 0.7, 0.8, 0.9, 1),
                            objective = c("D", "cumI"), 
                            dose_response = "covid_default",
                            homogen_mixing = c(T, F),
                            static = T,
                            pdeath = c("ifr_hic", "ifr_lic"), 
                            scenario = c("pars_le_slow", "pars_le_fast"),
                            recurring = list(c(0.8,0.2,0.5,1),
                                             c(0.8,0.2,0.5,5)),
                            iterations = 20000) %>% 
  # Initial value set as 1/7 of total vaccine sapply
  mutate(initial_value = q / 7) %>% 
  relocate(initial_value, .after = q)

# ------------------------------------------------------------------------------
# 1. Full dose
# ------------------------------------------------------------------------------

# Apply all combinations of options to the wrapper function.
results_full_dose_dynamic <- cases_dynamic %>% 
  mutate(result = pmap(., obj_full)) %>% 
  unnest_wider(result, names_sep = "_")

results_full_dose_static <- cases_static %>% 
  mutate(result = pmap(., obj_full)) %>% 
  unnest_wider(result, names_sep = "_")

results_full_dose <- results_full_dose_dynamic %>% rbind(results_full_dose_static)

save(results_full_dose, file = "results/results_full_dose.Rdata")

# ------------------------------------------------------------------------------
# 2. Optimal universal fractional dose
# ------------------------------------------------------------------------------

# Since we the dose fraction is universal, we redefine the dimension of the 
# problem to 1 and adjust the unroll_x function accordingly. 
n_x <- 1
unroll_x <- function(x, sub = 1) {c(sub, sub, rep(x, 7))} 

results_frac_uni_dynamic <- cases_dynamic %>% 
  mutate(result = future_pmap(., opt_general)) %>% 
  unnest_wider(result, names_sep = "_")
  # mutate(result_solution = map(result_solution, pluck, 2)) %>% 
  # mutate(result_solution = map(result_solution, pluck, 1))

save(results_frac_uni_dynamic, file = "results/results_frac_uni_dynamic.Rdata")

results_frac_uni_static <- cases_static %>%
  mutate(result = pmap(., opt_general)) %>%
  unnest_wider(result, names_sep = "_")

save(results_frac_uni_static, file = "results/results_frac_uni_static.Rdata")

results_frac_uni <- results_frac_uni_dynamic %>% rbind(results_frac_uni_static)

save(results_frac_uni, file = "results/results_frac_uni.Rdata")

# ------------------------------------------------------------------------------
# 3. Optimal fractional dose for each age group
# ------------------------------------------------------------------------------

# Restore the original definition of n_x and unroll_x in nlopt_general.R. 
n_x <- 7
unroll_x <- function(x, sub = 1) {
  c(sub, sub, x[1], x[2], x[3], x[4], x[5], x[6], x[7])
} 

results_frac_age_dynamic <- cases_dynamic %>% 
  mutate(result = pmap(., opt_general)) %>% 
  unnest_wider(result, names_sep = "_")

save(results_frac_age_dynamic, file = "results/results_frac_age_dynamic.Rdata")

results_frac_age_static <- cases_static %>% 
  mutate(result = pmap(., opt_general)) %>% 
  unnest_wider(result, names_sep = "_")

save(results_frac_age_static, file = "results/results_frac_age_static.Rdata")

results_frac_age <- results_frac_age_dynamic %>% 
  rbind(results_frac_age_static)

save(results_frac_age, file = "results/results_frac_age.Rdata")

# ------------------------------------------------------------------------------
# 4. No vaccination
# ------------------------------------------------------------------------------

# Apply all combinations of options to the wrapper function.
results_no_vac_dynamic <- cases_dynamic %>% 
  mutate(result_objective = future_pmap(., obj_no_vac))

results_no_vac_static <- cases_static %>% 
  mutate(result_objective = future_pmap(., obj_no_vac))

results_no_vac <- results_no_vac_dynamic %>% rbind(results_no_vac_static)

save(results_no_vac, file = "results/results_no_vac.Rdata")

# ------------------------------------------------------------------------------
# 5. Vaccination of optimally selected groups (for static cases only)
# ------------------------------------------------------------------------------

results_frac_01_static <- cases_static %>% 
  mutate(result = pmap(., opt_01)) %>% 
  unnest_wider(result, names_sep = "_")



# ------------------------------------------------------------------------------
# 6. Merge 
# ------------------------------------------------------------------------------

load("results/results_no_vac.Rdata")
load("results/results_full_dose.Rdata")
load("results/results_frac_age.Rdata")
load("results/results_frac_uni.Rdata")

results_frac_uni <- results_frac_uni %>% 
  select(-result_message, -result_n_iterations)

results_frac_age <- results_frac_age %>% 
  select(-result_message, -result_n_iterations)

results_all <- 
  results_full_dose %>% 
  rename(full_dose = result_objective,
         full_dose_sol = result_solution) %>% 
  left_join(results_frac_uni, 
            by = c("q", "initial_value", "objective","dose_response", 
                   "homogen_mixing", "static", "pdeath", "scenario", 
                   "recurring", "iterations")) %>% 
  rename(frac_uni = result_objective,
         frac_uni_sol = result_solution) %>% 
  left_join(results_frac_age,
            by = c("q", "initial_value", "objective","dose_response", 
                   "homogen_mixing", "static", "pdeath", "scenario", 
                   "recurring", "iterations")) %>% 
  rename(frac_age = result_objective,
         frac_age_sol = result_solution) %>% 
  left_join(results_no_vac,
            by = c("q", "initial_value", "objective","dose_response", 
                   "homogen_mixing", "static", "pdeath", "scenario", 
                   "recurring", "iterations")) %>% 
  rename(no_vac = result_objective) %>% 
  mutate(across(c(full_dose, frac_uni, frac_age, no_vac), ~map_dbl(., 1)))

save(results_all, file = "results/results_all.Rdata")



