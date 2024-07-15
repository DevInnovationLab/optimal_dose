# Basic packages
library(tidyverse)
library(ggpubr)
library(latex2exp)
library(shades) 
library(grid)
library(assertthat)
# Optimization packages
library(nloptr)
library(odin)
library(furrr)

# Parametrization and basic helper functions
source("setup/model_2vaccine.R")
source("optimisation-epi/single_run.R")
source("setup/parametrisation.R")
source("setup/plot_rcs.R")
source("setup/helpers.R")

# Optimization functions
source("optimisation-epi/nlopt_helpers.R")
source("optimisation-epi/nlopt_obj_fun.R")
source("optimisation-epi/nlopt_general.R")

# Visualization functions
source("optimisation-epi/nlopt_plot.R")



