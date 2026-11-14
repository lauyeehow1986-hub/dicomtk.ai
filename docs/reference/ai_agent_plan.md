# Plan a Guardrailed Clinical Imaging Agent Workflow

Stage 1 of the 5-stage clinical agent loop
(`plan -> dry-run -> approve -> execute -> verify`). Enforces the
non-weakening de-identification guardrail up front.

## Usage

``` r
ai_agent_plan(
  task = c("deid_and_qc", "deid_only", "qc_only"),
  path,
  baseline_profile = dicomtk::dicom_deid_profile(),
  override_tags = list(),
  options = character(0),
  chat = ai_chat("offline")
)
```

## Arguments

- task:

  Workflow task: `"deid_and_qc"`, `"deid_only"`, or `"qc_only"`.

- path:

  Input DICOM file or directory path.

- baseline_profile:

  Baseline
  [`dicomtk::dicom_deid_profile()`](https://lauyeehow1986-hub.github.io/dicomtk/reference/dicom_deid_profile.html)
  object.

- override_tags:

  Optional named list of tag-action overrides (must not weaken
  `baseline_profile`).

- options:

  Optional character vector of PS3.15 options.

- chat:

  A `"dicom_ai_chat"` object from
  [`ai_chat()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_chat.md).

## Value

An S3 `"dicom_agent_plan"` object at `stage = "planned"`.

## Examples

``` r
synth <- dicomtk::dicom_synthesize(modality = "CT", dims = c(8L, 8L, 2L))
on.exit(unlink(synth$out_dir, recursive = TRUE), add = TRUE)
plan <- ai_agent_plan("deid_only", path = synth$out_dir)
#> Error in ai_agent_plan("deid_only", path = synth$out_dir): Input path
#> C:/Users/lauye/AppData/Local/Temp/RtmpGcIm9O/dicom_synth_4b141df214a does not
#> exist.
dry <- ai_agent_dry_run(plan)
#> Error: object 'plan' not found
```
