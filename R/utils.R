# Internal helper: check non-empty scalar character
ai_check_scalar_chr <- function(x, arg = deparse(substitute(x))) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    cli::cli_abort("{.arg {arg}} must be a single non-empty character string.")
  }
  x
}

# Internal helper: safe numeric L2 normalization
ai_l2_normalize <- function(v) {
  v <- as.numeric(v)
  v[!is.finite(v)] <- 0.0
  nrm <- sqrt(sum(v^2))
  if (nrm > 1e-12) v / nrm else v
}
