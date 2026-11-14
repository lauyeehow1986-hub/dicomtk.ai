test_that("ai_extract_labels classifies present, absent, and uncertain findings", {
  rpt <- paste(
    "Moderate right pleural effusion is present.",
    "No evidence of pneumothorax.",
    "Possible early pulmonary edema; correlate clinically."
  )
  lbl <- ai_extract_labels(rpt, chat = ai_chat("offline"))
  expect_s3_class(lbl, "tbl_df")
  expect_true(all(c("finding", "anatomy", "polarity", "confidence") %in% names(lbl)))

  eff <- lbl[grepl("effusion", lbl$finding, ignore.case = TRUE), ]
  expect_equal(eff$polarity[1L], "present")

  ptx <- lbl[grepl("pneumothorax", lbl$finding, ignore.case = TRUE), ]
  expect_equal(ptx$polarity[1L], "absent")

  edm <- lbl[grepl("edema", lbl$finding, ignore.case = TRUE), ]
  expect_equal(edm$polarity[1L], "uncertain")
})
