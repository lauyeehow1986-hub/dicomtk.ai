test_that("register_ai_backend and ai_backend_health manage custom and built-in backends", {
  custom_fn <- function(input, backend, ...) {
    list(mask = array(1L, dim = dim(input)), probs = array(0.9, dim = dim(input)))
  }
  spec <- register_ai_backend(
    name = "custom_unet",
    task = "segmentation",
    mode = "offline",
    predict_fn = custom_fn
  )
  expect_s3_class(spec, "dicom_ai_backend")

  seg_tbl <- list_ai_backends(task = "segmentation")
  expect_true("custom_unet" %in% seg_tbl$name)

  got <- get_ai_backend("custom_unet")
  expect_true(is.function(got$predict_fn))

  hc <- ai_backend_health("totalsegmentator")
  expect_equal(hc$status, "offline_ready")
  expect_error(register_ai_backend("bad_fn", predict_fn = "not_a_fn"))
})
