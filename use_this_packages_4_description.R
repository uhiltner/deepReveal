# Core tidyverse packages for data manipulation
usethis::use_package("dplyr")
usethis::use_package("tidyr")
usethis::use_package("stringr")
usethis::use_package("readr")
usethis::use_package("magrittr") # For the pipe %>%

# Plotting packages
usethis::use_package("ggplot2")
usethis::use_package("cowplot")
usethis::use_package("viridis")
usethis::use_package("RColorBrewer")

# Modeling and metrics packages
usethis::use_package("keras3")
usethis::use_package("philentropy")
usethis::use_package("entropy", type = "Imports")
usethis::use_package("Metrics")

# Helper packages for programming
usethis::use_package("rlang") # For using .data in ggplot2

