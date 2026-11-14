# Phase 3 Design: `dicomtk.ai` (`0.1.0`) — AI, Agents, Clinical NLP & Vector Search

**Date:** 2026-11-14
**Status:** Validated
**Repository:** `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.ai` (`lauyeehow1986-hub/dicomtk.ai`)
**Lab Companion:** `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk-lab` (`profiles: ["ai", "all"]`)

---

## 1. Purpose & Package Boundary

`dicomtk.ai` is the first satellite package in the `dicomtk` ecosystem, keeping heavy AI orchestration (`ellmer`), Model Context Protocol tooling (`mcptools`), REST client adapters (`httr2`), and DuckDB vector similarity storage out of the lean CRAN core (`dicomtk`).

- **Package Name:** `dicomtk.ai` (`0.1.0`)
- **Depends / Imports:** `R (>= 4.1.0)`, `dicomtk (>= 0.4.0)`, `ellmer (>= 0.4.0)`, `mcptools (>= 0.2.0)`, `duckdb (>= 1.0.0)`, `DBI`, `httr2`, `jsonlite`, `tibble`, `cli`, `rlang`, `stats`, `utils`
- **Suggests:** `testthat (>= 3.0.0)`, `tesseract`, `torch`, `withr`, `knitr`, `rmarkdown`
- **Python Independence:** Zero mandatory Python runtime (`reticulate` never required). Production AI models (`TotalSegmentator`, `nnU-Net v2`, `MONAI VISTA3D`, `MedSAM2`, `Presidio`, `Ollama`) run as containerized REST services (`dicomtk-lab --profile ai`), paired with a first-class `"offline"` deterministic engine so `testthat` and `R CMD check` run offline with zero GPU/network requirements.

---

## 2. Architecture & Modules

### 2.1 `ellmer` Chat Adapter & 5-Stage Guardrailed Agent Loop
- **`ai_chat()` & `as_ellmer_chat()`**: Unified constructor wrapping `ellmer::chat_ollama()`, `chat_openai()`, `chat_anthropic()`, `chat_google_gemini()`, plus an `"offline"` deterministic rule-based planner (`ai_offline_chat`). Converts legacy `dicomtk::dicom_llm()` configs cleanly.
- **5-Stage Explicit State Machine (`dicom_agent_plan`)**:
  1. `ai_agent_plan(task, path, baseline_profile, chat, ...)` — Plans target series, protocol/QC actions, segmentation backends, and proposed de-identification adjustments.
  2. `ai_agent_dry_run(plan)` — Evaluates tag-level actions and risks against `baseline_profile` without writing/mutating any DICOM file.
  3. `ai_agent_approve(dry_run, auto_approve = FALSE, approver = NULL)` — Enforces interactive confirmation (or explicit programmatic approval in batch mode) before mutation.
  4. `ai_agent_execute(approved_plan, out_dir)` — Executes `dicomtk::dicom_deid()`, `dicomtk::dicom_image_qc()`, and/or `ai_segment()` into `out_dir`, recording W3C PROV provenance metadata.
  5. `ai_agent_verify(exec_result)` — Runs `dicomtk::dicom_deid_verify()` and structural integrity assertions.
- **Unbypassable Non-Weakening Invariant**:
  - `dicomtk` defines the join-semilattice `K (1) < C (2) < U (3) < D (4) < Z (5) < X (6)`.
  - `validate_agent_profile_guardrail(baseline, proposed)` verifies that for every baseline tag, `rank(proposed) >= rank(baseline)`, that `deidentify` and `patient_deid` flags are never downgraded from `TRUE` to `FALSE`, that `age_cap_years` and `zip_prefix_digits` are never relaxed or removed, and that all baseline `jurisdictions` and `regex_scrubbers` remain intact.
  - Any attempted weakening triggers `ellmer::tool_reject()` in LLM tool calls and `cli::cli_abort()` in agent execution.

### 2.2 Native MCP Server (`mcptools`)
- **`dicomtk_mcp_tools()`**: Builds `ellmer::tool()` specifications exposing `dicom_inspect_headers`, `dicom_run_qc`, `dicom_deid_dry_run`, `dicom_deid_verify_tool`, `ai_harmonize_protocol_tool`, `ai_segment_tool`, and `ai_search_similar_tool` (all bound by the non-weakening guardrail for any mutating/de-id action).
- **`start_mcp_server(type = c("stdio", "http"), ...)`**: Launches `mcptools::mcp_server(tools = dicomtk_mcp_tools(), ...)` cleanly for Antigravity IDE, Claude Desktop, and headless agent clients.

### 2.3 Pluggable AI Backend Registry, Uncertainty & IHE AIR Outputs
- **Registry (`register_ai_backend()`, `get_ai_backend()`, `list_ai_backends()`)**:
  - Environment-backed registry with pre-registered specs for `totalsegmentator`, `nnunet`, `vista3d`, `medsam2`, `presidio`, `ocr`, and `embeddings`, each supporting `"offline"` deterministic execution alongside HTTP/REST (`httr2`) adapters for live containers.
- **Segmentation & Uncertainty (`ai_segment()`)**:
  - Exports `dicomtk::dicom_volume` via `dicomtk::write_nifti()` in a cleaned temp staging dir, forwards 2D/3D point/box prompts for `medsam2`, aligns output masks to reference `dicom_volume`, and computes voxel-wise Shannon/binary entropy uncertainty volumes (`units = "entropy"`) and scalar uncertainty summaries (`mean_entropy`, `high_uncertainty_frac`, optional `dice` against ground-truth `dicom_seg`).
- **IHE AIR / AIW-I Standardized Export (`ai_export_results()`)**:
  - Persists outputs as `dicomtk::dicom_seg()` (`write_dicom_seg()`) + `dicomtk::dicom_sr_tid1500()` quantitative measurement reports with algorithm name/version provenance and uncertainty metrics.

### 2.4 Clinical NLP & Protocol Harmonisation
- **Report De-Identification (`ai_deid_report()`)**:
  - Accepts plain text or `dicomtk::read_dicom_sr()` structured reports (`ContentSequence` text extraction).
  - Supports Presidio REST (`presidio-analyzer` + `presidio-anonymizer`) and built-in offline HIPAA/GDPR pattern+dictionary NER.
  - Monotonic union invariant: optional `ellmer` audit passes may add missed PHI spans but can never erase deterministic NER detections.
- **Weak-Label Extraction (`ai_extract_labels()`)**:
  - Extracts structured pathology findings (`finding`, `anatomy`, `polarity = c("present", "absent", "uncertain")`, `confidence`) using ConText/negation rules offline or `ellmer` structured extraction online.
- **Protocol Harmonisation (`ai_harmonize_protocol()`, `radlex_playbook`)**:
  - Bundles a curated subset of **LOINC-RSNA Radiology Playbook & RadLex** (`data/radlex_playbook.rda`) covering CT, MR, PET, DX, MG, and US protocols (`rpid`, `long_common_name`, `modality`, `body_region`, `radlex_id`, `contrast`).
  - Matches `SeriesDescription` + `Modality` + `BodyPartExamined` via deterministic token/Jaccard/Levenshtein similarity with optional `ellmer` disambiguation for low-confidence headers.

### 2.5 Embeddings & DuckDB Similar-Case Search
- **`ai_embed()`**, **`ai_embedding_index()`**, **`ai_index_add()`**, **`ai_search_similar()`**:
  - Computes normalized multi-scale intensity/spatial histograms offline (`"offline"`) or via a REST embedding service (`RAD-DINO` / `BiomedCLIP` / `CT-FM`).
  - Stores study metadata and `DOUBLE[]` embeddings in DuckDB. Automatically uses DuckDB `vss` (`LOAD vss` + `array_cosine_similarity`) when the extension is available locally, with a seamless pure-SQL / vectorized cosine fallback for air-gapped CI environments.

### 2.6 `dicomtk-lab --profile ai` & Verification Criteria
- Add `ollama`, `presidio-analyzer`, `presidio-anonymizer`, `totalsegmentator`, and `monai-label` containers under `profiles: ["ai", "all"]` to `dicomtk-lab/docker-compose.yml`.
- **Exit Criteria**:
  1. Fuzz/property test across 100+ randomized adversarial LLM override payloads proves zero weakening of `baseline_profile`.
  2. All unit tests pass offline without Python, GPU, or network access.
  3. Env-gated (`DICOMTK_TEST_AI=true`) integration tests exercise live `dicomtk-lab --profile ai` endpoints when running.
  4. Clean `R CMD check` (`0 ERRORs | 0 WARNINGs`).
