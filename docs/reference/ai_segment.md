# Run Pluggable AI Segmentation With Uncertainty Estimation

Runs segmentation via a registered backend (`"totalsegmentator"`,
`"nnunet"`, `"vista3d"`, `"medsam2"`, or custom registered backends),
aligns the mask to the reference `dicom_volume`, and optionally computes
voxel-wise Shannon entropy uncertainty and Dice agreement.

## Usage

``` r
ai_segment(
  vol,
  backend = "totalsegmentator",
  prompts = NULL,
  estimate_uncertainty = TRUE,
  reference_seg = NULL
)
```

## Arguments

- vol:

  A `dicom_volume` object or path to a DICOM file/directory.

- backend:

  Registered segmentation backend name.

- prompts:

  Optional prompt list for interactive models such as `"medsam2"` (e.g.,
  `list(points = matrix(c(r, c, s), ncol = 3))`).

- estimate_uncertainty:

  Logical. Compute voxel-wise entropy map (`TRUE` by default).

- reference_seg:

  Optional reference `dicom_seg` for Dice evaluation.

## Value

A list of class `"dicom_ai_segmentation"` with `seg` (`dicom_seg`),
`uncertainty` (`dicom_volume` or `NULL`), `probs`, `metrics`, and
`backend`.
