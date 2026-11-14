# `dicomtk.ai` (`0.1.0`) Phase 3 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Build `dicomtk.ai` (`0.1.0`), the satellite R package for AI orchestration, MCP tooling (`mcptools`), `ellmer`-based non-weakening clinical agents, segmentation/uncertainty backends (`IHE AIR`), clinical report NLP, protocol harmonisation (`RadLex`/`LOINC-RSNA`), DuckDB vector similarity search, and `dicomtk-lab --profile ai` integration.

**Architecture:** Standalone R package at `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk.ai` importing `dicomtk (>= 0.4.0)`, `ellmer`, `mcptools`, `duckdb`, `DBI`, `httr2`, and `jsonlite`. All AI model backends use a pluggable environment registry supporting REST (`httr2`) adapters for Docker services alongside an `"offline"` deterministic engine so CI and `R CMD check` run with zero GPU/Python/network dependencies.

**Tech Stack:** R (>= 4.1.0), `dicomtk`, `ellmer` (>= 0.4.0), `mcptools` (>= 0.2.0), `duckdb`, `httr2`, `testthat` (>= 3.0.0), `roxygen2`, Docker Compose (`dicomtk-lab`).

**Effort Routing (`/effort-harness-router`):**
- **Hydrogen (`Medium`)**: Tasks 1–8 (package scaffolding, `ellmer` adapters, registry, NLP/protocol harmonisation, DuckDB embeddings, `dicomtk-lab --profile ai`, unit tests, vignette & docs).
- **Argon (`High`)**: Mid-phase security & invariant audit (Task 2 property-test verification + Task 4 MCP tool contract audit) and Task 9 (final Six-Sigma R-universe / `R CMD check` review & push to GitHub + `lauyeehow1986-hub.r-universe.dev`).

---

### Task 1: Package Scaffold, `DESCRIPTION`, `NAMESPACE`, & `radlex_playbook` Data
**Files:**
- Create: `DESCRIPTION`, `LICENSE`, `NEWS.md`, `_pkgdown.yml`, `README.md`
- Create: `R/zzz.R`, `R/utils.R`, `R/data.R`, `data-raw/build_radlex_playbook.R`, `data/radlex_playbook.rda`
- Test: `tests/testthat.R`, `tests/testthat/test-package-init.R`

**Steps:**
1. Write `DESCRIPTION` with `Package: dicomtk.ai`, `Version: 0.1.0`, `Imports` (`dicomtk (>= 0.4.0)`, `ellmer`, `mcptools`, `duckdb`, `DBI`, `httr2`, `jsonlite`, `tibble`, `cli`, `rlang`, `stats`, `utils`), `Suggests` (`testthat`, `tesseract`, `withr`, `knitr`, `rmarkdown`). Notice: keep single quotes around `'DICOM'`, `'R'`, `'DuckDB'`, `'MCP'` in `Description` per CRAN hygiene.
2. Create `data-raw/build_radlex_playbook.R` generating `data/radlex_playbook.rda` (~60 curated LOINC-RSNA Radiology Playbook + RadLex protocols across `CT`, `MR`, `PET`, `DX`, `MG`, `US` with columns `rpid`, `long_common_name`, `short_name`, `modality`, `body_region`, `radlex_id`, `contrast`, `keywords`). Document in `R/data.R`.
3. Write `R/zzz.R` initializing `.onLoad()` default backend registry environment (`.ai_env`).
4. Write `tests/testthat/test-package-init.R` verifying `radlex_playbook` columns, row count (`>= 40`), and `.onLoad` registry initialization.
5. Run `test_file()` (RED -> GREEN), run `roxygen2::roxygenise()`, commit.

---

### Task 2: `ellmer` Chat Adapter & 5-Stage Agent Loop + Non-Weakening Guardrail
**Files:**
- Create: `R/chat.R`, `R/agent-guardrail.R`, `R/agent-loop.R`
- Test: `tests/testthat/test-agent-guardrail.R`, `tests/testthat/test-agent-loop.R`

**Steps:**
1. Write failing tests in `test-agent-guardrail.R` and `test-agent-loop.R`:
   - `ai_chat("offline")` and `as_ellmer_chat(dicomtk::dicom_llm("offline"))` return `"dicom_ai_chat"` objects.
   - `enforce_non_weakening_profile(baseline, override_tags, options, flags)` resolves strictly up the semilattice `K < C < U < D < Z < X` and blocks downgrades (`cli_abort()` / `reject = TRUE`).
   - Property test with 120 randomized adversarial override payloads (`PatientName -> "K"`, `deidentify = FALSE`, `patient_deid = FALSE`, `age_cap_years = NULL`, `retain_uids`, etc.) verifies 100% rejection or monotonic preservation — resolved profile is always `>= baseline` on every tag and flag.
   - Full 5-stage workflow `ai_agent_plan() -> ai_agent_dry_run() -> ai_agent_approve(auto_approve = TRUE) -> ai_agent_execute() -> ai_agent_verify()` runs cleanly on `dicomtk::dicom_synthesize()` fixtures and passes `dicomtk::dicom_deid_verify()`.
2. Run RED tests -> expect `FAIL`.
3. Implement `R/chat.R`, `R/agent-guardrail.R`, and `R/agent-loop.R`.
4. Run GREEN tests -> expect `PASS`, `roxygenise()`, commit.

---

### Task 3: Pluggable AI Backend Registry & REST/Offline Segmentation (`ai_segment()`, Uncertainty, `IHE AIR` Export)
**Files:**
- Create: `R/backend-registry.R`, `R/segment-ai.R`
- Test: `tests/testthat/test-backend-registry.R`, `tests/testthat/test-segment-ai.R`

**Steps:**
1. Write failing tests:
   - `list_ai_backends()` includes `totalsegmentator`, `nnunet`, `vista3d`, `medsam2`, `presidio`, `ocr`, `embeddings`.
   - `register_ai_backend()` registers a custom backend and validates required `predict` callable / `endpoint`.
   - `ai_segment(vol, backend = "totalsegmentator", estimate_uncertainty = TRUE)` and `backend = "medsam2"` with `prompts = list(points = ...)` return `seg` (`dicom_seg`), `uncertainty` (`dicom_volume` with values in `[0, log(2)]` and `units = "entropy"`), and summary `metrics` (`mean_entropy`, `high_uncertainty_frac`, optional `dice` when `reference_seg` supplied).
   - `ai_export_results(res, vol, out_dir)` writes valid DICOM SEG (`.dcm`) + TID 1500 SR (`sr.dcm`) readable back by `dicomtk::read_dicom_seg()` and `dicomtk::read_sr_tid1500()`.
2. Run RED -> implement `R/backend-registry.R` & `R/segment-ai.R` -> run GREEN -> `roxygenise()`, commit.

---

### Task 4: Native MCP Server (`mcptools` + `ellmer::tool` Guardrails)
**Files:**
- Create: `R/mcp-server.R`
- Test: `tests/testthat/test-mcp-server.R`

**Steps:**
1. Write failing tests:
   - `dicomtk_mcp_tools()` returns a named list of `ellmer::ToolDef` objects (`inspect_headers`, `image_qc`, `deid_dry_run`, `deid_verify`, `harmonize_protocol`, `ai_segment`, `search_similar`).
   - Invoking `deid_dry_run` tool with an adversarial downgrade payload (e.g., `override_tags = list("(0010,0010)" = "K")`) returns an `ellmer::tool_reject()` error/condition rather than weakening `ps3.15`.
   - Invoking `inspect_headers`, `image_qc`, and `harmonize_protocol` tools directly executes cleanly and returns structured JSON/list output.
2. Run RED -> implement `R/mcp-server.R` wrapping `mcptools::mcp_server()` and `ellmer::tool()` -> run GREEN -> `roxygenise()`, commit.

---

### Task 5: Clinical NLP (Report De-ID & Weak-Label Extraction) + Protocol Harmonisation
**Files:**
- Create: `R/nlp-deid.R`, `R/nlp-labels.R`, `R/protocol-harmonize.R`
- Test: `tests/testthat/test-nlp-deid.R`, `tests/testthat/test-nlp-labels.R`, `tests/testthat/test-protocol-harmonize.R`

**Steps:**
1. Write failing tests:
   - `ai_deid_report()` redacts/pseudonymizes planted PHI (names, MRNs, dates, phone/email, Singapore NRIC/FIN patterns) from free text AND from `dicomtk::read_dicom_sr()` structured reports; verifies monotonic union invariant when combined with an LLM audit stub.
   - `ai_extract_labels()` extracts finding, anatomy, polarity (`"present"`, `"absent"`, `"uncertain"`), handling negation cues (`"no evidence of pneumothorax"`, `"rule out pulmonary embolism"`, `"moderate pleural effusion"`).
   - `ai_harmonize_protocol()` maps messy `SeriesDescription` values (e.g., `"CHEST WO CON 3.0mm"`, `"BRAIN_T1_POST_GAD"`, `"PET CT WB FDG"`) to accurate `rpid`, `radlex_id`, `modality`, `body_region`, and `contrast` columns.
2. Run RED -> implement all 3 files -> run GREEN -> `roxygenise()`, commit.

---

### Task 6: Foundation Embeddings & DuckDB Similar-Case Search
**Files:**
- Create: `R/embeddings.R`
- Test: `tests/testthat/test-embeddings.R`

**Steps:**
1. Write failing tests:
   - `ai_embed(vol, backend = "offline")` returns an L2-normalized numeric vector (`sum(v^2) == 1`) sensitive to phantom structure.
   - `ai_embedding_index(db_path)` creates DuckDB tables cleanly (using `on.exit()` / explicit `ai_index_close()`).
   - `ai_index_add()` inserts multiple synthetic studies (CT head vs CT chest vs MR brain); `ai_search_similar(idx, query_vol, k = 2L)` ranks matching-anatomy/modality study highest with cosine similarity `> 0.9`.
2. Run RED -> implement `R/embeddings.R` (with DuckDB `vss` detection + pure SQL/vector fallback) -> run GREEN -> `roxygenise()`, commit.

---

### Task 7: `dicomtk-lab --profile ai` Integration & Vignette / Docs
**Files:**
- Modify: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk-lab/docker-compose.yml`
- Modify: `C:/Users/lauye/.gemini/antigravity/scratch/dicomtk-lab/.env.example`
- Create: `vignettes/ai_agents_and_mcp.Rmd`
- Create: `tests/testthat/test-ai-lab.R` (gated on `DICOMTK_TEST_AI=true`)

**Steps:**
1. Add `ollama`, `presidio-analyzer`, `presidio-anonymizer`, `totalsegmentator`, and `monai-label` services under `profiles: ["ai", "all"]` in `dicomtk-lab/docker-compose.yml` (without disturbing existing `core`, `enterprise`, `ehr`, `ohdsi`, `ttp`, `fl` profiles).
2. Write `vignettes/ai_agents_and_mcp.Rmd` demonstrating offline `ai_agent_plan() -> dry_run -> approve -> execute -> verify`, `ai_segment()`, `ai_harmonize_protocol()`, and `ai_search_similar()` with full `unlink()` cleanup.
3. Add env-gated `test-ai-lab.R` verifying REST health checks against `dicomtk-lab` endpoints when `DICOMTK_TEST_AI=true`.

---

### Task 8: `R CMD check --as-cran` Clean Verification & Task 9 Argon High Review + R-universe Publish
**Steps:**
1. Run `roxygen2::roxygenise()`, `tools::showNonASCIIfile()`, `tools::checkRd()`, `pkgdown::check_pkgdown()`, and `testthat::test_local()` (`0 FAIL | 0 WARN`).
2. Run `pkgbuild::build(vignettes = TRUE)` and `R CMD check --as-cran --no-manual` -> verify `0 ERRORs | 0 WARNINGs`.
3. Hand off to **Gemini 4 Argon (High)** for Task 9 Six-Sigma review, GitHub repo setup / push (`lauyeehow1986-hub/dicomtk.ai`), and `lauyeehow1986-hub.r-universe.dev/packages.json` registration!
