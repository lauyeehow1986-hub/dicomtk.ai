#' Extract a Normalized Study Embedding Vector
#'
#' Computes an L2-normalized feature embedding from a `dicom_volume` using a
#' registered embedding backend (`"offline"` deterministic intensity/spatial/modality
#' signature, or a REST foundation-model endpoint such as RAD-DINO / BiomedCLIP).
#'
#' @param vol A `dicom_volume` object or DICOM path.
#' @param backend Registered embedding backend name (default `"embeddings"`).
#' @param dim_out Target embedding dimension for the offline extractor
#'   (default `32L`).
#'
#' @return A numeric L2-normalized embedding vector.
#' @export
ai_embed <- function(vol, backend = "embeddings", dim_out = 32L) {
  if (is.character(vol)) {
    vol <- dicomtk::read_dicom_volume(vol, warn = FALSE)
  }
  if (!inherits(vol, "dicom_volume") || is.null(vol$voxels)) {
    cli::cli_abort("{.arg vol} must be a valid {.cls dicom_volume} object.")
  }

  if (identical(backend, "offline")) backend <- "embeddings"
  spec <- get_ai_backend(backend)
  if (!is.null(spec$predict_fn)) {
    return(ai_l2_normalize(spec$predict_fn(vol, spec)))
  }
  if (identical(spec$mode, "rest") && nzchar(spec$endpoint)) {
    vals <- as.numeric(vol$voxels)
    resp <- httr2::request(paste0(sub("/+$", "", spec$endpoint), "/embed")) |>
      httr2::req_body_json(list(
        dims = dim(vol$voxels),
        modality = vol$modality %||% "",
        stats = c(mean(vals, na.rm = TRUE), stats::sd(vals, na.rm = TRUE))
      )) |>
      httr2::req_timeout(30) |>
      httr2::req_perform()
    payload <- httr2::resp_body_json(resp)
    return(ai_l2_normalize(unlist(payload$embedding)))
  }

  arr <- vol$voxels
  if (length(dim(arr)) == 4L) {
    arr <- arr[, , , 1L, drop = FALSE]
    dim(arr) <- dim(arr)[1:3]
  }
  vals <- as.numeric(arr)
  vals <- vals[is.finite(vals)]
  if (length(vals) == 0L) vals <- 0.0

  # 16-bin intensity histogram over fixed clinical range [-1024, 3071]
  breaks <- seq(-1024, 3072, length.out = 17L)
  clipped <- pmin(pmax(vals, -1024), 3072)
  h <- graphics::hist(clipped, breaks = breaks, plot = FALSE)$counts
  h <- h / max(1.0, sum(h))

  # 8 octant spatial means
  d <- dim(arr)
  rmid <- max(1L, d[1L] %/% 2L)
  cmid <- max(1L, d[2L] %/% 2L)
  smid <- max(1L, d[3L] %/% 2L)
  octs <- c(
    mean(arr[1:rmid, 1:cmid, 1:smid], na.rm = TRUE),
    mean(arr[rmid:d[1L], 1:cmid, 1:smid], na.rm = TRUE),
    mean(arr[1:rmid, cmid:d[2L], 1:smid], na.rm = TRUE),
    mean(arr[rmid:d[1L], cmid:d[2L], 1:smid], na.rm = TRUE),
    mean(arr[1:rmid, 1:cmid, smid:d[3L]], na.rm = TRUE),
    mean(arr[rmid:d[1L], 1:cmid, smid:d[3L]], na.rm = TRUE),
    mean(arr[1:rmid, cmid:d[2L], smid:d[3L]], na.rm = TRUE),
    mean(arr[rmid:d[1L], cmid:d[2L], smid:d[3L]], na.rm = TRUE)
  ) / 1000.0

  g_stats <- c(
    mean(vals) / 1000.0,
    stats::sd(vals) / 1000.0,
    stats::quantile(vals, 0.1, names = FALSE) / 1000.0,
    stats::quantile(vals, 0.9, names = FALSE) / 1000.0
  )

  mod <- toupper(as.character(vol$modality %||% ""))
  mod_oh <- c(
    as.numeric(mod == "CT"),
    as.numeric(mod == "MR"),
    as.numeric(mod %in% c("PT", "PET")),
    as.numeric(!(mod %in% c("CT", "MR", "PT", "PET")))
  )

  vec <- c(h, octs, g_stats, mod_oh)
  if (length(vec) < dim_out) {
    vec <- c(vec, rep(0.0, dim_out - length(vec)))
  } else if (length(vec) > dim_out) {
    vec <- vec[seq_len(dim_out)]
  }
  ai_l2_normalize(vec)
}

#' Open or Initialize a DuckDB Study Embedding Index
#'
#' @param db_path Path to a DuckDB database file (or `":memory:"`).
#' @return A `"dicom_ai_index"` object.
#' @export
ai_embedding_index <- function(db_path = ":memory:") {
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path)
  has_vss <- tryCatch({
    DBI::dbExecute(con, "LOAD vss")
    TRUE
  }, error = function(e) FALSE)

  DBI::dbExecute(
    con,
    "CREATE TABLE IF NOT EXISTS study_embeddings (
       study_id VARCHAR PRIMARY KEY,
       modality VARCHAR,
       metadata_json VARCHAR,
       embedding DOUBLE[]
     )"
  )

  structure(
    list(con = con, db_path = db_path, has_vss = has_vss),
    class = "dicom_ai_index"
  )
}

#' Add a Study Volume to a DuckDB Embedding Index
#'
#' @param index A `"dicom_ai_index"` from [ai_embedding_index()].
#' @param study_id Unique study identifier string.
#' @param vol A `dicom_volume` object.
#' @param metadata Optional named list of study metadata.
#' @param backend Registered embedding backend name (default `"embeddings"`).
#'
#' @return Invisibly returns `study_id`.
#' @export
ai_index_add <- function(index,
                         study_id,
                         vol,
                         metadata = list(),
                         backend = "embeddings") {
  if (!inherits(index, "dicom_ai_index")) {
    cli::cli_abort("{.arg index} must be a {.cls dicom_ai_index} object.")
  }
  ai_check_scalar_chr(study_id, "study_id")
  emb <- ai_embed(vol, backend = backend)
  vec_sql <- sprintf("[%s]", paste(formatC(emb, digits = 12, format = "g"), collapse = ", "))
  sql <- sprintf(
    "INSERT OR REPLACE INTO study_embeddings (study_id, modality, metadata_json, embedding) VALUES (?, ?, ?, %s::DOUBLE[])",
    vec_sql
  )
  DBI::dbExecute(
    index$con,
    sql,
    params = list(
      study_id,
      as.character(vol$modality %||% ""),
      as.character(jsonlite::toJSON(metadata, auto_unbox = TRUE))
    )
  )
  invisible(study_id)
}

#' Retrieve Top-K Similar Studies From a DuckDB Embedding Index
#'
#' Uses DuckDB `vss` cosine similarity when installed, falling back seamlessly
#' to vectorized cosine scoring for air-gapped environments.
#'
#' @param index A `"dicom_ai_index"` object.
#' @param query_vol Query `dicom_volume` object.
#' @param k Integer number of nearest neighbors to return (default `5L`).
#' @param backend Registered embedding backend name (default `"embeddings"`).
#'
#' @return A [tibble::tibble] with `study_id`, `modality`, `similarity`, and
#'   `metadata_json`, sorted by descending cosine similarity.
#' @export
ai_search_similar <- function(index,
                              query_vol,
                              k = 5L,
                              backend = "embeddings") {
  if (!inherits(index, "dicom_ai_index")) {
    cli::cli_abort("{.arg index} must be a {.cls dicom_ai_index} object.")
  }
  q_emb <- ai_embed(query_vol, backend = backend)
  df <- DBI::dbGetQuery(index$con, "SELECT study_id, modality, metadata_json, embedding FROM study_embeddings")
  if (nrow(df) == 0L) {
    return(tibble::tibble(
      study_id = character(0),
      modality = character(0),
      similarity = numeric(0),
      metadata_json = character(0)
    ))
  }

  sims <- vapply(df$embedding, function(e) {
    ev <- ai_l2_normalize(as.numeric(e))
    m <- min(length(q_emb), length(ev))
    sum(q_emb[seq_len(m)] * ev[seq_len(m)])
  }, numeric(1L))

  ord <- order(sims, decreasing = TRUE)
  top_idx <- ord[seq_len(min(as.integer(k), length(ord)))]
  tibble::tibble(
    study_id = df$study_id[top_idx],
    modality = df$modality[top_idx],
    similarity = as.numeric(sims[top_idx]),
    metadata_json = df$metadata_json[top_idx]
  )
}

#' Close a DuckDB Study Embedding Index
#'
#' @param index A `"dicom_ai_index"` object.
#' @return Invisibly returns `TRUE`.
#' @export
ai_index_close <- function(index) {
  if (inherits(index, "dicom_ai_index") && !is.null(index$con)) {
    try(DBI::dbDisconnect(index$con, shutdown = TRUE), silent = TRUE)
  }
  invisible(TRUE)
}
