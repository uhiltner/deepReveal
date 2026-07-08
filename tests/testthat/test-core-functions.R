library(deepReveal)

# ==============================================================================
# Tests for: kl_divergence_metric()
# These tests require only the 'philentropy' package (no keras/Python needed).
# ==============================================================================

test_that("kl_divergence_metric returns a single numeric for identical distributions", {
  y <- matrix(c(10, 20, 30, 40), nrow = 1)
  result <- kl_divergence_metric(y, y)
  expect_true(is.numeric(result))
  expect_length(result, 1)
  # Identical distributions should yield KL divergence near 0
  expect_lt(result, 0.01)
})

test_that("kl_divergence_metric returns a positive value for different distributions", {
  true_y <- matrix(c(100, 0, 0, 0), nrow = 1)
  pred_y <- matrix(c(0, 0, 0, 100), nrow = 1)
  result <- kl_divergence_metric(true_y, pred_y)
  expect_true(is.numeric(result))
  expect_gt(result, 0)
})

test_that("kl_divergence_metric returns NA for empty input", {
  result <- kl_divergence_metric(matrix(nrow = 0, ncol = 4), matrix(nrow = 0, ncol = 4))
  expect_true(is.na(result))
})

test_that("kl_divergence_metric raises error on dimension mismatch", {
  true_y <- matrix(1:4, nrow = 1)
  pred_y <- matrix(1:6, nrow = 1)
  expect_error(kl_divergence_metric(true_y, pred_y), "Dimensions")
})

test_that("kl_divergence_metric handles matrix input with multiple rows", {
  true_y <- matrix(c(10, 20, 30, 40, 5, 50, 5, 40), nrow = 2, byrow = TRUE)
  pred_y <- matrix(c(10, 22, 28, 40, 6, 49, 5, 40), nrow = 2, byrow = TRUE)
  result <- kl_divergence_metric(true_y, pred_y)
  expect_true(is.numeric(result))
  expect_length(result, 1)
  expect_gte(result, 0)
})

test_that("kl_divergence_metric issues warning for negative values", {
  y_neg <- matrix(c(-1, 20, 30, 40), nrow = 1)
  y_pos <- matrix(c(10, 20, 30, 40), nrow = 1)
  expect_warning(kl_divergence_metric(y_neg, y_pos))
})

test_that("kl_divergence_metric accepts vector input (coerces to matrix)", {
  y <- c(10, 20, 30, 40)
  result <- kl_divergence_metric(y, y)
  expect_true(is.numeric(result))
  expect_lt(result, 0.01)
})

# ==============================================================================
# Tests for: permutation_feature_importance() — input validation only
# (No keras model loading; tests only the guard clauses that do not require
#  a Python environment.)
# ==============================================================================

test_that("permutation_feature_importance errors when metric_function is missing", {
  expect_error(
    permutation_feature_importance(
      model_path      = "fake_model.keras",
      model_data_path = "fake_data.RData",
      model_data_name = "fake_obj",
      input_feature_set = "full.inputs"
      # metric_function intentionally omitted
    ),
    "`metric_function` must be a function"
  )
})

test_that("permutation_feature_importance errors when n_permutations is invalid", {
  expect_error(
    permutation_feature_importance(
      model_path        = "fake.keras",
      model_data_path   = "fake.RData",
      model_data_name   = "obj",
      input_feature_set = "full.inputs",
      metric_function   = function(a, b) mean(abs(a - b)),
      n_permutations    = 0
    ),
    "`n_permutations` must be a single positive integer"
  )
})

test_that("permutation_feature_importance errors when plot_save_path missing but plot_filename given", {
  expect_error(
    permutation_feature_importance(
      model_path        = "fake.keras",
      model_data_path   = "fake.RData",
      model_data_name   = "obj",
      input_feature_set = "full.inputs",
      metric_function   = function(a, b) mean(abs(a - b)),
      plot_filename     = "output.pdf"
      # plot_save_path intentionally omitted
    ),
    "`plot_save_path` must be provided"
  )
})

# ==============================================================================
# Tests for: deepReveal_example_data (bundled data integrity)
# ==============================================================================

test_that("deepReveal_example_data loads and has the correct structure", {
  data("deepReveal_example_data", package = "deepReveal")
  obj <- deepReveal_example_data
  expect_true(is.list(obj))
  expect_true(all(c("train_data", "val_data", "test_data",
                    "input_features", "target_features",
                    "top_seed", "top_model_predictions",
                    "top_model_metrics") %in% names(obj)))
})

test_that("deepReveal_example_data has correct split sizes", {
  data("deepReveal_example_data", package = "deepReveal")
  obj <- deepReveal_example_data
  expect_equal(nrow(obj$train_data), 387)
  expect_equal(nrow(obj$val_data),    26)
  expect_equal(nrow(obj$test_data),   70)
})

test_that("deepReveal_example_data has correct feature counts", {
  data("deepReveal_example_data", package = "deepReveal")
  obj <- deepReveal_example_data
  expect_equal(length(obj$input_features),  37)
  expect_equal(length(obj$target_features), 10)
})

test_that("deepReveal_example_data target features contain expected DBH class names", {
  data("deepReveal_example_data", package = "deepReveal")
  obj <- deepReveal_example_data
  expect_true(all(grepl("^stems\\.ha_dbhclass", obj$target_features)))
})

test_that("bundled example keras model file exists in inst/extdata", {
  model_path <- system.file("extdata", "deepReveal_example_model.keras",
                            package = "deepReveal")
  expect_true(nchar(model_path) > 0)
  expect_true(file.exists(model_path))
})
