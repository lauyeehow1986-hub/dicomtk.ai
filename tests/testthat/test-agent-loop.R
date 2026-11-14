test_that("ai_chat and 5-stage agent loop execute safely with approval gate and verification", {
  chat <- ai_chat("offline")
  expect_s3_class(chat, "dicom_ai_chat")

  legacy_llm <- dicomtk::dicom_llm("offline")
  adapted <- as_ellmer_chat(legacy_llm)
  expect_s3_class(adapted, "dicom_ai_chat")

  synth <- dicomtk::dicom_synthesize(modality = "CT", dims = c(16L, 16L, 4L), phi_profile = "basic")
  out_dir <- file.path(tempdir(), "ai_agent_exec_test")
  on.exit(unlink(c(synth[["out_dir"]], out_dir), recursive = TRUE), add = TRUE)

  base_prof <- dicomtk::dicom_deid_profile("ps3.15")
  plan <- ai_agent_plan(
    task = "deid_and_qc",
    path = synth[["out_dir"]],
    baseline_profile = base_prof,
    chat = chat
  )
  expect_s3_class(plan, "dicom_agent_plan")
  expect_equal(plan$stage, "planned")

  dry <- ai_agent_dry_run(plan)
  expect_equal(dry$stage, "dry_run")
  expect_false(dir.exists(out_dir))

  # Executing without approval must abort
  expect_error(ai_agent_execute(dry, out_dir = out_dir), "approved")

  approved <- ai_agent_approve(dry, auto_approve = TRUE, approver = "ci_reviewer")
  expect_equal(approved$stage, "approved")
  expect_equal(approved$approver, "ci_reviewer")

  exec_res <- ai_agent_execute(approved, out_dir = out_dir)
  expect_equal(exec_res$stage, "executed")
  expect_true(dir.exists(out_dir))
  expect_true(length(list.files(out_dir, pattern = "\\.dcm$", recursive = TRUE)) >= 1L)

  ver <- ai_agent_verify(exec_res)
  expect_equal(ver$stage, "verified")
  expect_true(isTRUE(ver$passed))
})
