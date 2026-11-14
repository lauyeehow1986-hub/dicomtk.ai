test_that("dicomtk.ai initializes default backend registry and radlex_playbook data", {
  backends <- list_ai_backends()
  expect_true(is.data.frame(backends))
  expect_true(all(c(
    "totalsegmentator", "nnunet", "vista3d", "medsam2",
    "presidio", "ocr", "embeddings"
  ) %in% backends$name))

  data("radlex_playbook", package = "dicomtk.ai", envir = environment())
  expect_true(is.data.frame(radlex_playbook))
  expect_gte(nrow(radlex_playbook), 40L)
  expect_true(all(c(
    "rpid", "long_common_name", "short_name", "modality",
    "body_region", "radlex_id", "contrast", "keywords"
  ) %in% names(radlex_playbook)))
})
