test_that("ai_deid_report redacts PHI from free text and enforces monotonic union", {
  rpt <- paste(
    "Patient John Tan (MRN: MRN-987654, NRIC: S8612345A) underwent CT Chest on 2026-03-14.",
    "Contact: john.tan@example.org, +65-9123-4567. Dr. Lim noted no acute findings."
  )
  res <- ai_deid_report(rpt, backend = "presidio", mode = "redact")
  expect_type(res, "list")
  expect_false(grepl("John Tan", res$text, fixed = TRUE))
  expect_false(grepl("MRN-987654", res$text, fixed = TRUE))
  expect_false(grepl("S8612345A", res$text, fixed = TRUE))
  expect_false(grepl("john.tan@example.org", res$text, fixed = TRUE))
  expect_false(grepl("9123-4567", res$text, fixed = TRUE))
  expect_gte(nrow(res$spans), 4L)
  expect_true(grepl("no acute findings", res$text, fixed = TRUE))
})
