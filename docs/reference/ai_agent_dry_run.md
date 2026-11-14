# Dry-Run a Planned Clinical Imaging Agent Workflow

Stage 2 of the agent loop. Evaluates effective tag actions and optional
image QC without writing or mutating any files on disk.

## Usage

``` r
ai_agent_dry_run(plan)
```

## Arguments

- plan:

  A `"dicom_agent_plan"` object from
  [`ai_agent_plan()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_agent_plan.md).

## Value

Updated `"dicom_agent_plan"` object at `stage = "dry_run"`.
