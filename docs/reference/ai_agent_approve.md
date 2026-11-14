# Approve a Dry-Run Clinical Imaging Agent Plan

Stage 3 of the agent loop. Requires explicit approval before any
mutation or de-identification output is written.

## Usage

``` r
ai_agent_approve(dry_run, auto_approve = FALSE, approver = NULL)
```

## Arguments

- dry_run:

  A `"dicom_agent_plan"` object at `stage = "dry_run"`.

- auto_approve:

  Logical. Set `TRUE` for non-interactive batch pipelines.

- approver:

  Optional character name/identifier of the approving user.

## Value

Updated `"dicom_agent_plan"` object at `stage = "approved"`.
