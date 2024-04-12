as.pct <- function(x, dig=1) 
  paste0(format(round(100 * (x), dig), nsmall = dig), "%")