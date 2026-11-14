# dicomtk.ai 0.2.0

* **IBSI Phase-1 Radiomics (`R/radiomics-ibsi.R`)**: Added `ibsi_digital_phantom()` and `ai_extract_radiomics()` computing morphology, first-order intensity, 3D GLCM, 3D GLRLM, and 3D GLSZM features.
* **Train/Test-Safe ComBat Harmonisation (`R/combat.R`)**: Added `combat_fit()`, `combat_apply()`, and `ai_combat_harmonize()` for Empirical Bayes scanner batch harmonisation without test-set leakage.
* **MONAI MAISI Synthetic Data (`R/maisi-synthetic.R`)**: Added `ai_generate_maisi()` for 3D synthetic CT DICOM series + multi-organ label masks with `DERIVED\\SECONDARY\\SYNTHETIC` provenance tagging.

# dicomtk.ai 0.1.0

* Initial release of `dicomtk.ai`, the AI, MCP, and clinical NLP satellite package for `dicomtk`:
  - `ellmer`-based chat wrapper (`ai_chat()`, `as_ellmer_chat()`) and 5-stage clinical agent loop (`ai_agent_plan()`, `ai_agent_dry_run()`, `ai_agent_approve()`, `ai_agent_execute()`, `ai_agent_verify()`) with unbypassable monotonic de-identification guardrails.
  - Native Model Context Protocol server (`dicomtk_mcp_tools()`, `start_mcp_server()`) powered by `mcptools`.
  - Pluggable AI backend registry (`register_ai_backend()`, `list_ai_backends()`) with segmentation + voxel-wise uncertainty estimation (`ai_segment()`) and `IHE AIR`-aligned `DICOM SEG` + `TID 1500` export (`ai_export_results()`).
  - Clinical report de-identification (`ai_deid_report()`), weak-label extraction (`ai_extract_labels()`), and `RadLex` / `LOINC-RSNA` protocol harmonisation (`ai_harmonize_protocol()`, `radlex_playbook`).
  - Foundation study embeddings and `DuckDB` similar-case retrieval (`ai_embed()`, `ai_embedding_index()`, `ai_index_add()`, `ai_search_similar()`).
