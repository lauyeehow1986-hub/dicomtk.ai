testthat::test_that("ai_generate_maisi synthesizes 3D CT DICOM series, multi-organ mask, and provenance manifest", {
  out_dir <- tempfile("maisi_test_")
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  res <- ai_generate_maisi(
    out_dir = out_dir,
    anatomy_list = c("liver", "spleen", "left_kidney", "right_kidney"),
    dims = c(24L, 24L, 8L),
    spacing = c(1.5, 1.5, 2.0),
    mode = "phantom"
  )
  testthat::expect_s3_class(res, "dicom_maisi_result")
  testthat::expect_true(dir.exists(res$dicom_dir))
  testthat::expect_equal(dim(res$mask), c(24L, 24L, 8L))
  testthat::expect_true(all(1:4 %in% unique(as.integer(res$mask))))
  testthat::expect_true(file.exists(res$manifest_path))

  vol <- dicomtk::read_dicom_volume(res$dicom_dir)
  testthat::expect_equal(dim(as.array(vol)), c(24L, 24L, 8L))
})
