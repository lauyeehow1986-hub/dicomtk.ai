# Export AI Segmentation Results in IHE AIR Standardized DICOM Format

Writes segmentation masks as a DICOM SEG object (`write_dicom_seg()`)
and quantitative summary metrics as a DICOM TID 1500 Measurement Report
(`dicom_sr_tid1500()`), aligned with IHE AI Results (AIR) conventions.

## Usage

``` r
ai_export_results(
  seg_res,
  vol,
  out_dir,
  title = "IHE AIR AI Segmentation Report"
)
```

## Arguments

- seg_res:

  A `"dicom_ai_segmentation"` object from
  [`ai_segment()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/ai_segment.md),
  or a `dicom_seg` object.

- vol:

  Reference `dicom_volume` object.

- out_dir:

  Output directory for standardized DICOM files.

- title:

  Report title for the TID 1500 Measurement Report.

## Value

Invisibly returns a list with `seg_path`, `sr_path`, `out_dir`, and
`metrics`.
