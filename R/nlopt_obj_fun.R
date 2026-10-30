# Define objective functions for the dynamic or static optimization problem

# ------------------------------------------------------------------------------
# Dynamic objective function
# ------------------------------------------------------------------------------
# - scenario: "base" for the main calibration. see grab_2v_parms()
# - length_campaign: length of the vaccination campaign in days, which regulates the supply constraint
# - fd: dose fraction
# - phi_x: dose response function
# - rm: return model? if TRUE, the raw output from single_run will be returned
# - ret: whether the output compartment values are scaled by population
# - objective: which compartment value to be minimized, either "D" (death) or "cumI" (total infection)
# - homogen: whether the mixing (contacts across groups) is homogenous or heterogenous
# - rep: vector of four arguments to unroll_vaccine_hesitancy()
# - calc_frac_vac: whether to compute and return the fraction vaccinated

model_fd_dynamic <- function(scenario, 
                             length_campaign, 
                             fd, 
                             phi_x = function(x) x,
                             pdeath = "ifr_hic",
                             rm = FALSE,
                             ret = 0,
                             objective = "D",
                             homogen = FALSE,
                             immunity_length = 365,
                             rep = c(0.8, 0.2, 0.5, 1),
                             calc_frac_vac = FALSE) {
  
  if (rep[4] == 1) {single_season <- T} else {single_season <- F}
  
  rep <- unroll_vaccine_hesitancy(rep[1], rep[2], rep[3], rep[4])
  
  e1 <- phi_x(fd)
  
  if (pdeath == "ifr_hic") {pdeath <- ifr_hic} else {pdeath <- ifr_lic}
  
  pars <- apap_2v(grab_2v_parms(scenario), 
                  fractional_dose = fd, 
                  len = length_campaign)
  pars <- list_modify(pars, e1 = e1, pdeath = pdeath)
  if(homogen){
    pars$contacts <- t(replicate(Ngroups, pop))
    pars$q <- ev*pars$q
  }
  if (length(rep) == 1) {
    y <- sr(pars, "2v_v2")
  } else if (length(rep) > 1) {
    pars <- list_modify(pars, 
                        kappa1 = rep(1/immunity_length, 9),
                        phi = rep(1/immunity_length, 9))
    # !!!this model will only make sense if kappa = phi!!!
    y <- multi_year_run(pars, "2v_v2", rep)
  }
  
  # Find the vaccinated fraction on the day with maximum I for each age group
  if (calc_frac_vac) {
    if (single_season) {
      # Population for each group, to compute the weighted total infection
      group_pop <- tibble(age_group = dimnames(y)[[3]], population = pop)
      # Long format of the output matrix y with group population
      y_long <- as_tibble(as.data.frame.table(y, responseName = "value")) %>% 
        rename(day = Var1, factor = Var2, age_group = Var3) %>% 
        filter(factor %in% c("I", "P1", "N1", "P2", "N2")) %>% 
        left_join(group_pop, by = "age_group")
      # Find the day of maximum population-weighted infection
      max_I <- y_long %>% 
        filter(factor == "I") %>%
        group_by(day) %>% 
        summarize(tot_I = weighted.mean(value, population)) %>% 
        ungroup() %>% 
        filter(tot_I == max(tot_I)) %>% 
        pull(day) %>% 
        as.numeric()
      # P+N sum on the day with max I for each age group
      return(
        y_long %>% 
          filter(day == max_I[1] & !factor == "I" & !age_group %in% c("[0,10)", "[10,20)")) %>% 
          group_by(age_group) %>% 
          summarize(frac_vac = sum(value)) %>% 
          mutate(max_I_day = max_I[1])
      )
    } else { # If multi-season then return NA
      return(tibble(age_group = dimnames(y)[[3]][-c(1,2)], 
                    frac_vac = NA,
                    max_I_day = NA))
    }
  }
  
  if(ret == 1)
    y <- rescale_rcs(y, pop, TRUE)
  if(rm) 
    return(y)
  if(ret == 0)
    return(y)
  return(y[360 * length(rep),objective,1])
}



# ------------------------------------------------------------------------------
# Static objective function
# ------------------------------------------------------------------------------
# - scenario: "base" for the main calibration.
# - fd: dose fraction
# - phi_x: dose response function
# - rm: whether the raw output from single_run will be returned
# - ret: whether the output compartment values are scaled by population
# - objective: which compartment value to be minimized, either "D" (death) or "cumI" (total infection)
# - homogen: whether the mixing (contacts across groups) is homogenous or heterogenous
# - rep: how many times vaccination recurs (number of years)
# - calc_frac_vac: whether to compute and return the fraction vaccinated
# 
# Note that the supply constraint is not built into the objective function, 
# rather, it is built into the optimization problem as the optimization constraint. 
# Refer to line xxx of nlopt_general.R for more detail. 

model_fd_static <- function(scenario, 
                            fd, 
                            phi_x,
                            pdeath = "ifr_hic",
                            rm = FALSE,
                            ret = 0,
                            objective = "D",
                            homogen = FALSE,
                            full = 0,
                            rep = c(0.8, 0.2, 0.5, 1),
                            calc_frac_vac = FALSE) {
  
  if (rep[4] == 1) {single_season <- T} else {single_season <- F}
  
  rep <- unroll_vaccine_hesitancy(rep[1], rep[2], rep[3], rep[4])
  
  e_vector <- phi_x(fd)
  
  if (pdeath == "ifr_hic") {pdeath <- ifr_hic
  } else if (pdeath == "ifr_lic") {pdeath <- ifr_lic}
  
  if (full){
    e_vector <- fd*phi_x(1)
  }
  pars <- list_modify(
    grab_2v_parms(scenario),
    y0 = y0_gen(13, Ngroups, pre_immunity = pre_immunity + (1-pre_immunity)*e_vector))
  if(homogen){
    pars$contacts <- t(replicate(Ngroups, pop))
    pars$q <- ev*pars$q
  }
  pars <- list_modify(pars, pdeath = pdeath)
  # We do not update e1, because there is no vaccination past t=0 
  if (length(rep) == 1) {
    y <- sr(pars, "2v_v2")
  } else if (length(rep) > 1) {
    y <- multi_year_run(pars, "2v_v2", rep)
  }
  
  # Find the vaccinated fraction on the day 0
  if (calc_frac_vac) {
    if (single_season) {
      q <- sum(fd * pop)
      frac_vac <- rep(0, 7)
      # Vaccinate according to fd until the total supply runs out
      for (i in c(9:3)) {
        q <- q - fd[i] * pop[i]
        if (q > 0) {
          frac_vac[i - 2] <- fd[i]
        } else {
          frac_vac[i - 2] <- (q + fd[i] * pop[i]) / pop[i]
          break
        }
      }
      return(tibble(age_group = dimnames(y)[[3]][-c(1,2)],
                    frac_vac = frac_vac,
                    max_I_day = 0))
    } else {# If multi-season then return NA
      return(tibble(age_group = dimnames(y)[[3]][-c(1,2)], 
                    frac_vac = NA,
                    max_I_day = NA))
    }
  }
  
  if(ret == 0)
    return(y)
  if(ret == 1){
    y <- rescale_rcs(y, pop, TRUE)
    return(y[360 * length(rep),objective,1])
  }
}
