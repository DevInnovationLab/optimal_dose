# ------------------------------------------------------------------------------
# Generate the aggregate list of optimization results with different options. 
# 
# Three general categories are: 
# 1. Full dose (no optimization needed)
# 2. Optimal universal fractional dose (1-dimensional optimization)
# 3. Optimal fractional dose for each age group (7-dimensional optimization)
# in addition to: 
# 4. No vaccination (no optimization needed, as a basic benchmark)
# 
# Output: Combined results under different options for the three categories. 
# The first 10 columns are combinations of options, the later 4 are:
#   - result_solution: 
#       1 & 4. N.A.
#       2. numeric value of the optimal universal dose fraction 
#       3. 7 x 2 tibble of age groups and corresponding optimal dose fractions
#   - result_objective: 
#       1 & 2 & 3 & 4: objective value evaluated at the solution
#   - result_n_iterations:
#       1 & 4: N.A.
#       2 & 3: the number of iterations in the solving process
#   - result_message: 
#       1 & 4: N.A.
#       2 & 3: message from nloptr about the status of the optimization
# ------------------------------------------------------------------------------

# For multi-thread performance, set the number of workers to the number of 
# logical processors. This does not work if Rtools is used to generate a 
# temporary optimized copy of the odin package. 
plan(multisession, workers = 4)

# ------------------------------------------------------------------------------
# Setup 1: Generate grids of all option combinations
# ------------------------------------------------------------------------------

# Since q is defined differently for dynamic and static problems, so we generate
# the grids for them separately and rbind later. 

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

# Define wrapper function for the objective function with constant full dose. 
# The purpose of the wrapper is to fit the data frame structure defined above. 
obj_full <- function(q, initial_value, objective, dose_response, homogen_mixing,
                     static, pdeath, scenario, recurring, iterations) {
  
  if (static) {
    frac_vac <- rep(0, 7)
    # Vaccinate according to fd until the total supply runs out
    for (i in c(9:3)) {
      q <- q - pop[i]
      if (q > 0) {
        frac_vac[i - 2] <- 1
      } else {
        frac_vac[i - 2] <- (q + pop[i]) / pop[i]
        break
      }
    }
    frac_vac <- tibble(age_group = factor(3:9, levels = paste0(3:9), 
                                          labels = colnames(pbc_spread)[3:9]),
                       frac_vac = frac_vac,
                       max_I_day = 0)
    
    pre_immunity_plus <- c(0, 0, sapply(frac_vac$frac_vac, 
                                        function(frac_vac){
                                          ifelse(test = frac_vac >= 0.8, 
                                                 yes = 0.8 * phi_x(1), 
                                                 no = frac_vac * phi_x(1))}))
    
    if (pdeath == "ifr_hic") {pdeath <- ifr_hic
    } else if (pdeath == "ifr_lic") {pdeath <- ifr_lic}
        
    pars <- list_modify(
      grab_2v_parms(scenario),
      y0 = y0_gen(13, Ngroups, pre_immunity = pre_immunity + pre_immunity_plus))
    
    if (homogen_mixing) {
      pars$contacts <- t(replicate(Ngroups, pop))
      pars$q <- ev*pars$q
    }
    pars <- list_modify(pars, pdeath = pdeath)
        
    rep <- unroll_vaccine_hesitancy(recurring[1], recurring[2], recurring[3], recurring[4])
    if (length(rep) == 1) {
      y <- sr(pars, "2v_v2")
    } else if (length(rep) > 1) {
      y <- multi_year_run(pars, "2v_v2", rep)
      }
    y <- rescale_rcs(y, pop, TRUE)
    obj <- y[360 * recurring[4],objective,1]
    } else {
      obj <- model_fd_dynamic(scenario = scenario, 
                               length_campaign = q, 
                               fd = rep(1, 9),
                               phi_x = dose_response, 
                               pdeath = pdeath,
                               ret = 1, 
                               objective = objective, 
                               homogen = homogen_mixing,
                               rep = recurring)
      frac_vac <- model_fd_dynamic(scenario = scenario, 
                                   length_campaign = q, 
                                   fd = rep(1, 9),
                                   phi_x = dose_response, 
                                   pdeath = pdeath,
                                   ret = 1, 
                                   objective = objective, 
                                   homogen = homogen_mixing,
                                   rep = recurring, 
                                   calc_frac_vac = T)
    }
      solution <- tibble(age_group = factor(3:9, levels = paste0(3:9), 
                                            labels = colnames(pbc_spread)[3:9]), 
                         solution = 1) %>% 
        left_join(frac_vac, by = "age_group")
      
      list("solution" = solution, 
           "objective" = obj)
  }

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

# Similar to 1, but with zero vaccination for any group
obj_no_vac <- function(q, initial_value, objective, dose_response, homogen_mixing,
                     static, pdeath, scenario, recurring, iterations) {
  
  if (static){
    rep <- unroll_vaccine_hesitancy(recurring[1], recurring[2], recurring[3], recurring[4])
    
    phi_x <- dose_response
    if (phi_x == "covid_default") {phi_x <- function(x) -25.31701*x^1.037524 + 1.037524*25.31701*x
    } else if (phi_x == "flu_default") {phi_x <- function(x) 0}
    
    if (pdeath == "ifr_hic") {pdeath <- ifr_hic
    } else if (pdeath == "ifr_lic") {pdeath <- ifr_lic}
    
    pars <- grab_2v_parms(scenario)
    if(homogen_mixing){
      pars$contacts <- t(replicate(Ngroups, pop))
      pars$q <- ev*pars$q
    }
    pars <- list_modify(pars, pdeath = pdeath)
    
    rep <- unroll_vaccine_hesitancy(recurring[1], recurring[2], recurring[3], recurring[4])
    if (length(rep) == 1) {
      y <- sr(pars, "2v_v2")
    } else if (length(rep) > 1) {
      y <- multi_year_run(pars, "2v_v2", rep)
    }
    
    y <- rescale_rcs(y, pop, TRUE)
    return(y[360 * recurring[4],objective,1])
  } else {
    model_fd_dynamic(scenario = scenario, 
                     length_campaign = q, 
                     fd = rep(0.000001, 9), 
                     phi_x = dose_response, 
                     pdeath = pdeath,
                     ret = 1, 
                     objective = objective, 
                     homogen = homogen_mixing,
                     rep = recurring)
  }
}

# Apply all combinations of options to the wrapper function.
results_no_vac_dynamic <- cases_dynamic %>% 
  mutate(result_objective = future_pmap(., obj_no_vac))

results_no_vac_static <- cases_static %>% 
  mutate(result_objective = future_pmap(., obj_no_vac))

results_no_vac <- results_no_vac_dynamic %>% rbind(results_no_vac_static)

save(results_no_vac, file = "results/results_no_vac.Rdata")

# ------------------------------------------------------------------------------
# 4. Merge 
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



