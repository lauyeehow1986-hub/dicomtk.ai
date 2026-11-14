test_that("ai_segment produces dicom_seg, entropy uncertainty volume, Dice metrics, and IHE AIR DICOM outputs", {
  synth <- dicomtk::dicom_synthesize(modality = "CT", dims = c(16L, 16L, 4L))
  out_dir <- file.path(tempdir(), "ai_seg_export_test")
  on.exit(unlink(c(synth[["out_dir"]], out_dir), recursive = TRUE), add = TRUE)

  vol <- dicomtk::read_dicom_volume(synth[["out_dir"]])
  # Place centered target intensity on uniform background
  vol$voxels[] <- -1000
  vol$voxels[5:12, 5:12, 2:3] <- 250

  ref_mask <- array(0L, dim = dim(vol))
  ref_mask[5:12, 5:12, 2:3] <- 1L
  ref_seg <- dicomtk::dicom_seg(ref_mask, vol, tibble::tibble(segment_id = 1L, label = "Target"))

  res <- ai_segment(
    vol = vol,
    backend = "totalsegmentator",
    estimate_uncertainty = TRUE,
    reference_seg = ref_seg
  )
  expect_s3_class(res$seg, "dicom_seg")
  expect_s3_class(res$seg, "dicom_volume")
  expect_equal(dim(res$seg), dim(vol))

  expect_s3_class(res$uncertainty, "dicom_volume")
  expect_equal(res$uncertainty$units, "entropy")
  uvals <- as.numeric(res$uncertainty$voxels)
  expect_true(all(is.finite(uvals) & uvals >= 0 & uvals <= log(2) + 1e-6))

  expect_true(is.finite(res$metrics$mean_entropy))
  expect_true(is.finite(res$metrics$dice) && res$metrics$dice > 0.5)

  # Prompted MedSAM2 offline segmentation
  res_sam <- ai_segment(
    vol = vol,
    backend = "medsam2",
    prompts = list(points = matrix(c(8, 8, 2), ncol = 3)),
    estimate_uncertainty = TRUE
  )
  expect_s3_class(res_sam$seg, "dicom_seg")
  expect_gt(sum(res_sam$seg$array > 0L), 0L)

  # IHE AIR standardized SEG + TID 1500 SR export
  exp_res <- ai_export_results(res, vol = vol, out_dir = out_dir)
  expect_true(file.exists(exp_res$seg_path))
  expect_true(file.exists(exp_res$sr_path))

  seg_back <- dicomtk::read_dicom_seg(exp_res$seg_path)
  expect_s3_class(seg_back, "dicom_seg")
  sr_back <- dicomtk::read_sr_tid1500(exp_res$sr_path)
  expect_true(is.list(sr_back))
})
