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

  # Pseudonymize mode and dicom_sr list input
  sr_in <- list(text = c("Patient Jane Doe (NRIC: S9012345Z)", "Normal chest radiograph."))
  res_pseudo <- ai_deid_report(sr_in, mode = "pseudonymize")
  expect_false(grepl("Jane Doe", res_pseudo$text, fixed = TRUE))
  expect_false(grepl("S9012345Z", res_pseudo$text, fixed = TRUE))
  expect_true(grepl("<", res_pseudo$text, fixed = TRUE))

  # Monotonic union invariant: adversarial LLM audit returning only 1 extra span
  # can add spans ("Ward 8B") but can NEVER remove deterministic regex spans
  chat_stub <- ai_chat("offline")
  chat_stub$audit_fn <- function(txt) {
    pos <- regexpr("Dr. Lim", txt, fixed = TRUE)
    tibble::tibble(
      entity_type = "PROVIDER",
      start = as.integer(pos),
      end = as.integer(pos) + 6L
    )
  }
  res_union <- ai_deid_report(rpt, chat = chat_stub, mode = "redact")
  expect_false(grepl("John Tan", res_union$text, fixed = TRUE))
  expect_false(grepl("MRN-987654", res_union$text, fixed = TRUE))
  expect_false(grepl("S8612345A", res_union$text, fixed = TRUE))
  expect_false(grepl("Dr. Lim", res_union$text, fixed = TRUE))
})
