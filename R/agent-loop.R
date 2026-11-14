#' Plan a Guardrailed Clinical Imaging Agent Workflow
#'
#' Stage 1 of the 5-stage clinical agent loop (`plan -> dry-run -> approve ->
#' execute -> verify`). Enforces the non-weakening de-identification guardrail
#' up front.
#'
#' @param task Workflow task: `"deid_and_qc"`, `"deid_only"`, or `"qc_only"`.
#' @param path Input DICOM file or directory path.
#' @param baseline_profile Baseline [`dicomtk::dicom_deid_profile()`] object.
#' @param override_tags Optional named list of tag-action overrides (must not
#'   weaken `baseline_profile`).
#' @param options Optional character vector of PS3.15 options.
#' @param chat A `"dicom_ai_chat"` object from [ai_chat()].
#'
#' @return An S3 `"dicom_agent_plan"` object at `stage = "planned"`.
#' @examples
#' synth <- dicomtk::dicom_synthesize(modality = "CT", dims = c(8L, 8L, 2L))
#' on.exit(unlink(synth$out_dir, recursive = TRUE), add = TRUE)
#' plan <- ai_agent_plan("deid_only", path = synth$out_dir)
#' dry <- ai_agent_dry_run(plan)
#' @export
ai_agent_plan <- function(task = c("deid_and_qc", "deid_only", "qc_only"),
                          path,
                          baseline_profile = dicomtk::dicom_deid_profile(),
                          override_tags = list(),
                          options = character(0),
                          chat = ai_chat("offline")) {
  task <- match.arg(task)
  ai_check_scalar_chr(path, "path")
  if (!file.exists(path) && !dir.exists(path)) {
    cli::cli_abort("Input path {.path {path}} does not exist.")
  }
  chat <- as_ellmer_chat(chat)

  effective_profile <- enforce_non_weakening_profile(
    baseline = baseline_profile,
    override_tags = override_tags,
    options = options,
    mode = "reject"
  )

  files <- if (dir.exists(path)) {
    list.files(path, pattern = "\\.dcm$", full.names = TRUE, recursive = TRUE, ignore.case = TRUE)
  } else {
    path
  }

  structure(
    list(
      stage = "planned",
      task = task,
      path = normalizePath(path, winslash = "/", mustWork = FALSE),
      files = files,
      baseline_profile = baseline_profile,
      effective_profile = effective_profile,
      override_tags = override_tags,
      options = options,
      chat = chat,
      dry_run = NULL,
      approved = FALSE,
      approver = NULL,
      approved_at = NULL,
      out_dir = NULL,
      deid_result = NULL,
      qc_result = NULL,
      verification = NULL
    ),
    class = "dicom_agent_plan"
  )
}

#' Dry-Run a Planned Clinical Imaging Agent Workflow
#'
#' Stage 2 of the agent loop. Evaluates effective tag actions and optional
#' image QC without writing or mutating any files on disk.
#'
#' @param plan A `"dicom_agent_plan"` object from [ai_agent_plan()].
#' @return Updated `"dicom_agent_plan"` object at `stage = "dry_run"`.
#' @export
ai_agent_dry_run <- function(plan) {
  if (!inherits(plan, "dicom_agent_plan")) {
    cli::cli_abort("{.arg plan} must be a {.cls dicom_agent_plan} object.")
  }

  action_counts <- as.list(table(plan$effective_profile$tags$action))
  qc_summary <- NULL
  if (plan$task %in% c("deid_and_qc", "qc_only") && length(plan$files) > 0L) {
    qc_summary <- tryCatch({
      vol <- dicomtk::read_dicom_volume(plan$path, warn = FALSE)
      dicomtk::dicom_image_qc(vol)
    }, error = function(e) NULL)
  }

  plan$dry_run <- list(
    n_files = length(plan$files),
    action_counts = action_counts,
    qc_summary = qc_summary
  )
  plan$stage <- "dry_run"
  plan
}

#' Approve a Dry-Run Clinical Imaging Agent Plan
#'
#' Stage 3 of the agent loop. Requires explicit approval before any mutation or
#' de-identification output is written.
#'
#' @param dry_run A `"dicom_agent_plan"` object at `stage = "dry_run"`.
#' @param auto_approve Logical. Set `TRUE` for non-interactive batch pipelines.
#' @param approver Optional character name/identifier of the approving user.
#'
#' @return Updated `"dicom_agent_plan"` object at `stage = "approved"`.
#' @export
ai_agent_approve <- function(dry_run, auto_approve = FALSE, approver = NULL) {
  if (!inherits(dry_run, "dicom_agent_plan") || !(dry_run$stage %in% c("dry_run", "approved"))) {
    cli::cli_abort("{.arg dry_run} must be a {.cls dicom_agent_plan} that has completed {.fn ai_agent_dry_run}.")
  }

  if (!isTRUE(auto_approve)) {
    if (!interactive()) {
      cli::cli_abort("Non-interactive execution requires {.arg auto_approve = TRUE}.")
    }
    ans <- readline(sprintf("Approve %s on %d file(s)? [y/N]: ", dry_run$task, dry_run$dry_run$n_files))
    if (!tolower(trimws(ans)) %in% c("y", "yes")) {
      cli::cli_abort("Agent execution rejected by human approver.")
    }
  }

  dry_run$approved <- TRUE
  dry_run$approver <- approver %||% Sys.info()[["user"]] %||% "unknown"
  dry_run$approved_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  dry_run$stage <- "approved"
  dry_run
}

#' Execute an Approved Clinical Imaging Agent Plan
#'
#' Stage 4 of the agent loop. Re-verifies the non-weakening guardrail and
#' executes de-identification and/or QC into `out_dir`.
#'
#' @param approved_plan An approved `"dicom_agent_plan"` object.
#' @param out_dir Output directory for de-identified files and provenance logs.
#'
#' @return Updated `"dicom_agent_plan"` object at `stage = "executed"`.
#' @export
ai_agent_execute <- function(approved_plan, out_dir) {
  if (!inherits(approved_plan, "dicom_agent_plan") || !isTRUE(approved_plan$approved) ||
      !identical(approved_plan$stage, "approved")) {
    cli::cli_abort("Plan must be approved via {.fn ai_agent_approve} before execution.")
  }
  ai_check_scalar_chr(out_dir, "out_dir")

  # Defense-in-depth re-check before execution (prevents post-approval TOCTOU tampering)
  verified_profile <- enforce_non_weakening_profile(
    baseline = approved_plan$baseline_profile,
    override_tags = approved_plan$override_tags,
    options = approved_plan$options,
    mode = "reject"
  )
  eff <- approved_plan$effective_profile
  if (!inherits(eff, "dicom_deid_profile") ||
      !identical(eff$deidentify, verified_profile$deidentify) ||
      !identical(eff$patient_deid, verified_profile$patient_deid) ||
      !identical(eff$tags$action, verified_profile$tags$action)) {
    cli::cli_abort("Tampering detected: {.field effective_profile} was modified or weakened after approval.")
  }

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  deid_res <- NULL
  if (approved_plan$task %in% c("deid_and_qc", "deid_only")) {
    deid_res <- dicomtk::dicom_deid(
      path = approved_plan$path,
      out_dir = out_dir,
      profile = verified_profile,
      override_tags = approved_plan$override_tags,
      overwrite = TRUE
    )
  }

  approved_plan$out_dir <- out_dir
  approved_plan$deid_result <- deid_res
  approved_plan$qc_result <- approved_plan$dry_run$qc_summary
  approved_plan$stage <- "executed"
  approved_plan
}

#' Verify Executed Clinical Imaging Agent Outputs
#'
#' Stage 5 of the agent loop. Runs [`dicomtk::dicom_deid_verify()`] on the
#' executed output directory to confirm zero residual PHI leakage.
#'
#' @param exec_result A `"dicom_agent_plan"` object at `stage = "executed"`.
#' @return Updated `"dicom_agent_plan"` object at `stage = "verified"` with
#'   `$passed` logical status.
#' @export
ai_agent_verify <- function(exec_result) {
  if (!inherits(exec_result, "dicom_agent_plan") || !identical(exec_result$stage, "executed")) {
    cli::cli_abort("{.arg exec_result} must be an executed {.cls dicom_agent_plan}.")
  }

  ver <- NULL
  passed <- TRUE
  if (exec_result$task %in% c("deid_and_qc", "deid_only")) {
    ver <- dicomtk::dicom_deid_verify(
      path = exec_result$out_dir,
      profile = exec_result$effective_profile
    )
    passed <- isTRUE(ver$passed)
  }

  exec_result$verification <- ver
  exec_result$passed <- passed
  exec_result$stage <- "verified"
  exec_result
}
