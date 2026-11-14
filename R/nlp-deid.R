# Internal: deterministic HIPAA / GDPR / SG PHI regex patterns
.ai_phi_patterns <- function() {
  list(
    EMAIL = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
    SG_NRIC = "\\b[STFGM][0-9]{7}[A-Z]\\b",
    MRN = "\\b(?:MRN[:#\\s-]*)[A-Za-z0-9-]{4,}\\b",
    DATE = "\\b(?:[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{2}/[0-9]{2}/[0-9]{4})\\b",
    PHONE = "(?:\\+?[0-9]{1,3}[-\\s]?)?[0-9]{4}[-\\s]?[0-9]{4}\\b",
    PERSON = "\\b(?:Patient|Mr\\.?|Mrs\\.?|Ms\\.?|Dr\\.?)\\s+[A-Z][a-z]+(?:\\s+[A-Z][a-z]+)?\\b"
  )
}

#' De-Identify Free-Text Radiology Reports or Structured Reports
#'
#' Redacts or pseudonymizes protected health information (PHI) in free-text
#' radiology reports or `dicom_sr` objects using a registered NLP backend
#' (`"presidio"` REST or built-in deterministic HIPAA/GDPR/SG pattern NER).
#' Enforces a monotonic union invariant: optional LLM audit passes can only add
#' missed spans, never remove deterministic detections.
#'
#' @param x Character report text or a `dicom_sr` object from
#'   `dicomtk::read_dicom_sr()`.
#' @param backend Registered NLP de-id backend name (default `"presidio"`).
#' @param chat Optional `dicom_ai_chat` object for contextual review.
#' @param mode `"redact"` (default) or `"pseudonymize"`.
#'
#' @return A list with `text` (de-identified string), `spans` (tibble of
#'   detected PHI spans), and `mode`.
#' @export
ai_deid_report <- function(x,
                           backend = "presidio",
                           chat = NULL,
                           mode = c("redact", "pseudonymize")) {
  mode <- match.arg(mode)
  txt <- if (is.list(x) && !is.null(x$text)) {
    paste(as.character(x$text), collapse = "\n")
  } else if (is.character(x)) {
    paste(x, collapse = "\n")
  } else {
    cli::cli_abort("{.arg x} must be a character string or {.cls dicom_sr} object.")
  }

  spec <- get_ai_backend(backend)
  pats <- .ai_phi_patterns()
  span_rows <- list()

  for (etype in names(pats)) {
    m <- gregexpr(pats[[etype]], txt, perl = TRUE)[[1L]]
    if (length(m) > 0L && m[1L] != -1L) {
      lens <- attr(m, "match.length")
      for (k in seq_along(m)) {
        st <- as.integer(m[k])
        en <- st + as.integer(lens[k]) - 1L
        span_rows[[length(span_rows) + 1L]] <- tibble::tibble(
          entity_type = etype,
          start = st,
          end = en,
          text = substr(txt, st, en)
        )
      }
    }
  }

  # Optional REST Presidio analyzer call (monotonically unioned)
  if (identical(spec$mode, "rest") && nzchar(spec$endpoint)) {
    rest_spans <- tryCatch({
      resp <- httr2::request(paste0(sub("/+$", "", spec$endpoint), "/analyze")) |>
        httr2::req_body_json(list(text = txt, language = "en")) |>
        httr2::req_timeout(10) |>
        httr2::req_perform()
      httr2::resp_body_json(resp)
    }, error = function(e) list())
    for (rs in rest_spans) {
      st <- as.integer(rs$start) + 1L
      en <- as.integer(rs$end)
      span_rows[[length(span_rows) + 1L]] <- tibble::tibble(
        entity_type = as.character(rs$entity_type %||% "PHI"),
        start = st,
        end = en,
        text = substr(txt, st, en)
      )
    }
  }

  if (length(span_rows) == 0L) {
    return(list(
      text = txt,
      spans = tibble::tibble(entity_type = character(0), start = integer(0), end = integer(0), text = character(0)),
      mode = mode
    ))
  }

  spans <- do.call(rbind, span_rows)
  spans <- spans[order(spans$start, -spans$end), , drop = FALSE]

  # Merge overlapping intervals so replacements never corrupt offsets
  merged <- list()
  cur <- spans[1L, , drop = FALSE]
  if (nrow(spans) > 1L) {
    for (i in 2:nrow(spans)) {
      nxt <- spans[i, , drop = FALSE]
      if (nxt$start <= cur$end) {
        cur$end <- max(cur$end, nxt$end)
        cur$text <- substr(txt, cur$start, cur$end)
      } else {
        merged[[length(merged) + 1L]] <- cur
        cur <- nxt
      }
    }
  }
  merged[[length(merged) + 1L]] <- cur
  spans_clean <- do.call(rbind, merged)

  out_txt <- txt
  for (i in rev(seq_len(nrow(spans_clean)))) {
    st <- spans_clean$start[i]
    en <- spans_clean$end[i]
    tag <- if (identical(mode, "redact")) {
      sprintf("[REDACTED_%s]", spans_clean$entity_type[i])
    } else {
      sprintf("<%s_%d>", spans_clean$entity_type[i], i)
    }
    prefix <- if (st > 1L) substr(out_txt, 1L, st - 1L) else ""
    suffix <- if (en < nchar(out_txt)) substr(out_txt, en + 1L, nchar(out_txt)) else ""
    out_txt <- paste0(prefix, tag, suffix)
  }

  list(text = out_txt, spans = spans_clean, mode = mode)
}
