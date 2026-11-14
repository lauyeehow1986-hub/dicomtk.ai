# Changelog

## dicomtk.ai 0.2.0

- **IBSI Phase-1 Radiomics (`R/radiomics-ibsi.R`)**: Added
  [`ibsi_digital_phantom()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ibsi_digital_phantom.md)
  and
  [`ai_extract_radiomics()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_extract_radiomics.md)
  computing morphology, first-order intensity, 3D GLCM, 3D GLRLM, and 3D
  GLSZM features.
- **Train/Test-Safe ComBat Harmonisation (`R/combat.R`)**: Added
  [`combat_fit()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/combat_fit.md),
  [`combat_apply()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/combat_apply.md),
  and
  [`ai_combat_harmonize()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_combat_harmonize.md)
  for Empirical Bayes scanner batch harmonisation without test-set
  leakage.
- **MONAI MAISI Synthetic Data (`R/maisi-synthetic.R`)**: Added
  [`ai_generate_maisi()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_generate_maisi.md)
  for 3D synthetic CT DICOM series + multi-organ label masks with
  `DERIVED\\SECONDARY\\SYNTHETIC` provenance tagging.

## dicomtk.ai 0.1.0

- Initial release of `dicomtk.ai`, the AI, MCP, and clinical NLP
  satellite package for `dicomtk`:
  - `ellmer`-based chat wrapper
    ([`ai_chat()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_chat.md),
    [`as_ellmer_chat()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/as_ellmer_chat.md))
    and 5-stage clinical agent loop
    ([`ai_agent_plan()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_plan.md),
    [`ai_agent_dry_run()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_dry_run.md),
    [`ai_agent_approve()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_approve.md),
    [`ai_agent_execute()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_execute.md),
    [`ai_agent_verify()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_verify.md))
    with unbypassable monotonic de-identification guardrails.
  - Native Model Context Protocol server
    ([`dicomtk_mcp_tools()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/dicomtk_mcp_tools.md),
    [`start_mcp_server()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/start_mcp_server.md))
    powered by `mcptools`.
  - Pluggable AI backend registry
    ([`register_ai_backend()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/register_ai_backend.md),
    [`list_ai_backends()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/list_ai_backends.md))
    with segmentation + voxel-wise uncertainty estimation
    ([`ai_segment()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_segment.md))
    and `IHE AIR`-aligned `DICOM SEG` + `TID 1500` export
    ([`ai_export_results()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_export_results.md)).
  - Clinical report de-identification
    ([`ai_deid_report()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_deid_report.md)),
    weak-label extraction
    ([`ai_extract_labels()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_extract_labels.md)),
    and `RadLex` / `LOINC-RSNA` protocol harmonisation
    ([`ai_harmonize_protocol()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_harmonize_protocol.md),
    `radlex_playbook`).
  - Foundation study embeddings and `DuckDB` similar-case retrieval
    ([`ai_embed()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_embed.md),
    [`ai_embedding_index()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_embedding_index.md),
    [`ai_index_add()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_index_add.md),
    [`ai_search_similar()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_search_similar.md)).
