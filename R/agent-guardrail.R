# Internal: DICOM PS3.15 monotonic action semilattice ranks
.ai_action_ranks <- c(K = 1L, C = 2L, U = 3L, D = 4L, Z = 5L, X = 6L)
.ai_rank_to_action <- c("K", "C", "U", "D", "Z", "X")

#' Enforce Non-Weakening Monotonic De-Identification Guardrail
#'
#' Validates or clamps any agent-proposed overrides, options, or policy flags
#' against a baseline [`dicomtk::dicom_deid_profile()`] along the strict
#' PS3.15 join-semilattice `K < C < U < D < Z < X`.
#'
#' @param baseline A baseline `dicom_deid_profile` object.
#' @param override_tags Named list of tag-action overrides.
#' @param options Character vector of additional PS3.15 options.
#' @param jurisdictions Optional character vector of additional jurisdictions.
#' @param deidentify Optional logical flag override.
#' @param patient_deid Optional logical flag override.
#' @param mode `"reject"` (default; throws an error on any weakening attempt)
#'   or `"clamp"` (clamps every tag and flag to at least baseline strength).
#'
#' @return A validated (or monotonically clamped) `dicom_deid_profile` object.
#' @examples
#' base <- dicomtk::dicom_deid_profile("ps3.15")
#' stronger <- enforce_non_weakening_profile(base, override_tags = list("(0008,1030)" = "X"))
#' @export
enforce_non_weakening_profile <- function(baseline,
                                          override_tags = list(),
                                          options = character(0),
                                          jurisdictions = NULL,
                                          deidentify = NULL,
                                          patient_deid = NULL,
                                          mode = c("reject", "clamp")) {
  mode <- match.arg(mode)
  if (!inherits(baseline, "dicom_deid_profile")) {
    cli::cli_abort("{.arg baseline} must be a {.cls dicom_deid_profile} object.")
  }

  base_tags <- baseline$tags
  base_ranks <- stats::setNames(.ai_action_ranks[base_tags$action], base_tags$tag)

  reasons <- character(0)
  if (isTRUE(baseline$deidentify) && isFALSE(deidentify)) {
    reasons <- c(reasons, "cannot set `deidentify = FALSE`")
  }
  if (isTRUE(baseline$patient_deid) && isFALSE(patient_deid)) {
    reasons <- c(reasons, "cannot set `patient_deid = FALSE`")
  }

  merged_options <- unique(c(baseline$options, options %||% character(0)))
  merged_jurisdictions <- unique(c(baseline$jurisdictions, jurisdictions %||% character(0)))
  if (length(merged_jurisdictions) == 0L) merged_jurisdictions <- NULL

  # Compile candidate profile
  cand <- dicomtk::dicom_deid_profile(
    profile = baseline$profile,
    options = merged_options,
    jurisdictions = merged_jurisdictions,
    override_tags = override_tags,
    date_shift = baseline$date_shift,
    dob_policy = baseline$dob_policy,
    patient_deid = if (identical(mode, "clamp") && isTRUE(baseline$patient_deid)) TRUE else (patient_deid %||% baseline$patient_deid),
    deidentify = if (identical(mode, "clamp") && isTRUE(baseline$deidentify)) TRUE else (deidentify %||% baseline$deidentify)
  )

  cand_ranks <- stats::setNames(.ai_action_ranks[cand$tags$action], cand$tags$tag)
  common_tags <- intersect(names(base_ranks), names(cand_ranks))
  weakened_tags <- common_tags[cand_ranks[common_tags] < base_ranks[common_tags]]

  if (length(weakened_tags) > 0L) {
    reasons <- c(reasons, sprintf(
      "weakened %d tag(s) (e.g. %s: %s -> %s)",
      length(weakened_tags),
      weakened_tags[1L],
      baseline$tags$action[match(weakened_tags[1L], baseline$tags$tag)],
      cand$tags$action[match(weakened_tags[1L], cand$tags$tag)]
    ))
  }

  if (length(reasons) > 0L && identical(mode, "reject")) {
    cli::cli_abort("Proposed changes would weaken baseline de-identification profile: {paste(reasons, collapse = '; ')}.")
  }

  if (identical(mode, "clamp") && length(weakened_tags) > 0L) {
    idx <- match(weakened_tags, cand$tags$tag)
    clamped_r <- pmax(base_ranks[weakened_tags], cand_ranks[weakened_tags])
    cand$tags$action[idx] <- .ai_rank_to_action[clamped_r]
  }

  cand
}
