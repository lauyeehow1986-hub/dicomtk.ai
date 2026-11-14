testthat::test_that("combat_fit and combat_apply remove scanner batch shifts without test-set leakage", {
  set.seed(42L)
  n_feat <- 8L
  n_samp <- 40L
  batch <- factor(rep(c("Scanner_A", "Scanner_B"), each = 20L))
  bio <- rnorm(n_samp)
  mod <- stats::model.matrix(~ bio)

  # Inject scanner location + scale batch effects on noise, preserving biological signal
  noise <- matrix(rnorm(n_feat * n_samp, sd = 0.2), nrow = n_feat, ncol = n_samp)
  noise[, batch == "Scanner_A"] <- noise[, batch == "Scanner_A"] * 2.0 + 5.0
  noise[, batch == "Scanner_B"] <- noise[, batch == "Scanner_B"] * 0.5 - 4.0
  obs_mat <- noise
  obs_mat[1L, ] <- obs_mat[1L, ] + 2.0 * bio

  res <- ai_combat_harmonize(obs_mat, batch = batch, mod = mod, eb = TRUE)
  harm <- res$harmonized
  testthat::expect_equal(dim(harm), dim(obs_mat))

  # Batch mean gap should collapse near 0 while biological correlation stays high
  mean_diff_before <- abs(mean(obs_mat[1L, batch == "Scanner_A"]) - mean(obs_mat[1L, batch == "Scanner_B"]))
  mean_diff_after <- abs(mean(harm[1L, batch == "Scanner_A"]) - mean(harm[1L, batch == "Scanner_B"]))
  testthat::expect_true(mean_diff_after < mean_diff_before * 0.2)
  testthat::expect_true(stats::cor(harm[1L, ], bio) > 0.85)

  # Train/test-safe check: applying fit to 1 test sample gives identical result as applying to 10 test samples
  train_idx <- c(1:15, 21:35)
  test_idx <- c(16:20, 36:40)
  fit_tr <- combat_fit(obs_mat[, train_idx], batch = batch[train_idx], mod = mod[train_idx, , drop = FALSE])
  h_test_all <- combat_apply(fit_tr, obs_mat[, test_idx], batch = batch[test_idx], mod = mod[test_idx, , drop = FALSE])
  h_test_one <- combat_apply(fit_tr, obs_mat[, test_idx[1L], drop = FALSE], batch = batch[test_idx[1L]], mod = mod[test_idx[1L], , drop = FALSE])
  testthat::expect_equal(h_test_all[, 1L], h_test_one[, 1L], tolerance = 1e-10)
})
