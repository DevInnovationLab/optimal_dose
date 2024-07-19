# ------------------------------------------------------------------------------
# Helper functions for the optimization and result-generating processes
# 
# 1. unroll_vaccine_hesitancy
# 2. obj_full
# 3. obj_no_vac
# 4. opt_01
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# 1. For multi-year runs, willingness to vaccinate will change in subsequent 
#    years. This function specifies hesitancy in a format that the ODE solver 
#    can then use.
# ------------------------------------------------------------------------------

unroll_vaccine_hesitancy <- function(a,b,c, nyears) {
  lst <- list()
  lst[[1]] <- rep(a, 9)
  
  if (nyears > 1) {
    for (i in (2:nyears)) {
      lst[[i]] <- c(0,0,b,b,b,b,b,c,c)
    }
  }
  return(lst)
}

# ------------------------------------------------------------------------------
# 2. Define wrapper function for the objective function with constant full dose,
#    fitting the data frame structure as defined in nlopt_all_cases.R. 
# ------------------------------------------------------------------------------
obj_full <- function(q, initial_value, objective, dose_response, homogen_mixing,
                     static, pdeath, scenario, recurring, iterations) {
  
  if (static) {
    q <- q * sum(pop[3:9])
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
    
    phi_x <- dose_response
    if (phi_x == "covid_default") {
      phi_x <- phi_covid
    } else if (phi_x == "flu_default") {
      phi_x <- function(x) 0
    }
    
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

# ------------------------------------------------------------------------------
# 3. Similar to 2, but with zero vaccination for any group.
# ------------------------------------------------------------------------------

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

# ------------------------------------------------------------------------------
# 4. For the static cases, we further consider the possibility of pre-vaccinating 
#    only selected age groups, when evenly distributing the vaccine to everyone 
#    in the groups. This function finds the optimal assignment of groups and the 
#    minimized objective. 
# ------------------------------------------------------------------------------

opt_01 <- function(q, initial_value, objective, dose_response, homogen_mixing,
                   static, pdeath, scenario, recurring, iterations) {

  if (static == F) {stop("opt_01 is for static cases only")}
  
  q <- q * sum(pop[3:9]) # Re-scale q as for the entire population
  
  # Generate all 0-10 combinations of vaccinated fraction
  objectives_01 <- expand.grid(replicate(7, c(0, 1), simplify = FALSE))
  objectives_01 <- objectives_01[-1,] %>% # Delete the all zero case
    pmap(~ as.numeric(c(...)))
  
  # Compute the objective value for each combination
  objectives_01 <- tibble(frac_vac = objectives_01) %>% 
    mutate(objective = pmap(., function(frac_vac) {
      # Compute dose fraction for each group when evenly distributing the total
      # supply to everyone in the groups set to 1
      frac_vac <- c(0, 0, frac_vac)
      fd <- pmin(frac_vac * (q / sum(pop * frac_vac)), 1)
      # Compute the objective
      model_fd_static(scenario = scenario,
                      fd = fd, 
                      phi_x = dose_response, 
                      pdeath = pdeath,
                      objective = objective,
                      homogen = homogen_mixing,
                      ret = 1,
                      rep = recurring)
      }))
    
    # Find and store the combination with minimum objective
    obj_min <- min(as.numeric(objectives_01$objective))
    frac_vac_min <- objectives_01$frac_vac[[which.min(objectives_01$objective)]]
    
    solution <- tibble(
      age_group = factor(3:9, levels = paste0(3:9), labels = colnames(pbc_spread)[3:9]),
      solution = frac_vac_min * (q / sum(pop * c(0, 0, frac_vac_min))),
      frac_vac = frac_vac_min
      )
    
    list("solution" = solution, "objective" = obj_min)
  }



