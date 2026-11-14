#' Build `ellmer` Tool Definitions for the `dicomtk.ai` MCP Server
#'
#' Constructs a named list of `ellmer::tool()` definitions exposing
#' header inspection, automated QC, guardrailed de-identification dry-runs,
#' residual-PHI verification, protocol harmonisation, and AI segmentation.
#'
#' @return A named list of `ellmer` `ToolDef` objects.
#' @export
dicomtk_mcp_tools <- function() {
  t_inspect <- ellmer::tool(
    fun = function(path) {
      hdr <- dicomtk::read_dicom_header(path)
      jsonlite::toJSON(utils::head(hdr, 50L), auto_unbox = TRUE)
    },
    name = "inspect_headers",
    description = "Inspect DICOM header tags for a single file.",
    arguments = list(
      path = ellmer::type_string("Path to a DICOM (.dcm) file.")
    ),
    annotations = ellmer::tool_annotations(read_only_hint = TRUE)
  )

  t_qc <- ellmer::tool(
    fun = function(path) {
      vol <- dicomtk::read_dicom_volume(path, warn = FALSE)
      qc <- dicomtk::dicom_image_qc(vol)
      jsonlite::toJSON(qc, auto_unbox = TRUE)
    },
    name = "image_qc",
    description = "Run automated image quality control (SNR, CNR, truncation, spacing, ringing).",
    arguments = list(
      path = ellmer::type_string("Path to a DICOM file or series directory.")
    ),
    annotations = ellmer::tool_annotations(read_only_hint = TRUE)
  )

  t_dry_run <- ellmer::tool(
    fun = function(path, profile = "ps3.15", override_json = "{}") {
      ov <- if (nzchar(trimws(override_json))) {
        jsonlite::fromJSON(override_json, simplifyVector = FALSE)
      } else {
        list()
      }
      base_prof <- dicomtk::dicom_deid_profile(profile = profile)
      plan <- tryCatch(
        ai_agent_plan(
          task = "deid_and_qc",
          path = path,
          baseline_profile = base_prof,
          override_tags = ov,
          chat = ai_chat("offline")
        ),
        error = function(e) ellmer::tool_reject(conditionMessage(e))
      )
      dry <- ai_agent_dry_run(plan)
      jsonlite::toJSON(dry$dry_run, auto_unbox = TRUE)
    },
    name = "deid_dry_run",
    description = "Plan and dry-run a DICOM de-identification workflow without weakening the baseline profile.",
    arguments = list(
      path = ellmer::type_string("Input DICOM file or directory path."),
      profile = ellmer::type_string("Baseline PS3.15 profile name.", required = FALSE),
      override_json = ellmer::type_string("JSON object mapping '(gggg,eeee)' tags to actions.", required = FALSE)
    ),
    annotations = ellmer::tool_annotations(read_only_hint = TRUE)
  )

  t_verify <- ellmer::tool(
    fun = function(path, profile = "ps3.15") {
      ver <- dicomtk::dicom_deid_verify(
        path = path,
        profile = dicomtk::dicom_deid_profile(profile = profile)
      )
      jsonlite::toJSON(list(passed = ver$passed, files_scanned = ver$files_scanned), auto_unbox = TRUE)
    },
    name = "deid_verify",
    description = "Audit an output DICOM directory for residual PHI leakage.",
    arguments = list(
      path = ellmer::type_string("Output DICOM directory to verify."),
      profile = ellmer::type_string("Baseline profile name.", required = FALSE)
    ),
    annotations = ellmer::tool_annotations(read_only_hint = TRUE)
  )

  t_harmonize <- ellmer::tool(
    fun = function(series_description, modality = "CT", body_part = "") {
      df <- tibble::tibble(
        SeriesDescription = series_description,
        Modality = modality,
        BodyPartExamined = body_part
      )
      res <- ai_harmonize_protocol(df)
      jsonlite::toJSON(res, auto_unbox = TRUE)
    },
    name = "harmonize_protocol",
    description = "Map a SeriesDescription and Modality to LOINC-RSNA Playbook and RadLex codes.",
    arguments = list(
      series_description = ellmer::type_string("DICOM SeriesDescription string."),
      modality = ellmer::type_string("DICOM Modality code (e.g. CT, MR, PT).", required = FALSE),
      body_part = ellmer::type_string("Optional BodyPartExamined string.", required = FALSE)
    ),
    annotations = ellmer::tool_annotations(read_only_hint = TRUE)
  )

  t_seg <- ellmer::tool(
    fun = function(path, backend = "totalsegmentator") {
      res <- ai_segment(vol = path, backend = backend, estimate_uncertainty = TRUE)
      jsonlite::toJSON(res$metrics, auto_unbox = TRUE)
    },
    name = "ai_segment",
    description = "Run a registered AI segmentation backend and compute uncertainty metrics.",
    arguments = list(
      path = ellmer::type_string("Path to input DICOM file or series directory."),
      backend = ellmer::type_string("Registered segmentation backend name.", required = FALSE)
    ),
    annotations = ellmer::tool_annotations(read_only_hint = TRUE)
  )

  list(
    inspect_headers = t_inspect,
    image_qc = t_qc,
    deid_dry_run = t_dry_run,
    deid_verify = t_verify,
    harmonize_protocol = t_harmonize,
    ai_segment = t_seg
  )
}

#' Start the `dicomtk.ai` Model Context Protocol (MCP) Server
#'
#' Launches an MCP server via [`mcptools::mcp_server()`] exposing
#' [dicomtk_mcp_tools()] over `"stdio"` or `"http"`.
#'
#' @param type Transport type: `"stdio"` or `"http"`.
#' @param host Host interface for HTTP transport (default `"127.0.0.1"`).
#' @param port Port for HTTP transport (default `8080L`).
#' @param tools List of `ellmer::ToolDef` objects (default
#'   [dicomtk_mcp_tools()]).
#'
#' @return Called for its side effect (runs the MCP server loop).
#' @export
start_mcp_server <- function(type = c("stdio", "http"),
                             host = "127.0.0.1",
                             port = 8080L,
                             tools = dicomtk_mcp_tools()) {
  type <- match.arg(type)
  mcptools::mcp_server(
    tools = tools,
    type = type,
    host = host,
    port = as.integer(port)
  )
}
