# Curated LOINC-RSNA Radiology Playbook and RadLex Protocol Table

A compact reference dataset of common diagnostic imaging protocols
across `CT`, `MR`, `PT`, `NM`, `DX`, `MG`, `US`, and `XA` modalities
mapped to LOINC-RSNA Radiology Playbook IDs (`rpid`) and `RadLex`
anatomical region identifiers (`radlex_id`).

## Usage

``` r
radlex_playbook
```

## Format

A tibble with 46 rows and 8 variables:

- rpid:

  LOINC-RSNA Radiology Playbook identifier.

- long_common_name:

  Standardized long protocol name.

- short_name:

  Abbreviated display name.

- modality:

  DICOM Modality code.

- body_region:

  Normalized anatomical region.

- radlex_id:

  RadLex anatomical identifier (`RID...`).

- contrast:

  Logical indicating IV/radiotracer contrast usage.

- keywords:

  Space-delimited matching keywords.

## Source

Curated subset of LOINC-RSNA Radiology Playbook and RadLex ontology.
