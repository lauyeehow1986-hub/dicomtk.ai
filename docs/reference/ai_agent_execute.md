# Execute an Approved Clinical Imaging Agent Plan

Stage 4 of the agent loop. Re-verifies the non-weakening guardrail and
executes de-identification and/or QC into `out_dir`.

## Usage

``` r
ai_agent_execute(approved_plan, out_dir)
```

## Arguments

- approved_plan:

  An approved `"dicom_agent_plan"` object.

- out_dir:

  Output directory for de-identified files and provenance logs.

## Value

Updated `"dicom_agent_plan"` object at `stage = "executed"`.
