# Internal: deterministic offline segmentation + probability map
.ai_offline_segment <- function(vox, prompts = NULL) {
  d <- dim(vox)
  vals <- as.numeric(vox)
  vals[!is.finite(vals)] <- 0.0
  vmin <- min(vals)
  vmax <- max(vals)
  vrange <- vmax - vmin

  if (!is.null(prompts) && !is.null(prompts$points)) {
    pts <- as.matrix(prompts$points)
    grid <- expand.grid(
      r = seq_len(d[1L]),
      c = seq_len(d[2L]),
      s = seq_len(d[3L])
    )
    min_d2 <- rep(Inf, nrow(grid))
    rad2 <- max(4.0, (min(d[1:2]) * 0.2)^2)
    for (i in seq_len(nrow(pts))) {
      d2 <- (grid$r - pts[i, 1L])^2 + (grid$c - pts[i, 2L])^2 + ((grid$s - pts[i, 3L]) * 2)^2
      min_d2 <- pmin(min_d2, d2)
    }
    probs_vec <- 1.0 / (1.0 + exp((min_d2 - rad2) / max(1.0, rad2 * 0.25)))
    probs <- array(probs_vec, dim = d)
  } else if (vrange < 1e-9) {
    probs <- array(0.05, dim = d)
  } else {
    thresh <- vmin + 0.4 * vrange
    scale <- max(1e-6, 0.1 * vrange)
    probs <- array(1.0 / (1.0 + exp(-(vals - thresh) / scale)), dim = d)
  }

  mask <- array(as.integer(probs >= 0.5), dim = d)
  list(mask = mask, probs = probs)
}

#' Run Pluggable AI Segmentation With Uncertainty Estimation
#'
#' Runs segmentation via a registered backend (`"totalsegmentator"`, `"nnunet"`,
#' `"vista3d"`, `"medsam2"`, or custom registered backends), aligns the mask to
#' the reference `dicom_volume`, and optionally computes voxel-wise Shannon
#' entropy uncertainty and Dice agreement.
#'
#' @param vol A `dicom_volume` object or path to a DICOM file/directory.
#' @param backend Registered segmentation backend name.
#' @param prompts Optional prompt list for interactive models such as
#'   `"medsam2"` (e.g., `list(points = matrix(c(r, c, s), ncol = 3))`).
#' @param estimate_uncertainty Logical. Compute voxel-wise entropy map
#'   (`TRUE` by default).
#' @param reference_seg Optional reference `dicom_seg` for Dice evaluation.
#'
#' @return A list of class `"dicom_ai_segmentation"` with `seg` (`dicom_seg`),
#'   `uncertainty` (`dicom_volume` or `NULL`), `probs`, `metrics`, and
#'   `backend`.
#' @export
ai_segment <- function(vol,
                       backend = "totalsegmentator",
                       prompts = NULL,
                       estimate_uncertainty = TRUE,
                       reference_seg = NULL) {
  if (is.character(vol)) {
    vol <- dicomtk::read_dicom_volume(vol, warn = FALSE)
  }
  if (!inherits(vol, "dicom_volume") || is.null(vol$voxels)) {
    cli::cli_abort("{.arg vol} must be a valid {.cls dicom_volume} object or DICOM path.")
  }

  spec <- get_ai_backend(backend)
  vox <- vol$voxels
  if (length(dim(vox)) == 4L) {
    vox <- vox[, , , 1L, drop = FALSE]
    dim(vox) <- dim(vox)[1:3]
  }

  if (!is.null(spec$predict_fn)) {
    pred <- spec$predict_fn(vox, spec, prompts = prompts)
  } else if (identical(spec$mode, "rest")) {
    tmp_dir <- tempfile("ai_seg_req_")
    dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
    on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)
    nii_in <- file.path(tmp_dir, "input.nii.gz")
    dicomtk::write_nifti(vol, nii_in, json_sidecar = FALSE)

    resp <- httr2::request(paste0(sub("/+$", "", spec$endpoint), "/predict")) |>
      httr2::req_body_multipart(
        image = curl::form_file(nii_in),
        prompts = jsonlite::toJSON(prompts %||% list(), auto_unbox = TRUE)
      ) |>
      httr2::req_timeout(120) |>
      httr2::req_perform()
    payload <- httr2::resp_body_json(resp)
    pred <- list(
      mask = array(as.integer(unlist(payload$mask)), dim = dim(vox)),
      probs = array(as.numeric(unlist(payload$probs %||% payload$mask)), dim = dim(vox))
    )
  } else {
    pred <- .ai_offline_segment(vox, prompts = prompts)
  }

  seg_meta <- tibble::tibble(
    segment_id = 1L,
    label = paste0(spec$name, "_roi")
  )
  seg <- dicomtk::dicom_seg(mask = pred$mask, ref_volume = vol, segments = seg_meta)

  unc_vol <- NULL
  mean_ent <- NA_real_
  high_unc_frac <- NA_real_
  if (isTRUE(estimate_uncertainty) && !is.null(pred$probs)) {
    p_c <- pmin(pmax(as.numeric(pred$probs), 1e-6), 1.0 - 1e-6)
    ent_vec <- -(p_c * log(p_c) + (1.0 - p_c) * log(1.0 - p_c))
    ent_arr <- array(ent_vec, dim = dim(vox))
    unc_vol <- dicomtk::new_dicom_volume(
      voxels = ent_arr,
      affine = vol$affine,
      spacing = vol$spacing,
      modality = vol$modality,
      units = "entropy"
    )
    mean_ent <- mean(ent_vec)
    high_unc_frac <- mean(ent_vec > (0.5 * log(2.0)))
  }

  dice_val <- NA_real_
  if (!is.null(reference_seg) && inherits(reference_seg, "dicom_seg")) {
    p_bin <- as.logical(pred$mask > 0L)
    r_bin <- as.logical(reference_seg$array > 0L)
    denom <- sum(p_bin) + sum(r_bin)
    dice_val <- if (denom > 0L) (2.0 * sum(p_bin & r_bin)) / denom else 1.0
  }

  structure(
    list(
      seg = seg,
      uncertainty = unc_vol,
      probs = pred$probs,
      metrics = list(
        foreground_voxels = sum(pred$mask > 0L),
        mean_entropy = mean_ent,
        high_uncertainty_frac = high_unc_frac,
        dice = dice_val
      ),
      backend = spec$name
    ),
    class = "dicom_ai_segmentation"
  )
}

#' Export AI Segmentation Results in IHE AIR Standardized DICOM Format
#'
#' Writes segmentation masks as a DICOM SEG object (`write_dicom_seg()`) and
#' quantitative summary metrics as a DICOM TID 1500 Measurement Report
#' (`dicom_sr_tid1500()`), aligned with IHE AI Results (AIR) conventions.
#'
#' @param seg_res A `"dicom_ai_segmentation"` object from [ai_segment()], or a
#'   `dicom_seg` object.
#' @param vol Reference `dicom_volume` object.
#' @param out_dir Output directory for standardized DICOM files.
#' @param title Report title for the TID 1500 Measurement Report.
#'
#' @return Invisibly returns a list with `seg_path`, `sr_path`, `out_dir`, and
#'   `metrics`.
#' @export
ai_export_results <- function(seg_res,
                              vol,
                              out_dir,
                              title = "IHE AIR AI Segmentation Report") {
  ai_check_scalar_chr(out_dir, "out_dir")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  seg <- if (inherits(seg_res, "dicom_ai_segmentation")) seg_res$seg else seg_res
  if (!inherits(seg, "dicom_seg")) {
    cli::cli_abort("{.arg seg_res} must be a {.cls dicom_ai_segmentation} or {.cls dicom_seg} object.")
  }

  seg_path <- file.path(out_dir, "ai_seg.dcm")
  sr_path <- file.path(out_dir, "ai_sr_tid1500.dcm")
  dicomtk::write_dicom_seg(seg, seg_path)
  dicomtk::dicom_sr_tid1500(vol = vol, seg = seg, out_path = sr_path, title = title)

  invisible(list(
    seg_path = seg_path,
    sr_path = sr_path,
    out_dir = out_dir,
    metrics = if (inherits(seg_res, "dicom_ai_segmentation")) seg_res$metrics else NULL
  ))
}
