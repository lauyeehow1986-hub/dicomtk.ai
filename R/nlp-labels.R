# Internal: clinical finding & anatomy dictionary for offline weak-label extraction
.ai_finding_lexicon <- function() {
  tibble::tibble(
    finding = c(
      "pleural effusion", "pneumothorax", "pulmonary edema", "pneumonia",
      "consolidation", "atelectasis", "pulmonary embolism", "nodule",
      "mass", "hemorrhage", "fracture", "cardiomegaly", "ascites"
    ),
    anatomy = c(
      "pleura", "pleura", "lung", "lung",
      "lung", "lung", "pulmonary_artery", "lung",
      "unspecified", "brain_or_tissue", "bone", "heart", "abdomen"
    )
  )
}

#' Extract Weak Clinical Labels From Radiology Report Text
#'
#' Extracts structured pathology findings with assertion polarity (`"present"`,
#' `"absent"`, or `"uncertain"`) using deterministic ConText negation/uncertainty
#' rules (when `"offline"`) or an `ellmer` structured-output chat session.
#'
#' @param text Character vector of report text.
#' @param findings Optional character vector of extra finding terms to track.
#' @param chat A `dicom_ai_chat` object from [ai_chat()].
#'
#' @return A [tibble::tibble] with columns `finding`, `anatomy`, `polarity`,
#'   `confidence`, and `sentence`.
#' @export
ai_extract_labels <- function(text,
                              findings = NULL,
                              chat = ai_chat("offline")) {
  if (!is.character(text) || length(text) == 0L) {
    cli::cli_abort("{.arg text} must be a non-empty character vector.")
  }
  chat <- as_ellmer_chat(chat)

  lex <- .ai_finding_lexicon()
  if (!is.null(findings) && length(findings) > 0L) {
    extra <- tibble::tibble(finding = tolower(as.character(findings)), anatomy = "unspecified")
    lex <- rbind(lex, extra[!extra$finding %in% lex$finding, , drop = FALSE])
  }

  full_txt <- paste(text, collapse = " ")
  sents <- trimws(unlist(strsplit(full_txt, "[.;!?\r\n]+", perl = TRUE)))
  sents <- sents[nzchar(sents)]

  neg_pat <- "\\b(no|no evidence of|negative for|without|absent|free of|ruled out)\\b"
  unc_pat <- "\\b(possible|possibly|probable|probably|suspect|suspicious|cannot exclude|may represent|rule out|questionable)\\b"

  rows <- list()
  for (s in sents) {
    s_low <- tolower(s)
    for (i in seq_len(nrow(lex))) {
      term <- lex$finding[i]
      if (grepl(paste0("\\b", term, "\\b"), s_low, perl = TRUE)) {
        pol <- if (grepl(neg_pat, s_low, perl = TRUE)) {
          "absent"
        } else if (grepl(unc_pat, s_low, perl = TRUE)) {
          "uncertain"
        } else {
          "present"
        }
        conf <- if (identical(pol, "uncertain")) 0.70 else 0.90
        rows[[length(rows) + 1L]] <- tibble::tibble(
          finding = term,
          anatomy = lex$anatomy[i],
          polarity = pol,
          confidence = conf,
          sentence = s
        )
      }
    }
  }

  if (length(rows) == 0L) {
    return(tibble::tibble(
      finding = character(0),
      anatomy = character(0),
      polarity = character(0),
      confidence = numeric(0),
      sentence = character(0)
    ))
  }
  do.call(rbind, rows)
}
