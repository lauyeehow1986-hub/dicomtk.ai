# Internal: initialize default pluggable AI backend registry
.ai_init_default_backends <- function() {
  reg <- new.env(parent = emptyenv())
  .ai_env$backends <- reg

  defaults <- list(
    list(name = "totalsegmentator", task = "segmentation", mode = "offline",
         endpoint = Sys.getenv("DICOMTK_TOTALSEG_URL", "http://127.0.0.1:8001")),
    list(name = "nnunet", task = "segmentation", mode = "offline",
         endpoint = Sys.getenv("DICOMTK_NNUNET_URL", "http://127.0.0.1:8002")),
    list(name = "vista3d", task = "segmentation", mode = "offline",
         endpoint = Sys.getenv("DICOMTK_VISTA3D_URL", "http://127.0.0.1:8003")),
    list(name = "medsam2", task = "segmentation", mode = "offline",
         endpoint = Sys.getenv("DICOMTK_MEDSAM2_URL", "http://127.0.0.1:8004")),
    list(name = "presidio", task = "nlp_deid", mode = "offline",
         endpoint = Sys.getenv("DICOMTK_PRESIDIO_URL", "http://127.0.0.1:5002")),
    list(name = "ocr", task = "ocr", mode = "offline",
         endpoint = "local://tesseract"),
    list(name = "embeddings", task = "embedding", mode = "offline",
         endpoint = Sys.getenv("DICOMTK_EMBED_URL", "http://127.0.0.1:8005"))
  )

  for (d in defaults) {
    register_ai_backend(
      name = d$name,
      task = d$task,
      mode = d$mode,
      endpoint = d$endpoint
    )
  }
  invisible(TRUE)
}

#' Register a Pluggable AI Backend
#'
#' Registers or updates an AI model backend (segmentation, NLP de-identification,
#' OCR, or embedding extraction) in the session registry.
#'
#' @param name Unique backend identifier (e.g., `"totalsegmentator"`,
#'   `"medsam2"`, `"presidio"`).
#' @param task Task category: `"segmentation"`, `"nlp_deid"`, `"ocr"`, or
#'   `"embedding"`.
#' @param mode Execution mode: `"offline"` (deterministic local engine) or
#'   `"rest"` (HTTP endpoint via `httr2`).
#' @param endpoint Base URL or local URI for the backend.
#' @param predict_fn Optional custom `function(input, backend, ...)` override.
#' @param headers Optional named character vector of HTTP headers.
#'
#' @return Invisibly returns the registered `dicom_ai_backend` object.
#' @export
register_ai_backend <- function(name,
                                task = c("segmentation", "nlp_deid", "ocr", "embedding"),
                                mode = c("offline", "rest"),
                                endpoint = NULL,
                                predict_fn = NULL,
                                headers = character(0)) {
  ai_check_scalar_chr(name, "name")
  task <- match.arg(task)
  mode <- match.arg(mode)
  if (is.null(.ai_env$backends)) {
    .ai_env$backends <- new.env(parent = emptyenv())
  }
  if (!is.null(predict_fn) && !is.function(predict_fn)) {
    cli::cli_abort("{.arg predict_fn} must be a function when provided.")
  }

  spec <- structure(
    list(
      name = tolower(name),
      task = task,
      mode = mode,
      endpoint = endpoint %||% "",
      predict_fn = predict_fn,
      headers = headers
    ),
    class = "dicom_ai_backend"
  )
  assign(tolower(name), spec, envir = .ai_env$backends)
  invisible(spec)
}

#' Retrieve a Registered AI Backend
#'
#' @param name Backend name (case-insensitive).
#' @return A `dicom_ai_backend` object.
#' @export
get_ai_backend <- function(name) {
  ai_check_scalar_chr(name, "name")
  if (is.null(.ai_env$backends)) {
    .ai_init_default_backends()
  }
  key <- tolower(name)
  if (!exists(key, envir = .ai_env$backends, inherits = FALSE)) {
    cli::cli_abort("Unknown AI backend {.val {name}}. Use {.fn list_ai_backends} to inspect available backends.")
  }
  get(key, envir = .ai_env$backends, inherits = FALSE)
}

#' List Registered AI Backends
#'
#' @param task Optional task filter (`"segmentation"`, `"nlp_deid"`, `"ocr"`,
#'   or `"embedding"`).
#' @return A [tibble::tibble] summarizing registered backends.
#' @examples
#' list_ai_backends()
#' @export
list_ai_backends <- function(task = NULL) {
  if (is.null(.ai_env$backends)) {
    .ai_init_default_backends()
  }
  keys <- sort(ls(envir = .ai_env$backends))
  if (length(keys) == 0L) {
    return(tibble::tibble(
      name = character(0),
      task = character(0),
      mode = character(0),
      endpoint = character(0)
    ))
  }
  rows <- lapply(keys, function(k) {
    b <- get(k, envir = .ai_env$backends, inherits = FALSE)
    tibble::tibble(
      name = b$name,
      task = b$task,
      mode = b$mode,
      endpoint = b$endpoint
    )
  })
  tbl <- do.call(rbind, rows)
  if (!is.null(task)) {
    tbl <- tbl[tbl$task %in% task, , drop = FALSE]
  }
  tbl
}

#' Check Health of a Registered AI Backend
#'
#' Probes a registered backend's readiness (`"offline_ready"` for offline
#' backends, or HTTP GET `/health` / base URL for REST backends).
#'
#' @param name Backend name.
#' @param timeout_sec HTTP timeout in seconds for REST backends (default `3`).
#' @return A list with `name`, `mode`, `status`, and `endpoint`.
#' @export
ai_backend_health <- function(name, timeout_sec = 3) {
  b <- get_ai_backend(name)
  if (identical(b$mode, "offline")) {
    return(list(
      name = b$name,
      mode = b$mode,
      status = "offline_ready",
      endpoint = b$endpoint
    ))
  }

  ok <- tryCatch({
    resp <- httr2::request(b$endpoint) |>
      httr2::req_timeout(timeout_sec) |>
      httr2::req_error(is_error = function(resp) FALSE) |>
      httr2::req_perform()
    httr2::resp_status(resp) < 500L
  }, error = function(e) FALSE)

  list(
    name = b$name,
    mode = b$mode,
    status = if (isTRUE(ok)) "healthy" else "unreachable",
    endpoint = b$endpoint
  )
}
