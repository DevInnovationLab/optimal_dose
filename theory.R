############################################################
##  Optimal fractional-dosing toy model (sigmoidal φ)     ##
############################################################
# Packages -------------------------------------------------
if (!requireNamespace("nloptr", quietly = TRUE))
  install.packages("nloptr")
library(nloptr)

# 1. Global parameters ------------------------------------
N       <- 1            # total population to vaccinate
p       <- 10           # price per unit antigen (==0 ⇒ social-welfare objective)
A_b     <- 500           # scale for B(·)
gamma_b <- 3            # concavity for B(·)
sigma_s <- 50           # linear side-effect slope; set >0 to penalise large doses
k_phi   <- 5           # steepness of sigmoid
xi_phi  <- 0.5          # inflection point
full_dose <- 1          # developer’s "standard" dose; sets Q-grid upper bound

# 2. Model primitives -------------------------------------
phi   <- function(x) 1 / (1 + exp(-k_phi * (x - xi_phi)))        # efficacy φ(x)
# s     <- function(x) sigma_s * x                               # linear side-effects  s(x)
# s     <- function(x) sigma_s*(1 - exp(-5*x))                   # concave side-effects  s(x)
s     <- function(x) sigma_s*exp(5*(x-1))                        # convex side-effects  s(x)
g     <- function(x) s(x) + p*x                                  # generalised cost g(x)
B     <- function(v) A_b * (1 - exp(-gamma_b * v))               # social benefit B(v)
# v = n*phi(x)

# 3. Objective & constraints for nloptr --------------------
obj <- function(vars, pars) {
  n <- vars[1]; x <- vars[2]
  
  # guard against NA / ±Inf that nloptr occasionally feeds in
  if (any(!is.finite(c(n, x))))            return(1e20)
  
  # no need to repeat the constraints here (COBYLA enforces them)
  - ( B(n * phi(x)) - n * g(x) )           # nloptr minimises
}

g_ineq <- function(vars, pars) {            # ≤0 for feasibility
  n <- vars[1]; x <- vars[2]
  with(pars, c( n*x - Q , n - N ))          # supply, population
}

# 4. Solver wrapper ---------------------------------------
solve_one_Q <- function(Q, start=c(N/2, full_dose/2)) {
  pars <- list(Q=Q, N=N)
  res  <- nloptr(x0     = start,
                 eval_f = obj,
                 eval_g_ineq = g_ineq,
                 lb     = c(0,0),
                 opts   = list(algorithm="NLOPT_LN_COBYLA",
                               xtol_rel = 1e-8,
                               maxeval  = 500),
                 pars   = pars)
  list(Q=Q, n_star = res$solution[1], x_star = res$solution[2],
       objective = -res$objective)
}

# 5. Run across a grid of supply constraints ---------------
Q_grid <- seq(N*full_dose/100, N*full_dose, length.out = 100)
results <- lapply(Q_grid, solve_one_Q)
results_df <- do.call(rbind, lapply(results, as.data.frame))

# 6. Inspect / plot ---------------------------------------
print(head(results_df, 8))

# Optional quick plots (comment out if not needed)
par(mfrow = c(2,3))
plot(results_df$Q, results_df$x_star, type="l",
     xlab="Total antigen available (Q)", ylab="Optimal dose x*",
     main="Optimal dose vs. supply constraint",
     ylim = c(0,1))
plot(results_df$Q, results_df$n_star, type="l",
     xlab="Total antigen available (Q)", ylab="People vaccinated n*",
     main="Coverage vs. supply constraint",
     ylim = c(0,1))
curve(phi(x), 0, full_dose, n = 200, xlab = "dose x", ylab = "φ(x)", main = "Efficacy φ(x)")
curve(s(x), 0, full_dose, n = 200, xlab = "dose x", ylab = "s(x)", main = "Side‑effects s(x)")
curve(g(x), 0, full_dose, n = 200, xlab = "dose x", ylab = "g(x)", main = "Generalised cost g(x)")
curve(B, from = 0, to = 1, n = 200, xlab = "effective coverage v", ylab = "B(v)", main = "Benefit B(v)")

par(mfrow = c(1, 1))   # reset layout
