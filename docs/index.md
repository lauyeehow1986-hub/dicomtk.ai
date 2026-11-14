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

[`library`](https://rdrr.io/r/base/library.html)`(`[`dicomtk.ai`](https://lauyeehow1986-hub.github.io/dicomtk.ai/)`)`` `` ``# The non-weakening guardrail prevents an LLM from disabling PS3.15 de-id,`` ``# lowering pixel-cleaning confidence, or skipping attestation verification.`` ``guard`` ``<-`` ``ai_guardrail_policy``(``strict ``=`` ``TRUE``)`` ``agent`` ``<-`` ``dicom_agent_create``(``policy ``=`` ``guard``, backend ``=`` ``"offline"``)`

### 2. AI Segmentation, Uncertainty Quantification & `IHE AIR` Export

`# Register or select an AI segmentation backend (offline demo or REST/MONAI)`` ``reg`` ``<-`` ``ai_backend_registry``(``)`` ``# seg_res <- ai_segment_volume(vol, model = "offline_demo", return_uncertainty = TRUE)`` ``# air_bundle <- export_ihe_air(seg_res)`

### 3. Clinical NLP: Report De-Identification, Weak Labels & Protocol Harmonisation

`report`` ``<-`` ``"Patient John Tan (NRIC S8512345A) underwent CT Thorax on 2026-04-12. Impression: 12mm RUL nodule."`` ``deid_rep`` ``<-`` ``nlp_deid_report``(``report``)`` ``deid_rep``$``redacted_text`` `` ``# Extract weak clinical labels & harmonize acquisition protocol names to RadLex`` ``nlp_extract_labels``(``deid_rep``$``redacted_text``)`` ``harmonize_protocol``(``"CT CHEST W/O IV CONT"``)`

### 4. Foundation Embeddings & DuckDB Similar-Case Retrieval

`# Store 3D study embeddings in DuckDB and retrieve top-k similar cases`` ``idx`` ``<-`` ``embed_index_create``(``)`` ``embed_index_add``(``idx``, study_id ``=`` ``"STUDY_001"``, vector ``=`` `[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``64``)``)`` ``embed_index_search``(``idx``, query_vector ``=`` `[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``64``)``, k ``=`` ``5L``)`

### 5. IBSI Phase-1 Standardized 3D Radiomics Engine

`# Verify against the built-in IBSI Phase-1 digital phantom`` ``ibsi_res`` ``<-`` ``radiomics_verify_ibsi_phantom``(``)`` ``ibsi_res``$``passed`` `` ``# Extract 5 feature families (Intensity, Shape, GLCM, GLRLM, GLSZM)`` ``# feats <- extract_radiomics_3d(vol, mask, bin_width = 25)`

### 6. Train/Test-Safe Empirical Bayes ComBat Harmonisation

[`set.seed`](https://rdrr.io/r/base/Random.html)`(``42``)`` ``train_feat`` ``<-`` `[`matrix`](https://rdrr.io/r/base/matrix.html)`(`[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``120`` ``*`` ``10``)``, nrow ``=`` ``120``)`` ``train_batch`` ``<-`` `[`rep`](https://rdrr.io/r/base/rep.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"SCANNER_A"``, ``"SCANNER_B"``)``, each ``=`` ``60``)`` `` ``# Fit ComBat ONLY on training data, then apply to held-out test data (zero leakage)`` ``fit`` ``<-`` `[`combat_fit`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/combat_fit.md)`(``train_feat``, batch ``=`` ``train_batch``)`` ``train_harm`` ``<-`` `[`combat_apply`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/combat_apply.md)`(``fit``, ``train_feat``, batch ``=`` ``train_batch``)`

### 7. MONAI MAISI-Style 3D Synthetic CT & Multi-Organ Mask Generator

`syn`` ``<-`` ``maisi_generate_ct``(``dim ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``64L``, ``64L``, ``32L``)``, seed ``=`` ``2026L``)`` `[`dim`](https://rdrr.io/r/base/dim.html)`(``syn``$``ct_volume``$``voxels``)`` `[`table`](https://rdrr.io/r/base/table.html)`(``syn``$``organ_mask``)`

### 8. Documentation

Browse the full reference at
<https://lauyeehow1986-hub.github.io/dicomtk.ai/>.
