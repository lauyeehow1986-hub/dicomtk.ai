test_that("ai_harmonize_protocol maps messy SeriesDescription to LOINC-RSNA and RadLex", {
  hdrs <- tibble::tibble(
    SeriesDescription = c("CHEST WO CON 3.0mm", "BRAIN_T1_POST_GAD", "PET CT WB FDG"),
    Modality = c("CT", "MR", "PT"),
    BodyPartExamined = c("CHEST", "HEAD", "WHOLEBODY")
  )
  res <- ai_harmonize_protocol(hdrs)
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 3L)
  expect_true(all(c("rpid", "radlex_id", "body_region", "contrast", "confidence") %in% names(res)))
  expect_equal(res$rpid[1L], "RPID29")
  expect_equal(res$rpid[2L], "RPID102")
  expect_equal(res$rpid[3L], "RPID201")
  expect_true(all(res$confidence > 0.3))
})
