# =========================================================================
# WORKFLOW SCRIPT FOR BUILDING AND MAINTAINING THE 'deepReveal' R PACKAGE
# =========================================================================

# --- 1. SETUP ---
# Load the essential libraries for package development.
# Run this once per R session when you start working on the package.

library(devtools)
library(roxygen2)
library(usethis)


# --- 2. THE INTERACTIVE DEVELOPMENT CYCLE ---
# These are the commands you will run most frequently while developing.
# Always make sure your R session's working directory is set to the
# root of your 'deepReveal' package project. The easiest way is to open
# the 'deepReveal.Rproj' file in RStudio.

# Load all functions from R/ into memory for interactive testing,
# simulating the behavior of a loaded package.
# Use this after you've changed any function code.
devtools::load_all()

# Run this after you've changed any roxygen2 documentation comments (the #' parts)
# or added/removed imported functions. It updates the NAMESPACE file and
# the help files in the 'man/' directory.
devtools::document()

# build a single, consolidated PDF reference for the package's functions.
devtools::build_manual()

# This is the most important command. It runs a comprehensive series of checks
# to find common problems, similar to what CRAN does. Run this frequently!
# Setting `vignettes = FALSE` makes the check run much faster during development
# by skipping the time-consuming vignette execution.
devtools::check(vignettes = FALSE)

# --- 3. WORKING WITH THE VIGNETTE ---
# The vignette is a tutorial for your users. The code inside it must run flawlessly
# for the package to be built correctly for distribution (like on CRAN).

# To test ONLY the vignette without running all other checks:
# This command will try to execute all code chunks in your .Rmd file
# and build the final HTML. If there's an error, it will stop and tell you
# which code chunk failed and why. This is the best way to debug the vignette.
devtools::build_vignettes()

# ---- How to handle `eval = TRUE` vs `eval = FALSE` in your vignette ----
#
# Your vignette's setup chunk looks like this:
#
#   ```{r setup, include = FALSE}
#   knitr::opts_chunk$set(
#     collapse = TRUE,
#     comment = "#>",
#     eval = FALSE  # <---- THIS IS THE KEY
#   )
#   ```
#
# a) For day-to-day development (`eval = FALSE`):
#    Keep `eval = FALSE`. This allows you to run `devtools::check()` quickly.
#    It will still check your R code in the vignette for syntax errors, but it
#    won't actually run it. This is perfect for when you're working on other
#    parts of the package.
#
# b) When you want to test the vignette (`eval = TRUE`):
#    1. Change the setup chunk in your .Rmd file to `eval = TRUE`.
#    2. Run `devtools::build_vignettes()` from the console.
#    3. This will execute all the code. If it works, you'll see the rendered
#       HTML file in your `doc/` folder. If it fails, the console will show an error.
#
# c) Common reasons for vignette failure (and how to fix them):
#    - **Missing Dependency:** If you use a function from a package (e.g., `ggplot2`)
#      in the vignette, that package MUST be listed in your `DESCRIPTION` file.
#      Run `usethis::use_package("packagename", type = "Suggests")` to add it.
#      It's best to put packages only used in vignettes in `Suggests:`.
#    - **Incorrect File Path:** Never use a local path like `C:/...`. Always
#      load your example model from `inst/extdata/` using:
#      `system.file("extdata", "deepReveal_example_model.keras", package = "deepReveal")`
#    - **Code Takes Too Long:** For the feature set sensitivity analysis
#      (`run_feature_set_sensitivity_training`), which is very slow, you should
#      keep that specific code chunk with the option `{r run-fs-training, eval=FALSE}`.
#      To show the results (like the heatmap), you can pre-compute them once,
#      save the results object (e.g., `fs_sensitivity_results.rda`) in your
#      package's `data/` folder using `usethis::use_data()`, and then have the
#      vignette `load()` and plot those pre-computed results. This shows the full
#      workflow without the prohibitive runtime.
#
# !! IMPORTANT: Your old workflow of manually copying the HTML file into the
# package archive is not a standard practice and will cause the package to fail
# CRAN checks. The goal should always be to fix the underlying errors so that the
# vignette builds correctly with `devtools`.


# --- 4. FINAL BUILD AND INSTALLATION ---

# When your package passes devtools::check() and the vignette builds correctly,
# you are ready to create the final package file.

# This creates the distributable package file (e.g., 'deepReveal_0.1.0.tar.gz').
# By default, this command will also build the vignette.
devtools::build()

# To install the package on your own system from the local source files
# so you can use it like any other package (`library(deepReveal)`).
devtools::install()

