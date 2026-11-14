test_that("dicomtk_mcp_tools builds ellmer ToolDefs and enforces tool_reject on profile weakening", {
  tools <- dicomtk_mcp_tools()
  expect_true(is.list(tools))
  expect_true(all(c(
    "inspect_headers", "image_qc", "deid_dry_run",
    "deid_verify", "harmonize_protocol", "ai_segment"
  ) %in% names(tools)))
  expect_true(inherits(tools$inspect_headers, "ellmer::ToolDef") || is.function(tools$inspect_headers))

  synth <- dicomtk::dicom_synthesize(modality = "CT", dims = c(16L, 16L, 4L))
  on.exit(unlink(synth[["out_dir"]], recursive = TRUE), add = TRUE)

  hdr_res <- tools$inspect_headers(path = synth[["files"]][1L])
  expect_true(is.character(hdr_res) || is.list(hdr_res))

  qc_res <- tools$image_qc(path = synth[["out_dir"]])
  expect_true(is.list(qc_res) || is.character(qc_res))

  # Adversarial downgrade via MCP tool must trigger tool_reject()
  expect_error(
    tools$deid_dry_run(
      path = synth[["out_dir"]],
      profile = "ps3.15",
      override_json = '{"(0010,0010)":"K"}'
    )
  )

  # Valid non-weakening dry-run succeeds
  dry_res <- tools$deid_dry_run(
    path = synth[["out_dir"]],
    profile = "ps3.15",
    override_json = '{"(0008,1030)":"X"}'
  )
  expect_true(is.list(dry_res) || is.character(dry_res))
})
