test_that("enforce_non_weakening_profile enforces monotonic lattice and rejects 120 random downgrades", {
  baseline <- dicomtk::dicom_deid_profile(
    profile = "ps3.15",
    jurisdictions = "hipaa_safe_harbor"
  )

  # Strengthening a tag (e.g. to X) is permitted
  stronger <- enforce_non_weakening_profile(
    baseline = baseline,
    override_tags = list("(0008,1030)" = "X"),
    mode = "reject"
  )
  expect_s3_class(stronger, "dicom_deid_profile")
  row_1030 <- stronger$tags[stronger$tags$tag == "(0008,1030)", ]
  expect_equal(unname(row_1030$action[1L]), "X")

  # Explicit weakening is rejected
  expect_error(
    enforce_non_weakening_profile(
      baseline = baseline,
      override_tags = list("(0010,0010)" = "K"),
      mode = "reject"
    ),
    "weaken"
  )
  expect_error(
    enforce_non_weakening_profile(
      baseline = baseline,
      patient_deid = FALSE,
      mode = "reject"
    ),
    "weaken"
  )
  expect_error(
    enforce_non_weakening_profile(
      baseline = baseline,
      deidentify = FALSE,
      mode = "reject"
    ),
    "weaken"
  )

  # Property test: 120 randomized adversarial LLM override payloads
  rank_map <- c(K = 1L, C = 2L, U = 3L, D = 4L, Z = 5L, X = 6L)
  base_ranks <- stats::setNames(rank_map[baseline$tags$action], baseline$tags$tag)
  actions <- names(rank_map)

  set.seed(20261114L)
  for (trial in seq_len(120L)) {
    sample_tags <- sample(baseline$tags$tag, size = 5L)
    rand_acts <- sample(actions, size = 5L, replace = TRUE)
    ov <- stats::setNames(as.list(rand_acts), sample_tags)
    bad_flag <- (trial %% 4L == 0L)
    bad_opts <- if (trial %% 3L == 0L) "retain_uids" else character(0)

    is_weakening <- any(rank_map[rand_acts] < base_ranks[sample_tags]) ||
      bad_flag || length(bad_opts) > 0L

    if (is_weakening) {
      expect_error(
        enforce_non_weakening_profile(
          baseline = baseline,
          override_tags = ov,
          options = bad_opts,
          patient_deid = !bad_flag,
          mode = "reject"
        )
      )
    }

    # Clamp mode must NEVER produce a weaker tag or flag than baseline
    clamped <- enforce_non_weakening_profile(
      baseline = baseline,
      override_tags = ov,
      options = bad_opts,
      patient_deid = !bad_flag,
      mode = "clamp"
    )
    clamped_ranks <- stats::setNames(rank_map[clamped$tags$action], clamped$tags$tag)
    expect_true(all(clamped_ranks[names(base_ranks)] >= base_ranks))
    expect_true(clamped$deidentify)
    expect_true(clamped$patient_deid)
    expect_true(all(baseline$jurisdictions %in% clamped$jurisdictions))
  }
})
