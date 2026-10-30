# Calibrate unvaccinated epidemic scenarios by their attack rate and peak time.
# The common outcome horizon is day 360; a longer run locates the peak and tail.

calibration_solver <- list(rtol = 1e-9, atol = 1e-18, maxsteps = 100000)

epidemic_parameters <- function(r0_value, seed) {
  pars <- pars_base
  pars$q <- rep(r0_value / (5 * ev), Ngroups)
  pars$y0[1, ] <- 1 - seed
  pars$y0[2, ] <- seed
  pars
}

epidemic_outcomes <- function(pars, pop_sizes = pop) {
  pars$Ndays <- 730
  y <- do.call(sr, c(list(pars = pars), calibration_solver))
  y <- rescale_rcs(y, pop_sizes, TRUE)
  infectious <- y[, "I", 1]
  peak <- which.max(infectious)
  peak_time <- if (peak %in% c(1, 730)) peak else {
    optimize(splinefun(1:730, infectious), c(peak - 1, peak + 1),
             maximum = TRUE, tol = 1e-6)$maximum
  }
  tibble(peak_day = peak_time, peak_months = peak_time / 30.5,
    attack_360 = y[360, "cumI", 1], attack_final = y[730, "cumI", 1],
    no_vaccine_deaths = y[360, "D", 1])
}

calibrate_exposure <- function(r0_value, peak_months) {
  fit <- uniroot(function(log_seed) {
    epidemic_outcomes(epidemic_parameters(r0_value, exp(log_seed)))$peak_day -
      30.5 * peak_months
  }, log(c(1e-20, .2)), tol = 1e-8)
  exp(fit$root)
}

calibrate_epidemic <- function(attack_target, peak_months) {
  fit <- uniroot(function(r0_value) {
    epidemic_outcomes(epidemic_parameters(r0_value, calibrate_exposure(r0_value, peak_months)))$
      attack_360 - attack_target
  }, c(1.08, 2.7), tol = 1e-7)
  seed <- calibrate_exposure(fit$root, peak_months)
  outcomes <- epidemic_outcomes(epidemic_parameters(fit$root, seed))
  stopifnot(abs(outcomes$attack_360 - attack_target) < 1e-5,
    abs(outcomes$peak_months - peak_months) < .01)
  bind_cols(tibble(r0_value = fit$root, seed = seed,
    target_attack = attack_target, target_peak_months = peak_months), outcomes)
}
