.eb_it_sol <- function(sdat, g_hat, d_hat, g_bar, t2, a, b, conv = 1e-4) {
  n <- rowSums(!is.na(sdat))
  g_old <- g_hat
  d_old <- d_hat
  change <- 1
  iter <- 0L
  while (change > conv && iter < 200L) {
    g_new <- (t2 * n * g_hat + d_old * g_bar) / (t2 * n + d_old)
    sum2 <- rowSums((sdat - g_new)^2, na.rm = TRUE)
    d_new <- (0.5 * sum2 + b) / (n / 2 + a - 1)
    change <- max(
      max(abs(g_new - g_old) / pmax(abs(g_old), 1e-8), na.rm = TRUE),
      max(abs(d_new - d_old) / pmax(abs(d_old), 1e-8), na.rm = TRUE)
    )
    g_old <- g_new
    d_old <- d_new
    iter <- iter + 1L
  }
  list(gamma_star = g_new, delta_star = pmax(d_new, 1e-8))
}

#' Fit Train/Test-Safe Empirical Bayes ComBat Harmonisation Parameters
#'
#' Estimates batch location and scale parameters on a training cohort while
#' preserving biological covariates (`mod`). Apply the resulting fit to
#' training or held-out test cohorts with [combat_apply()] without test-set
#' leakage.
#'
#' @param features Numeric matrix (`n_features x n_samples`).
#' @param batch Factor or character vector of scanner/site batch labels of
#'   length `ncol(features)`.
#' @param mod Optional biological covariate design matrix (`n_samples x q`,
#'   e.g. from `model.matrix(~ age + sex)`).
#' @param eb Logical; if `TRUE` (default), applies Empirical Bayes shrinkage
#'   across features.
#' @param ref_batch Optional reference batch name.
#'
#' @return An S3 `"dicom_combat_fit"` object.
#' @export
combat_fit <- function(features,
                       batch,
                       mod = NULL,
                       eb = TRUE,
                       ref_batch = NULL) {
  features <- as.matrix(features)
  storage.mode(features) <- "double"
  batch <- droplevels(as.factor(batch))
  if (length(batch) != ncol(features)) {
    rlang::abort("`length(batch)` must equal `ncol(features)`.")
  }
  b_levels <- levels(batch)
  n_batch <- length(b_levels)
  n_samp <- ncol(features)
  n_feat <- nrow(features)

  batch_mod <- stats::model.matrix(~ -1 + batch)
  colnames(batch_mod) <- b_levels

  mod_clean <- NULL
  keep_mod_cols <- integer(0)
  if (!is.null(mod)) {
    mod <- as.matrix(mod)
    if (nrow(mod) != n_samp) {
      rlang::abort("`nrow(mod)` must equal `ncol(features)`.")
    }
    # Drop constant intercept column if present so design stays full-rank with batch_mod
    is_const <- apply(mod, 2L, function(col) stats::sd(col) == 0)
    if (any(!is_const)) {
      keep_mod_cols <- which(!is_const)
      mod_clean <- mod[, keep_mod_cols, drop = FALSE]
    }
  }

  design <- if (!is.null(mod_clean)) cbind(batch_mod, mod_clean) else batch_mod
  b_hat <- solve(crossprod(design), tcrossprod(t(design), features))

  batches <- lapply(b_levels, function(lvl) which(batch == lvl))
  n_batches <- vapply(batches, length, integer(1L))

  if (!is.null(ref_batch) && (ref_batch %in% b_levels)) {
    ref_idx <- match(ref_batch, b_levels)
    grand_mean <- b_hat[ref_idx, ]
  } else {
    grand_mean <- as.numeric(crossprod(n_batches / n_samp, b_hat[seq_len(n_batch), , drop = FALSE]))
  }

  stand_mean <- matrix(grand_mean, nrow = n_feat, ncol = n_samp)
  beta_mod <- if (!is.null(mod_clean)) b_hat[-seq_len(n_batch), , drop = FALSE] else NULL
  mod_effect <- if (!is.null(beta_mod)) t(mod_clean %*% beta_mod) else matrix(0, nrow = n_feat, ncol = n_samp)

  resid_full <- features - t(design %*% b_hat)
  var_pooled <- pmax(rowMeans(resid_full^2, na.rm = TRUE), 1e-8)
  s_data <- (features - stand_mean - mod_effect) / sqrt(var_pooled)

  gamma_hat <- matrix(0, nrow = n_batch, ncol = n_feat)
  delta_hat <- matrix(1, nrow = n_batch, ncol = n_feat)
  for (i in seq_len(n_batch)) {
    sub <- s_data[, batches[[i]], drop = FALSE]
    gamma_hat[i, ] <- rowMeans(sub, na.rm = TRUE)
    delta_hat[i, ] <- if (ncol(sub) > 1L) apply(sub, 1L, stats::var, na.rm = TRUE) else rep(1, n_feat)
  }
  delta_hat[!is.finite(delta_hat) | delta_hat <= 0] <- 1e-4

  if (isTRUE(eb) && n_feat > 1L) {
    gamma_bar <- rowMeans(gamma_hat, na.rm = TRUE)
    t2 <- apply(gamma_hat, 1L, stats::var, na.rm = TRUE)
    t2[!is.finite(t2) | t2 <= 0] <- 1e-4
    a_prior <- apply(delta_hat, 1L, function(d) {
      m <- mean(d); s2 <- stats::var(d)
      if (!is.finite(s2) || s2 <= 0) 2 else (2 * s2 + m^2) / s2
    })
    b_prior <- apply(delta_hat, 1L, function(d) {
      m <- mean(d); s2 <- stats::var(d)
      if (!is.finite(s2) || s2 <= 0) 1 else (m * s2 + m^3) / s2
    })

    gamma_star <- gamma_hat
    delta_star <- delta_hat
    for (i in seq_len(n_batch)) {
      sol <- .eb_it_sol(
        s_data[, batches[[i]], drop = FALSE],
        gamma_hat[i, ], delta_hat[i, ],
        gamma_bar[i], t2[i], a_prior[i], b_prior[i]
      )
      gamma_star[i, ] <- sol$gamma_star
      delta_star[i, ] <- sol$delta_star
    }
  } else {
    gamma_star <- gamma_hat
    delta_star <- delta_hat
  }

  if (!is.null(ref_batch) && (ref_batch %in% b_levels)) {
    ref_idx <- match(ref_batch, b_levels)
    gamma_star[ref_idx, ] <- 0
    delta_star[ref_idx, ] <- 1
  }

  rownames(gamma_star) <- b_levels
  rownames(delta_star) <- b_levels

  structure(
    list(
      batch_levels = b_levels,
      grand_mean = grand_mean,
      var_pooled = var_pooled,
      beta_mod = beta_mod,
      keep_mod_cols = keep_mod_cols,
      gamma_star = gamma_star,
      delta_star = delta_star,
      ref_batch = ref_batch,
      n_features = n_feat
    ),
    class = "dicom_combat_fit"
  )
}

#' Apply Fitted ComBat Harmonisation Parameters Without Test-Set Leakage
#'
#' @param fit A `"dicom_combat_fit"` from [combat_fit()].
#' @param features Numeric matrix (`n_features x n_samples`).
#' @param batch Factor or character vector of batch labels matching `fit$batch_levels`.
#' @param mod Optional biological covariate matrix (`n_samples x q`).
#'
#' @return Harmonized numeric matrix of dimensions `dim(features)`.
#' @export
combat_apply <- function(fit, features, batch, mod = NULL) {
  if (!inherits(fit, "dicom_combat_fit")) {
    rlang::abort("`fit` must be a `dicom_combat_fit` object.")
  }
  features <- as.matrix(features)
  storage.mode(features) <- "double"
  if (nrow(features) != fit$n_features) {
    rlang::abort("`nrow(features)` does not match `fit$n_features`.")
  }
  batch <- as.character(batch)
  n_samp <- ncol(features)
  if (length(batch) != n_samp) {
    rlang::abort("`length(batch)` must equal `ncol(features)`.")
  }

  mod_effect <- matrix(0, nrow = fit$n_features, ncol = n_samp)
  if (!is.null(fit$beta_mod) && !is.null(mod) && length(fit$keep_mod_cols) > 0L) {
    mod <- as.matrix(mod)
    mod <- mod[, fit$keep_mod_cols, drop = FALSE]
    mod_effect <- t(mod %*% fit$beta_mod)
  }

  stand_mean <- matrix(fit$grand_mean, nrow = fit$n_features, ncol = n_samp)
  s_data <- (features - stand_mean - mod_effect) / sqrt(fit$var_pooled)

  bayes_data <- s_data
  for (lvl in unique(batch)) {
    if (!(lvl %in% fit$batch_levels)) {
      rlang::abort(paste0("Unseen batch level '", lvl, "' in combat_apply()."))
    }
    idx <- which(batch == lvl)
    b_idx <- match(lvl, fit$batch_levels)
    g <- fit$gamma_star[b_idx, ]
    d <- sqrt(fit$delta_star[b_idx, ])
    bayes_data[, idx] <- (s_data[, idx, drop = FALSE] - g) / d
  }

  out <- bayes_data * sqrt(fit$var_pooled) + stand_mean + mod_effect
  dimnames(out) <- dimnames(features)
  out
}

#' Fit and Apply Empirical Bayes ComBat Harmonisation
#'
#' @inheritParams combat_fit
#' @return A list with `harmonized` (harmonized matrix) and `fit`
#'   (`"dicom_combat_fit"`).
#' @examples
#' set.seed(1)
#' mat <- matrix(rnorm(40), nrow = 4, ncol = 10)
#' b <- rep(c("A", "B"), each = 5)
#' res <- ai_combat_harmonize(mat, b)
#' dim(res$harmonized)
#' @export
ai_combat_harmonize <- function(features,
                                batch,
                                mod = NULL,
                                eb = TRUE,
                                ref_batch = NULL) {
  fit <- combat_fit(features, batch = batch, mod = mod, eb = eb, ref_batch = ref_batch)
  harm <- combat_apply(fit, features, batch = batch, mod = mod)
  list(harmonized = harm, fit = fit)
}
