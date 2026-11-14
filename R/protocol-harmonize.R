# Internal: normalize string into lowercase alphanumeric tokens
.ai_tokenize <- function(x) {
  toks <- unlist(strsplit(tolower(as.character(x %||% "")), "[^a-z0-9]+"))
  toks <- toks[nzchar(toks)]
  unique(toks)
}

#' Harmonise Messy DICOM Series Descriptions to RadLex and LOINC-RSNA Playbook
#'
#' Maps heterogeneous `SeriesDescription`, `Modality`, and `BodyPartExamined`
#' headers onto standardized LOINC-RSNA Radiology Playbook IDs (`rpid`) and
#' `RadLex` anatomical identifiers (`radlex_id`).
#'
#' @param headers A data frame / tibble with `SeriesDescription` (and optional
#'   `Modality`, `BodyPartExamined` columns).
#' @param chat Optional `dicom_ai_chat` object for semantic tie-breaking on
#'   low-confidence headers.
#'
#' @return A [tibble::tibble] with columns `SeriesDescription`, `Modality`,
#'   `rpid`, `long_common_name`, `short_name`, `body_region`, `radlex_id`,
#'   `contrast`, and `confidence`.
#' @export
ai_harmonize_protocol <- function(headers, chat = NULL) {
  if (!is.data.frame(headers) || !("SeriesDescription" %in% names(headers))) {
    cli::cli_abort("{.arg headers} must be a data.frame containing {.field SeriesDescription}.")
  }

  env <- new.env(parent = emptyenv())
  utils::data("radlex_playbook", package = "dicomtk.ai", envir = env)
  pb <- env$radlex_playbook

  pb_tokens <- lapply(seq_len(nrow(pb)), function(i) {
    .ai_tokenize(paste(pb$long_common_name[i], pb$short_name[i], pb$keywords[i], pb$body_region[i]))
  })

  n <- nrow(headers)
  out_rows <- vector("list", n)

  for (r in seq_len(n)) {
    sd_str <- as.character(headers$SeriesDescription[r] %||% "")
    mod_str <- if ("Modality" %in% names(headers)) toupper(as.character(headers$Modality[r] %||% "")) else ""
    bp_str <- if ("BodyPartExamined" %in% names(headers)) as.character(headers$BodyPartExamined[r] %||% "") else ""

    q_toks <- .ai_tokenize(paste(sd_str, bp_str))
    has_wo <- any(q_toks %in% c("wo", "noncon", "noncontrast", "ncct", "unenhanced"))
    has_w <- any(q_toks %in% c("w", "post", "gad", "cect", "contrast", "cta", "ctpa", "fdg", "psma"))

    scores <- vapply(seq_len(nrow(pb)), function(j) {
      mod_bonus <- if (nzchar(mod_str)) {
        if (identical(mod_str, pb$modality[j])) 0.35 else -0.25
      } else {
        0.0
      }
      inter <- length(intersect(q_toks, pb_tokens[[j]]))
      uni <- length(union(q_toks, pb_tokens[[j]]))
      jacc <- if (uni > 0L) inter / uni else 0.0
      c_bonus <- 0.0
      if (has_wo && !isTRUE(pb$contrast[j])) c_bonus <- c_bonus + 0.15
      if (has_w && isTRUE(pb$contrast[j])) c_bonus <- c_bonus + 0.15
      mod_bonus + 0.55 * jacc + c_bonus
    }, numeric(1L))

    best <- which.max(scores)
    conf <- max(0.0, min(1.0, scores[best]))
    out_rows[[r]] <- tibble::tibble(
      SeriesDescription = sd_str,
      Modality = mod_str,
      rpid = pb$rpid[best],
      long_common_name = pb$long_common_name[best],
      short_name = pb$short_name[best],
      body_region = pb$body_region[best],
      radlex_id = pb$radlex_id[best],
      contrast = pb$contrast[best],
      confidence = round(conf, 4)
    )
  }

  do.call(rbind, out_rows)
}
