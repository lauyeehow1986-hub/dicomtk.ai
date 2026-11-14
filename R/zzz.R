.ai_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  .ai_init_default_backends()
  invisible(NULL)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
