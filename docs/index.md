# dicomtk.ai: Guardrailed AI, Clinical NLP, Radiomics & Synthetic Imaging for ‘DICOM’

`dicomtk.ai` (`0.2.0`) is the AI, radiomics, and clinical NLP satellite
package for [`dicomtk`](https://lauyeehow1986-hub.github.io/dicomtk/).
It provides a non-weakening 5-stage `ellmer` agent loop, a native Model
Context Protocol (`MCP`) server, pluggable segmentation backends
(`IHE AIR`), clinical report de-identification, DuckDB
foundation-embedding search, an IBSI Phase-1 standardized 3D radiomics
engine, train/test-safe ComBat harmonisation, and MONAI MAISI-style 3D
synthetic CT + multi-organ mask generation.

------------------------------------------------------------------------

## Installation

[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(`` `` ``"dicomtk.ai"``,`` `` repos ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``"https://lauyeehow1986-hub.r-universe.dev"``,`` `` ``"https://cloud.r-project.org"`` `` ``)`` ``)`

Or install from GitHub:

`remotes``::`[`install_github`](https://remotes.r-lib.org/reference/install_github.html)`(``"lauyeehow1986-hub/dicomtk.ai"``)`

------------------------------------------------------------------------

## How to Use `dicomtk.ai`

### 1. Guardrailed 5-Stage Agent Loop (`ellmer`)

[`library`](https://rdrr.io/r/base/library.html)`(`[`dicomtk.ai`](https://lauyeehow1986-hub.github.io/dicomtk.ai/)`)`` `` ``# The non-weakening guardrail prevents an LLM from disabling PS3.15 de-id,`` ``# lowering pixel-cleaning confidence, or skipping attestation verification.`` ``profile`` ``<-`` `[`enforce_non_weakening_profile`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/enforce_non_weakening_profile.md)`(`` `` requested ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``jurisdiction ``=`` ``"HIPAA"``, verify_attestation ``=`` ``TRUE``)``,`` `` baseline ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``jurisdiction ``=`` ``"HIPAA"``, verify_attestation ``=`` ``TRUE``)`` ``)`` ``# 5-stage pipeline: ai_agent_plan() -> ai_agent_dry_run() -> ai_agent_approve() -> ai_agent_execute() -> ai_agent_verify()`

### 2. AI Segmentation, Uncertainty Quantification & `IHE AIR` Export

[`list_ai_backends`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/list_ai_backends.md)`(``)`` ``# seg_res <- ai_segment(vol, backend = "offline_demo")`` ``# air_bundle <- ai_export_results(seg_res, format = "ihe_air")`

### 3. Clinical NLP: Report De-Identification, Weak Labels & Protocol Harmonisation

`report`` ``<-`` ``"Patient John Tan (NRIC S8512345A) underwent CT Thorax on 2026-04-12. Impression: 12mm RUL nodule."`` ``deid_rep`` ``<-`` `[`ai_deid_report`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_deid_report.md)`(``report``)`` ``deid_rep``$``redacted_text`` `` ``# Extract weak clinical labels & harmonize acquisition protocol names to RadLex`` `[`ai_extract_labels`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_extract_labels.md)`(``deid_rep``$``redacted_text``)`` `[`ai_harmonize_protocol`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_harmonize_protocol.md)`(``"CT CHEST W/O IV CONT"``)`

### 4. Foundation Embeddings & DuckDB Similar-Case Retrieval

`idx`` ``<-`` `[`ai_embedding_index`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_embedding_index.md)`(``)`` `[`ai_index_add`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_index_add.md)`(``idx``, study_id ``=`` ``"STUDY_001"``, embedding ``=`` `[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``64``)``)`` `[`ai_search_similar`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_search_similar.md)`(``idx``, query_embedding ``=`` `[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``64``)``, top_k ``=`` ``5L``)`` `[`ai_index_close`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_index_close.md)`(``idx``)`

### 5. IBSI Phase-1 Standardized 3D Radiomics Engine

`# Verify against the built-in IBSI Phase-1 digital phantom`` ``phantom`` ``<-`` `[`ibsi_digital_phantom`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ibsi_digital_phantom.md)`(``)`` ``feats`` ``<-`` `[`ai_extract_radiomics`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_extract_radiomics.md)`(``phantom``$``volume``, ``phantom``$``mask``, discretization ``=`` ``"none"``)`

### 6. Train/Test-Safe Empirical Bayes ComBat Harmonisation

[`set.seed`](https://rdrr.io/r/base/Random.html)`(``42``)`` ``train_feat`` ``<-`` `[`matrix`](https://rdrr.io/r/base/matrix.html)`(`[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``120`` ``*`` ``10``)``, nrow ``=`` ``120``)`` ``train_batch`` ``<-`` `[`rep`](https://rdrr.io/r/base/rep.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"SCANNER_A"``, ``"SCANNER_B"``)``, each ``=`` ``60``)`` `` ``# Fit ComBat ONLY on training data, then apply to held-out test data (zero leakage)`` ``fit`` ``<-`` `[`combat_fit`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/combat_fit.md)`(``train_feat``, batch ``=`` ``train_batch``)`` ``train_harm`` ``<-`` `[`combat_apply`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/combat_apply.md)`(``fit``, ``train_feat``, batch ``=`` ``train_batch``)`

### 7. MONAI MAISI-Style 3D Synthetic CT & Multi-Organ Mask Generator

`syn`` ``<-`` `[`ai_generate_maisi`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_generate_maisi.md)`(``dim ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``64L``, ``64L``, ``32L``)``, seed ``=`` ``2026L``)`` `[`dim`](https://rdrr.io/r/base/dim.html)`(``syn``$``volume``$``voxels``)`` `[`table`](https://rdrr.io/r/base/table.html)`(``syn``$``mask``)`

### 8. Documentation

Browse the full reference at
<https://lauyeehow1986-hub.github.io/dicomtk.ai/>.
