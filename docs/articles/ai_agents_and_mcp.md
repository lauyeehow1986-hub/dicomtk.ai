# Clinical AI Agents, MCP Tooling, and Vector Search with dicomtk.ai

## Overview

`dicomtk.ai` extends `dicomtk` with `ellmer`-based clinical imaging
agents, a Model Context Protocol (`MCP`) server via `mcptools`,
pluggable AI segmentation backends with uncertainty maps, clinical
report NLP, `RadLex` / `LOINC-RSNA` protocol harmonisation, and `DuckDB`
vector similarity search.

## 1. Guardrailed 5-Stage Agent Workflow

Every de-identification workflow enforces the PS3.15 monotonic
join-semilattice (`K < C < U < D < Z < X`), preventing any LLM or caller
from weakening the baseline profile:

[`library`](https://rdrr.io/r/base/library.html)`(`[`dicomtk`](https://github.com/lauyeehow1986-hub/dicomtk)`)`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`dicomtk.ai`](https://lauyeehow1986-hub.github.io/dicomtk.ai/)`)`` `` ``synth`` ``<-`` `[`dicom_synthesize`](https://lauyeehow1986-hub.github.io/dicomtk/reference/dicom_synthesize.html)`(``modality ``=`` ``"CT"``, dims ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``16L``, ``16L``, ``4L``)``, phi_profile ``=`` ``"basic"``)`` ``out_dir`` ``<-`` `[`tempfile`](https://rdrr.io/r/base/tempfile.html)`(``"ai_vignette_out_"``)`` `` ``plan`` ``<-`` `[`ai_agent_plan`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_plan.md)`(`` `` task ``=`` ``"deid_and_qc"``,`` `` path ``=`` ``synth``[[``"out_dir"``]``]``,`` `` baseline_profile ``=`` `[`dicom_deid_profile`](https://lauyeehow1986-hub.github.io/dicomtk/reference/dicom_deid_profile.html)`(``"ps3.15"``)``,`` `` chat ``=`` `[`ai_chat`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_chat.md)`(``"offline"``)`` ``)`` ``dry`` ``<-`` `[`ai_agent_dry_run`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_dry_run.md)`(``plan``)`` ``approved`` ``<-`` `[`ai_agent_approve`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_approve.md)`(``dry``, auto_approve ``=`` ``TRUE``, approver ``=`` ``"vignette"``)`` ``exec_res`` ``<-`` `[`ai_agent_execute`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_execute.md)`(``approved``, out_dir ``=`` ``out_dir``)`` ``ver`` ``<-`` `[`ai_agent_verify`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_verify.md)`(``exec_res``)`` ``ver``$``passed`` ``#> [1] TRUE`

## 2. Protocol Harmonisation & Weak-Label Extraction

`hdrs`` ``<-`` ``tibble``::`[`tibble`](https://tibble.tidyverse.org/reference/tibble.html)`(`` `` SeriesDescription ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"CHEST WO CON 3.0mm"``, ``"BRAIN_T1_POST_GAD"``)``,`` `` Modality ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"CT"``, ``"MR"``)``,`` `` BodyPartExamined ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"CHEST"``, ``"HEAD"``)`` ``)`` `[`ai_harmonize_protocol`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_harmonize_protocol.md)`(``hdrs``)`` ``#> ``# A tibble: 2 × 9`` ``#> SeriesDescription Modality rpid long_common_name short_name body_region`` ``#> ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` ``<chr>`` `` ``#> ``1`` CHEST WO CON 3.0mm CT RPID29 CT Chest WO contra… CT Chest … CHEST `` ``#> ``2`` BRAIN_T1_POST_GAD MR RPID102 MR Brain WO and W … MR Brain … HEAD `` ``#> ``# ℹ 3 more variables: radlex_id <chr>, contrast <lgl>, confidence <dbl>`

## 3. Cleanup
