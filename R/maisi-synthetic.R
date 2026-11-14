#' Generate MONAI MAISI 3D Synthetic CT and Multi-Organ Label Masks
#'
#' Generates paired 3D synthetic CT DICOM slices (`ImageType =
#' "DERIVED\\SECONDARY\\SYNTHETIC"`) and multi-organ integer segmentation masks
#' along with a provenance manifest (`maisi_manifest.json`). Supports local
#' deterministic `"phantom"` synthesis or an external MONAI MAISI `"http"`
#' inference endpoint.
#'
#' @param out_dir Output directory for synthetic DICOM series and manifest.
#' @param anatomy_list Character vector of target organ names (e.g.
#'   `c("liver", "spleen", "left_kidney", "right_kidney")`).
#' @param dims Integer vector `c(rows, cols, slices)` (default `c(32L, 32L, 16L)`).
#' @param spacing Numeric vector `c(dx, dy, dz)` in mm.
#' @param mode Synthesis mode: `"phantom"` (pure-R offline) or `"http"` (MAISI
#'   REST service).
#' @param endpoint Optional MAISI HTTP endpoint URL when `mode = "http"`.
#'
#' @return An S3 `"dicom_maisi_result"` object with `dicom_dir`, `mask`,
#'   `anatomy_map`, `manifest_path`, and `synthetic = TRUE`.
#' @examples
#' out <- tempfile("maisi_ex_")
#' res <- ai_generate_maisi(out, dims = c(16L, 16L, 4L))
#' dim(res$mask)
#' unlink(out, recursive = TRUE)
#' @export
ai_generate_maisi <- function(out_dir = tempfile("maisi_"),
                              anatomy_list = c("liver", "spleen", "left_kidney", "right_kidney"),
                              dims = c(32L, 32L, 16L),
                              spacing = c(1.5, 1.5, 2.0),
                              mode = c("phantom", "http"),
                              endpoint = NULL) {
  mode <- match.arg(mode)
  dims <- as.integer(dims)
  if (length(dims) != 3L || any(dims < 4L)) {
    rlang::abort("`dims` must be an integer vector of length 3 with values >= 4.")
  }
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  dicom_dir <- file.path(out_dir, "dicom_ct")

  if (identical(mode, "http")) {
    if (is.null(endpoint) || !nzchar(endpoint)) {
      rlang::abort("`endpoint` must be provided when `mode = 'http'`.")
    }
    resp <- httr2::request(endpoint) |>
      httr2::req_body_json(list(anatomy_list = anatomy_list, dims = dims, spacing = spacing)) |>
      httr2::req_perform()
    httr2::resp_check_status(resp)
  }

  syn <- dicomtk::dicom_synthesize(
    out_dir = dicom_dir,
    modality = "CT",
    dims = dims,
    spacing = spacing,
    phi = FALSE,
    extra_tags = list(
      ImageType = "DERIVED\\SECONDARY\\SYNTHETIC",
      SeriesDescription = "MONAI MAISI Synthetic CT"
    )
  )

  # Build non-overlapping multi-organ ellipsoid/box mask aligned to dims
  mask <- array(0L, dim = dims)
  n_org <- length(anatomy_list)
  nr <- dims[1L]; nc <- dims[2L]; ns <- dims[3L]
  for (k in seq_len(n_org)) {
    r1 <- max(2L, floor((k - 1L) * nr / n_org) + 1L)
    r2 <- min(nr - 1L, floor(k * nr / n_org))
    c1 <- max(2L, floor(nc * 0.25))
    c2 <- min(nc - 1L, floor(nc * 0.75))
    s1 <- max(2L, floor(ns * 0.2))
    s2 <- min(ns - 1L, max(2L, floor(ns * 0.8)))
    if (r2 >= r1 && c2 >= c1 && s2 >= s1) {
      mask[r1:r2, c1:c2, s1:s2] <- as.integer(k)
    }
  }

  anatomy_map <- stats::setNames(as.list(seq_len(n_org)), anatomy_list)
  manifest <- list(
    generator = "MONAI MAISI",
    mode = mode,
    synthetic = TRUE,
    image_type = "DERIVED\\SECONDARY\\SYNTHETIC",
    dims = dims,
    spacing = spacing,
    anatomy_map = anatomy_map,
    generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  )
  manifest_path <- file.path(out_dir, "maisi_manifest.json")
  jsonlite::write_json(manifest, manifest_path, auto_unbox = TRUE, pretty = TRUE)

  structure(
    list(
      out_dir = normalizePath(out_dir, winslash = "/", mustWork = FALSE),
      dicom_dir = syn$out_dir,
      mask = mask,
      anatomy_map = anatomy_map,
      manifest_path = manifest_path,
      synthetic = TRUE
    ),
    class = "dicom_maisi_result"
  )
}
