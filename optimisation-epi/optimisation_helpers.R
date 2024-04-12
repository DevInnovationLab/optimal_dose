
# For multi-year runs, willingness to vaccinate will change in subsequent years
# This specifies hesitancy in a format that the ODE solver can then use
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