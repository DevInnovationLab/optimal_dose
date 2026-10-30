# ------------------------------------------------------------------------------
# Define the optimization problem of fractional dose
# ------------------------------------------------------------------------------

# Helper objects
prop_adults <- sum(pop[3:9])/sum(pop) #for now I ignore children, so Q is scaled down to adult pop
q_seq <- c(0.1, 0.25, 0.5, 0.75, 1) #just try two quantities at first

# see below for explanation, these are the global defaults
# n_x <- 7
# unroll_x <- function(x, sub=1) #set sub to 0 for static model where no doses go to children
  # c(sub,sub,x[1],x[2],x[3],x[4],x[5],x[6],x[7])


# Function Arguments:
# 
# - q_seq: supply constraints (optimization is run for each constraint)
#          * (dynamic) length of vaccination campaign in days
#          * (static) total dose amount available (percentage of full dose for entire population)
# - initial_value: dose fraction used for a single-start fit
# - objective: either "D" (death) or "cumI" (cumulative infection) 
# - dose_response: function phi(x) of efficacy response to dose fraction
# - supply_constraint:
# - homogen_mixing: TRUE or FALSE
# - static: TRUE or FALSE for static problem
# - pdeath: mortality risk vector, default to high-income country case
# - scenario: "base" for the main calibration
# - recurring: list with vectors vaccine hesitancy parameter for each year of the campaign
# - n_starts: 1--5 starts for dynamic age-varying fits; defaults to 1
# - n_x = number of parameters to optimise
# - unroll_x = how the different x's (1, ..., n_x) unroll into a vector of doses
opt_general <- 
  function(q,
           initial_value,
           objective = "D",
           dose_response = phi_covid,
           homogen_mixing = F, 
           static = T,
           pdeath = "ifr_hic",
           scenario = "base",
           recurring = c(0.8,0.2,0.5,1),
           n_x = 7,
           unroll_x = function(x, sub=1) c(sub,sub,x[1],x[2],x[3],x[4],x[5],x[6],x[7]),
           iterations = 1000,
           n_starts = 1) {
    
    if (class(dose_response) == "character" && (dose_response == "covid_default"))
      dose_response <- phi_covid
    
    # Select objective function
    if(static)
      eval_f <- function(x) model_fd_static(scenario = scenario,
                                            fd = unroll_x(x,sub=0), 
                                            phi_x = dose_response, 
                                            pdeath = pdeath,
                                            objective = objective,
                                            homogen = homogen_mixing,
                                            ret = 1,
                                            rep = recurring)
    else
      eval_f <- function(x) model_fd_dynamic(scenario = scenario,
                                             fd = unroll_x(x,sub=1), 
                                             length_campaign = q,
                                             phi_x = dose_response,
                                             pdeath = pdeath,
                                             objective = objective,
                                             ret = 1,
                                             homogen = homogen_mixing,
                                             rep = recurring)
    # Set equality constraints
    if(static) {
      q <- q * sum(pop[3:9]) # Re-scale q as for the entire population
      # In the static case, the total dose applied is equal to the total dose available
      # Need to change this constraint according to the number of groups
      eval_g_ineq <- function(x) c(sum(x * pop[3:9]) - q, - sum(x * pop[3:9]) + q)
    } else {
      eval_g_ineq <- NULL
    }
    
    # Lower and upper bounds
    ub <- rep(1,n_x)
    
    # Initial values
    if(static){
      lb <- rep(0,n_x)
      x0 <- rep(initial_value, n_x)
    } else {
      lb <- rep(0.01,n_x)
      x0 <- rep(initial_value, n_x)
    }
    # Set optimization options.
    opts <- list( "algorithm" = "NLOPT_LN_COBYLA",#"NLOPT_GN_ISRES"
                  "xtol_rel" = 1e-06,
                  "maxeval" = iterations,
                  #"local_opts" = list( "algorithm" = "NLOPT_LN_NELDERMEAD",
                  #                     "xtol_rel" = 1.0e-4 ),
                  "print_level" = 0 )
    
    
    # Use the uniform optimum and dispersed doses, including both bounds.
    stopifnot(n_starts %in% 1:5)
    starts <- list(x0)
    if (n_starts > 1) {
      stopifnot(!static, n_x > 1)
      uniform <- optimize(function(x) eval_f(rep(x, n_x)),
                          c(lb[1], ub[1]), tol = 1e-7)
      initial_doses <- c(uniform$minimum, .25, .75, .01, 1)
      starts <- lapply(initial_doses[seq_len(n_starts)], rep, times = n_x)
    }
    fits <- lapply(starts, function(start) {
      nloptr(x0 = start, eval_f = eval_f, lb = lb, ub = ub,
             eval_g_ineq = eval_g_ineq, opts = opts)
    })
    start_diagnostics <- tibble(
      initial_dose = vapply(starts, `[`, numeric(1), 1),
      objective = vapply(fits, `[[`, numeric(1), "objective"),
      status = vapply(fits, `[[`, integer(1), "status"),
      iterations = vapply(fits, `[[`, integer(1), "iterations"))
    usable <- with(start_diagnostics, status > 0 & is.finite(objective))
    stopifnot(any(usable))
    best <- which.min(ifelse(usable, start_diagnostics$objective, Inf))
    res <- fits[[best]]

    if (static) {
      
      frac_vac <- tibble(age_group = factor(3:9, levels = paste0(3:9), 
                                            labels = colnames(pbc_spread)[3:9]),
                         frac_vac = rep(1, 7), 
                         max_I_day = 0)
    } else {
      frac_vac <- model_fd_dynamic(scenario = scenario,
                                   fd = unroll_x(res$solution),
                                   length_campaign = q,
                                   phi_x = dose_response,
                                   pdeath = pdeath,
                                   objective = objective,
                                   ret = 1,
                                   homogen = homogen_mixing,
                                   rep = recurring,
                                   calc_frac_vac = T)
    }
    
    solution <- tibble(age_group = factor(3:9, levels = paste0(3:9), 
                                          labels = colnames(pbc_spread)[3:9]), 
                       solution = res$solution) %>% 
      left_join(frac_vac, by = "age_group")
    
    list("solution" = solution, 
         "objective" = res$objective,
         "n_iterations" = res$iterations, 
         "message" = res$message,
         "start_diagnostics" = start_diagnostics)
  }
