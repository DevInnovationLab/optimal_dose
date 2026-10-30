# ------------------------------------------------------------------------------
# Helper functions for the optimization and result-generating processes
# 
# 1. unroll_vaccine_hesitancy
# 2. obj_full
# 3. obj_no_vac
# 4. opt_01
# ------------------------------------------------------------------------------

# for adding first two age groups to a vector of parameters
unroll_1 <- function(x, sub = 1) c(sub, sub, rep(x, 7))
unroll_7 <- function(x, sub = 1) c(sub, sub, x)

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
obj_full <- function(q = 1, 
                     objective = "D", 
                     dose_response = phi_covid, 
                     homogen_mixing = FALSE,
                     static = TRUE, 
                     pdeath = "ifr_hic", 
                     scenario = "base",
                     recurring = c(0.8, 0.2, 0.5, 1)) {
  
  
  phi_x <- dose_response
  if (class(phi_x) == "character" && (phi_x == "covid_default"))
    phi_x <- phi_covid
  
  if (static) {
    q <- q * sum(pop[3:9])
    frac_vac <- rep(0, 7)
    # Vaccinate according to fd until the total supply runs out
    # i-2 and 3:9 because we ignore under 20 yo's
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
    
    pars <- list_modify(
      grab_2v_parms(scenario),
      y0 = y0_gen(13, Ngroups, pre_immunity = pre_immunity + pre_immunity_plus))
    
    if (pdeath == "ifr_hic") {pdeath <- ifr_hic
    } else if (pdeath == "ifr_lic") {pdeath <- ifr_lic}
    pars <- list_modify(pars, pdeath = pdeath)
    
    if (homogen_mixing) {
      pars$contacts <- t(replicate(Ngroups, pop))
      pars$q <- ev*pars$q
    }
    
    
    rep <- unroll_vaccine_hesitancy(recurring[1], recurring[2], recurring[3], recurring[4])
    if (length(rep) == 1) {
      y <- sr(pars, "2v_v2")
    } else if (length(rep) > 1) {
      y <- multi_year_run(pars, "2v_v2", rep)
    }
    y <- rescale_rcs(y, pop, TRUE)
    obj_value <- y[360 * recurring[4],objective,1]
    
  } else {
    obj_value <- model_fd_dynamic(scenario = scenario, 
                                  length_campaign = q, 
                                  fd = rep(1,9),
                                  phi_x = phi_x, 
                                  pdeath = pdeath,
                                  ret = 1, 
                                  objective = objective, 
                                  homogen = homogen_mixing,
                                  rep = recurring)
    frac_vac <- model_fd_dynamic(scenario = scenario, 
                                 length_campaign = q, 
                                 fd = rep(1,9),
                                 phi_x = phi_x, 
                                 pdeath = pdeath,
                                 ret = 1, 
                                 objective = objective, 
                                 homogen = homogen_mixing,
                                 rep = recurring, 
                                 calc_frac_vac = T)
  }
  
  # Return vaccination fraction and objective function value  
  list("solution"  = tibble(age_group = factor(3:9, 
                                               levels = paste0(3:9), 
                                               labels = colnames(pbc_spread)[3:9]), 
                            solution = 1) %>% 
         left_join(frac_vac, by = "age_group"), 
       "objective" = obj_value)
}


# ------------------------------------------------------------------------------
# 3. Similar to 2, but with zero vaccination for any group.
# ------------------------------------------------------------------------------

obj_no_vac_v2 <- function(objective = "D", 
                          homogen_mixing = FALSE, 
                          pdeath = "ifr_hic", 
                          scenario = "base",
                          recurring = c(0.8, 0.2, 0.5, 1)) {
  
  # Set up parameters for the single run of the epidemic
  rep <- unroll_vaccine_hesitancy(recurring[1], recurring[2], recurring[3], recurring[4])
  if (pdeath == "ifr_hic") {pdeath <- ifr_hic} else {pdeath <- ifr_lic}
  pars <- list_modify(grab_2v_parms(scenario), e1 = 0, pdeath = pdeath)
  if(homogen_mixing){
    pars$contacts <- t(replicate(Ngroups, pop))
    pars$q <- 0*pars$q
  }
  
  # Calculate burden
  if (length(rep) == 1) {
    y <- sr(pars, "2v_v2")
  } else if (length(rep) > 1) {
    pars <- list_modify(pars, 
                        kappa1 = rep(1/immunity_length, 9),
                        phi = rep(1/immunity_length, 9))
    y <- multi_year_run(pars, "2v_v2", rep)
  }
  
  # Calculate the objective function value
  y <- rescale_rcs(y, pop, TRUE)
  return(y[nrow(y),objective,1])
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



