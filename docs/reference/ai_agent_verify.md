# Verify Executed Clinical Imaging Agent Outputs

Stage 5 of the agent loop. Runs
[`dicomtk::dicom_deid_verify()`](https://lauyeehow1986-hub.github.io/dicomtk/reference/dicom_deid_verify.html)
on the executed output directory to confirm zero residual PHI leakage.

## Usage

``` r
ai_agent_verify(exec_result)
```

## Arguments

- exec_result:

  A `"dicom_agent_plan"` object at `stage = "executed"`.

## Value

Updated `"dicom_agent_plan"` object at `stage = "verified"` with
`$passed` logical status.
