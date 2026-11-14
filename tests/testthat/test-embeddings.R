test_that("ai_embed and DuckDB embedding index retrieve most similar studies", {
  s_ct1 <- dicomtk::dicom_synthesize(modality = "CT", dims = c(16L, 16L, 4L))
  s_ct2 <- dicomtk::dicom_synthesize(modality = "CT", dims = c(16L, 16L, 4L))
  s_mr  <- dicomtk::dicom_synthesize(modality = "MR", dims = c(16L, 16L, 4L))
  db_path <- tempfile(fileext = ".duckdb")
  on.exit(unlink(c(s_ct1[["out_dir"]], s_ct2[["out_dir"]], s_mr[["out_dir"]], db_path), recursive = TRUE), add = TRUE)

  v_ct1 <- dicomtk::read_dicom_volume(s_ct1[["out_dir"]])
  v_ct2 <- dicomtk::read_dicom_volume(s_ct2[["out_dir"]])
  v_mr  <- dicomtk::read_dicom_volume(s_mr[["out_dir"]])
  v_mr$voxels <- v_mr$voxels * 0.25 + 300

  emb <- ai_embed(v_ct1, backend = "offline")
  expect_true(is.numeric(emb) && length(emb) >= 16L)
  expect_equal(sum(emb^2), 1.0, tolerance = 1e-6)

  idx <- ai_embedding_index(db_path)
  on.exit(ai_index_close(idx), add = TRUE)

  ai_index_add(idx, study_id = "ct_study_1", vol = v_ct1, metadata = list(body_part = "CHEST"))
  ai_index_add(idx, study_id = "mr_study_1", vol = v_mr, metadata = list(body_part = "BRAIN"))

  hits <- ai_search_similar(idx, query_vol = v_ct2, k = 2L)
  expect_s3_class(hits, "tbl_df")
  expect_equal(nrow(hits), 2L)
  expect_equal(hits$study_id[1L], "ct_study_1")
  expect_gt(hits$similarity[1L], 0.9)
})
