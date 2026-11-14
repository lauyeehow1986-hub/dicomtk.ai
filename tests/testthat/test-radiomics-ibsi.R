testthat::test_that("ibsi_digital_phantom and ai_extract_radiomics match IBSI Phase-1 reference benchmarks", {
  ph <- ibsi_digital_phantom()
  testthat::expect_equal(dim(ph$voxels), c(4L, 5L, 4L))
  testthat::expect_equal(sum(ph$mask > 0L), 74L)

  rad <- ai_extract_radiomics(ph$volume, ph$mask, discretization = "none")
  testthat::expect_s3_class(rad, "tbl_df")

  vals <- stats::setNames(rad$value, rad$feature)
  testthat::expect_equal(unname(vals["morph_voxel_volume"]), 592, tolerance = 1e-6)
  testthat::expect_equal(unname(vals["stat_mean"]), 2.148649, tolerance = 1e-3)
  testthat::expect_equal(unname(vals["stat_median"]), 1.0, tolerance = 1e-6)
  testthat::expect_equal(unname(vals["stat_var"]), 3.045471, tolerance = 1e-3)
  testthat::expect_equal(unname(vals["stat_skewness"]), 1.2976, tolerance = 0.02)
  testthat::expect_true(all(c(
    "glcm_contrast", "glcm_joint_entropy", "glcm_angular_second_moment",
    "glrlm_short_runs_emphasis", "glrlm_long_runs_emphasis",
    "glszm_small_zone_emphasis", "glszm_zone_percentage"
  ) %in% names(vals)))
  testthat::expect_true(all(is.finite(rad$value)))
})
