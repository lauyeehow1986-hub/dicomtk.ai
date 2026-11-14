# Package index

## ellmer Agents & Non-Weakening Guardrails

5-stage clinical agent loop, ellmer chat adapters, and monotonic PS3.15
lattice enforcement.

- [`ai_chat()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_chat.md)
  :

  Configure an `ellmer`-Backed Chat Session for `dicomtk.ai`

- [`as_ellmer_chat()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/as_ellmer_chat.md)
  :

  Convert a Legacy
  [`dicomtk::dicom_llm`](https://lauyeehow1986-hub.github.io/dicomtk/reference/dicom_llm.html)
  Object to `dicom_ai_chat`

- [`enforce_non_weakening_profile()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/enforce_non_weakening_profile.md)
  : Enforce Non-Weakening Monotonic De-Identification Guardrail

- [`ai_agent_plan()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_plan.md)
  : Plan a Guardrailed Clinical Imaging Agent Workflow

- [`ai_agent_dry_run()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_dry_run.md)
  : Dry-Run a Planned Clinical Imaging Agent Workflow

- [`ai_agent_approve()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_approve.md)
  : Approve a Dry-Run Clinical Imaging Agent Plan

- [`ai_agent_execute()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_execute.md)
  : Execute an Approved Clinical Imaging Agent Plan

- [`ai_agent_verify()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_verify.md)
  : Verify Executed Clinical Imaging Agent Outputs

## MCP Server (mcptools)

Expose dicomtk and dicomtk.ai tools to Antigravity, Claude Desktop, and
headless MCP clients.

- [`dicomtk_mcp_tools()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/dicomtk_mcp_tools.md)
  :

  Build `ellmer` Tool Definitions for the `dicomtk.ai` MCP Server

- [`start_mcp_server()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/start_mcp_server.md)
  :

  Start the `dicomtk.ai` Model Context Protocol (MCP) Server

## Segmentation Backends, Uncertainty & IHE AIR

Pluggable model registry, voxel-wise entropy uncertainty, and DICOM
SEG + TID 1500 export.

- [`register_ai_backend()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/register_ai_backend.md)
  : Register a Pluggable AI Backend
- [`get_ai_backend()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/get_ai_backend.md)
  : Retrieve a Registered AI Backend
- [`list_ai_backends()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/list_ai_backends.md)
  : List Registered AI Backends
- [`ai_backend_health()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_backend_health.md)
  : Check Health of a Registered AI Backend
- [`ai_segment()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_segment.md)
  : Run Pluggable AI Segmentation With Uncertainty Estimation
- [`ai_export_results()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_export_results.md)
  : Export AI Segmentation Results in IHE AIR Standardized DICOM Format

## Clinical NLP & Protocol Harmonisation

Report de-identification, ConText weak-label extraction, and RadLex /
LOINC-RSNA mapping.

- [`ai_deid_report()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_deid_report.md)
  : De-Identify Free-Text Radiology Reports or Structured Reports
- [`ai_extract_labels()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_extract_labels.md)
  : Extract Weak Clinical Labels From Radiology Report Text
- [`ai_harmonize_protocol()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_harmonize_protocol.md)
  : Harmonise Messy DICOM Series Descriptions to RadLex and LOINC-RSNA
  Playbook
- [`radlex_playbook`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/radlex_playbook.md)
  : Curated LOINC-RSNA Radiology Playbook and RadLex Protocol Table

## Embeddings & DuckDB Vector Search

Study-level embeddings and cosine similarity retrieval.

- [`ai_embed()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_embed.md)
  : Extract a Normalized Study Embedding Vector
- [`ai_embedding_index()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_embedding_index.md)
  : Open or Initialize a DuckDB Study Embedding Index
- [`ai_index_add()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_index_add.md)
  : Add a Study Volume to a DuckDB Embedding Index
- [`ai_search_similar()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_search_similar.md)
  : Retrieve Top-K Similar Studies From a DuckDB Embedding Index
- [`ai_index_close()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_index_close.md)
  : Close a DuckDB Study Embedding Index

## IBSI Radiomics, ComBat & MAISI Synthetic Data

IBSI Phase-1 standardized 3D radiomics, Empirical Bayes ComBat
harmonisation, and MONAI MAISI 3D synthetic CT + masks.

- [`ibsi_digital_phantom()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ibsi_digital_phantom.md)
  : Construct the Canonical IBSI Phase-1 Digital Phantom
- [`ai_extract_radiomics()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_extract_radiomics.md)
  : Extract IBSI-Standardized 3D Radiomics Features
- [`combat_fit()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/combat_fit.md)
  : Fit Train/Test-Safe Empirical Bayes ComBat Harmonisation Parameters
- [`combat_apply()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/combat_apply.md)
  : Apply Fitted ComBat Harmonisation Parameters Without Test-Set
  Leakage
- [`ai_combat_harmonize()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_combat_harmonize.md)
  : Fit and Apply Empirical Bayes ComBat Harmonisation
- [`ai_generate_maisi()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_generate_maisi.md)
  : Generate MONAI MAISI 3D Synthetic CT and Multi-Organ Label Masks
