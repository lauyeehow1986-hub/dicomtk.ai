#' Curated LOINC-RSNA Radiology Playbook and RadLex Protocol Table
#'
#' A compact reference dataset of common diagnostic imaging protocols across
#' `CT`, `MR`, `PT`, `NM`, `DX`, `MG`, `US`, and `XA` modalities mapped to
#' LOINC-RSNA Radiology Playbook IDs (`rpid`) and `RadLex` anatomical region
#' identifiers (`radlex_id`).
#'
#' @format A tibble with 46 rows and 8 variables:
#' \describe{
#'   \item{rpid}{LOINC-RSNA Radiology Playbook identifier.}
#'   \item{long_common_name}{Standardized long protocol name.}
#'   \item{short_name}{Abbreviated display name.}
#'   \item{modality}{DICOM Modality code.}
#'   \item{body_region}{Normalized anatomical region.}
#'   \item{radlex_id}{RadLex anatomical identifier (`RID...`).}
#'   \item{contrast}{Logical indicating IV/radiotracer contrast usage.}
#'   \item{keywords}{Space-delimited matching keywords.}
#' }
#' @source Curated subset of LOINC-RSNA Radiology Playbook and RadLex ontology.
"radlex_playbook"
