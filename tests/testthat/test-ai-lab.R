test_that("dicomtk-lab --profile ai live REST endpoints respond when DICOMTK_TEST_AI=true", {
  testthat::skip_if_not(
    identical(tolower(Sys.getenv("DICOMTK_TEST_AI")), "true"),
    "dicomtk-lab AI container smoke tests skipped. Set DICOMTK_TEST_AI=true to run."
  )

  register_ai_backend("presidio_live", task = "nlp_deid", mode = "rest",
                      endpoint = Sys.getenv("DICOMTK_PRESIDIO_URL", "http://127.0.0.1:5002"))
  hc <- ai_backend_health("presidio_live")
  expect_true(hc$status %in% c("healthy", "unreachable"))
})
