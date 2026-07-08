library(deepReveal)

# ==============================================================================
# Tests for: SSD constants
# ==============================================================================

test_that("SG_DBH_BREAKS has 11 elements ending in Inf", {
  expect_length(SG_DBH_BREAKS, 11)
  expect_equal(SG_DBH_BREAKS[1], 8)
  expect_true(is.infinite(SG_DBH_BREAKS[11]))
})

test_that("SG_DBH_MIDPOINTS has 10 elements in ascending order", {
  expect_length(SG_DBH_MIDPOINTS, 10)
  expect_true(all(diff(SG_DBH_MIDPOINTS) > 0))
})

test_that("SG_DBH_THETA equals 8", {
  expect_equal(SG_DBH_THETA, 8L)
})

# ==============================================================================
# Tests for: stand_qmd() and stand_basal_area()
# ==============================================================================

test_that("stand_qmd returns correct QMD from N and BA", {
  dG <- stand_qmd(N_target = 400, BA_target = 28)
  expect_true(is.numeric(dG))
  expect_gt(dG, 0)
  # QMD = sqrt(4 * BA / (pi * N)) * 100; round-trip check
  expected <- sqrt(4 * 28 / (pi * 400)) * 100
  expect_equal(dG, expected, tolerance = 1e-6)
})

test_that("stand_basal_area computes correct BA from absolute SSD", {
  ssd <- generate_ssd_weibull(c_shape = 2.5, N_target = 400, BA_target = 28)
  ba  <- stand_basal_area(ssd)
  expect_true(is.numeric(ba))
  expect_equal(ba, 28, tolerance = 0.5)
})

# ==============================================================================
# Tests for: jsd_divergence()
# ==============================================================================

test_that("jsd_divergence returns 0 for identical distributions", {
  p <- c(0.1, 0.3, 0.4, 0.2)
  expect_equal(jsd_divergence(p, p), 0, tolerance = 1e-9)
})

test_that("jsd_divergence is symmetric", {
  p <- c(0.1, 0.3, 0.4, 0.2)
  q <- c(0.4, 0.2, 0.1, 0.3)
  expect_equal(jsd_divergence(p, q), jsd_divergence(q, p), tolerance = 1e-12)
})

test_that("jsd_divergence is bounded in [0, log(2)]", {
  p <- c(1, 0, 0, 0)
  q <- c(0, 0, 0, 1)
  jsd <- jsd_divergence(p, q)
  expect_gte(jsd, 0)
  expect_lte(jsd, log(2) + 1e-9)
})

test_that("jsd_divergence returns positive value for different distributions", {
  p <- c(0.5, 0.3, 0.2)
  q <- c(0.1, 0.1, 0.8)
  expect_gt(jsd_divergence(p, q), 0)
})

# ==============================================================================
# Tests for: SSD generators — N and BA conservation
# ==============================================================================

test_that("generate_ssd_weibull conserves N and BA within 0.5%", {
  ssd <- generate_ssd_weibull(c_shape = 2.5, N_target = 400, BA_target = 28)
  expect_length(ssd, 10)
  expect_equal(sum(ssd), 400, tolerance = 2)
  expect_equal(stand_basal_area(ssd), 28, tolerance = 0.14)
})

test_that("generate_ssd_reverse_j conserves N and BA within 0.5%", {
  ssd <- generate_ssd_reverse_j(q = 1.3, N_target = 300, BA_target = 20)
  expect_length(ssd, 10)
  expect_equal(sum(ssd), 300, tolerance = 1.5)
  expect_equal(stand_basal_area(ssd), 20, tolerance = 0.10)
})

test_that("generate_ssd_bimodal conserves N and BA within 0.5%", {
  ssd <- generate_ssd_bimodal(r1 = 0.5, r2 = 1.5, N_target = 400, BA_target = 28)
  expect_length(ssd, 10)
  expect_equal(sum(ssd), 400, tolerance = 2)
  expect_equal(stand_basal_area(ssd), 28, tolerance = 0.14)
})

test_that("generators return non-negative stem counts", {
  expect_true(all(generate_ssd_weibull(2.5, 400, 28) >= 0))
  expect_true(all(generate_ssd_reverse_j(1.3, 300, 20) >= 0))
  expect_true(all(generate_ssd_bimodal(r1 = 0.5, r2 = 1.5,
                                       N_target = 400, BA_target = 28) >= 0))
})

# ==============================================================================
# Tests for: classify_ssd()
# ==============================================================================

test_that("classify_ssd returns a list with $category", {
  ssd <- generate_ssd_weibull(c_shape = 2.5, N_target = 400, BA_target = 28)
  result <- classify_ssd(ssd_abs = ssd, stem_number = 400)
  expect_true(is.list(result))
  expect_true("category" %in% names(result))
  expect_true(is.character(result$category))
})

test_that("classify_ssd categorises a geometric-decay SSD as Reverse-J", {
  ssd <- c(400, 200, 100, 50, 20, 10, 5, 2, 1, 0)
  result <- classify_ssd(ssd_abs = ssd, stem_number = 788)
  expect_equal(result$category, "Reverse-J")
})

test_that("classify_ssd categorises a bimodal SSD correctly", {
  ssd <- generate_ssd_bimodal(r1 = 0.5, r2 = 1.5, N_target = 400, BA_target = 28)
  result <- classify_ssd(ssd_abs = ssd, stem_number = 400)
  expect_true(result$category %in% c("Bimodal", "Unimodal", "Reverse-J", "Irregular"))
})

test_that("classify_ssd with very few stems returns Irregular", {
  ssd <- c(5, 3, 1, 0, 1, 0, 0, 0, 0, 0)
  result <- classify_ssd(ssd_abs = ssd, stem_number = 10)
  expect_true(result$category %in% c("Irregular", "Reverse-J", "Unimodal", "Bimodal"))
})

# ==============================================================================
# Tests for: compute_prediction_metrics()
# ==============================================================================

test_that("compute_prediction_metrics returns a one-row tibble with 4 metrics", {
  true_abs <- generate_ssd_weibull(c_shape = 2.5, N_target = 400, BA_target = 28)
  pred_rel <- true_abs / sum(true_abs)
  m <- compute_prediction_metrics(true_abs = true_abs, pred_rel = pred_rel, N_total = 400)
  expect_equal(nrow(m), 1)
  expect_true(all(c("kl", "jsd", "rmse", "r2") %in% names(m)))
})

test_that("compute_prediction_metrics: perfect prediction gives KL≈0, JSD≈0, R²≈1", {
  true_abs <- generate_ssd_weibull(c_shape = 2.5, N_target = 400, BA_target = 28)
  pred_rel <- true_abs / sum(true_abs)
  m <- compute_prediction_metrics(true_abs = true_abs, pred_rel = pred_rel, N_total = 400)
  expect_lt(m$kl,  0.01)
  expect_lt(m$jsd, 0.01)
  expect_gt(m$r2,  0.99)
})

test_that("compute_prediction_metrics: different shape gives positive KL and JSD", {
  true_abs <- generate_ssd_weibull(c_shape = 2.5, N_target = 400, BA_target = 28)
  pred_ssd <- generate_ssd_weibull(c_shape = 4.0, N_target = 400, BA_target = 28)
  pred_rel <- pred_ssd / sum(pred_ssd)
  m <- compute_prediction_metrics(true_abs = true_abs, pred_rel = pred_rel, N_total = 400)
  expect_gt(m$kl,  0)
  expect_gt(m$jsd, 0)
  expect_gte(m$rmse, 0)
})

test_that("compute_prediction_metrics returns NA row when N_total < 1", {
  true_abs <- c(0.1, 0.2, 0.3, 0.2, 0.1, 0.05, 0.02, 0.01, 0.01, 0.01)
  pred_rel <- true_abs / sum(true_abs)
  m <- compute_prediction_metrics(true_abs = true_abs, pred_rel = pred_rel, N_total = 0)
  expect_true(all(is.na(unlist(m))))
})

test_that("compute_prediction_metrics: KL >= 0, JSD in [0, log(2)], RMSE >= 0, R2 <= 1", {
  true_abs <- generate_ssd_reverse_j(q = 1.3, N_target = 300, BA_target = 20)
  pred_ssd <- generate_ssd_weibull(c_shape = 3.0, N_target = 300, BA_target = 20)
  pred_rel <- pred_ssd / sum(pred_ssd)
  m <- compute_prediction_metrics(true_abs = true_abs, pred_rel = pred_rel, N_total = 300)
  expect_gte(m$kl,   0)
  expect_gte(m$jsd,  0)
  expect_lte(m$jsd,  log(2) + 1e-9)
  expect_gte(m$rmse, 0)
  expect_lte(m$r2,   1 + 1e-9)
})
