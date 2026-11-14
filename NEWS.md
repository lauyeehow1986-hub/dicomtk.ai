# dicomtk.ai 0.1.0

* Initial release of `dicomtk.ai`, the AI, MCP, and clinical NLP satellite package for `dicomtk`:
  - `ellmer`-based chat wrapper (`ai_chat()`, `as_ellmer_chat()`) and 5-stage clinical agent loop (`ai_agent_plan()`, `ai_agent_dry_run()`, `ai_agent_approve()`, `ai_agent_execute()`, `ai_agent_verify()`) with unbypassable monotonic de-identification guardrails.
  - Native Model Context Protocol server (`dicomtk_mcp_tools()`, `start_mcp_server()`) powered by `mcptools`.
  - Pluggable AI backend registry (`register_ai_backend()`, `list_ai_backends()`) with segmentation + voxel-wise uncertainty estimation (`ai_segment()`) and `IHE AIR`-aligned `DICOM SEG` + `TID 1500` export (`ai_export_results()`).
  - Clinical report de-identification (`ai_deid_report()`), weak-label extraction (`ai_extract_labels()`), and `RadLex` / `LOINC-RSNA` protocol harmonisation (`ai_harmonize_protocol()`, `radlex_playbook`).
  - Foundation study embeddings and `DuckDB` similar-case retrieval (`ai_embed()`, `ai_embedding_index()`, `ai_index_add()`, `ai_search_similar()`).
