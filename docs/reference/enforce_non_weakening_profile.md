# Enforce Non-Weakening Monotonic De-Identification Guardrail

Validates or clamps any agent-proposed overrides, options, or policy
flags against a baseline
[`dicomtk::dicom_deid_profile()`](https://lauyeehow1986-hub.github.io/dicomtk/reference/dicom_deid_profile.html)
along the strict PS3.15 join-semilattice `K < C < U < D < Z < X`.

## Usage

``` r
enforce_non_weakening_profile(
  baseline,
  override_tags = list(),
  options = character(0),
  jurisdictions = NULL,
  deidentify = NULL,
  patient_deid = NULL,
  mode = c("reject", "clamp")
)
```

## Arguments

- baseline:

  A baseline `dicom_deid_profile` object.

- override_tags:

  Named list of tag-action overrides.

- options:

  Character vector of additional PS3.15 options.

- jurisdictions:

  Optional character vector of additional jurisdictions.

- deidentify:

  Optional logical flag override.

- patient_deid:

  Optional logical flag override.

- mode:

  `"reject"` (default; throws an error on any weakening attempt) or
  `"clamp"` (clamps every tag and flag to at least baseline strength).

## Value

A validated (or monotonically clamped) `dicom_deid_profile` object.

## Examples

``` r
base <- dicomtk::dicom_deid_profile("ps3.15")
stronger <- enforce_non_weakening_profile(base, override_tags = list("(0008,1030)" = "X"))
```
