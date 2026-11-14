# Apply Fitted ComBat Harmonisation Parameters Without Test-Set Leakage

Apply Fitted ComBat Harmonisation Parameters Without Test-Set Leakage

## Usage

``` r
combat_apply(fit, features, batch, mod = NULL)
```

## Arguments

- fit:

  A `"dicom_combat_fit"` from
  [`combat_fit()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/combat_fit.md).

- features:

  Numeric matrix (`n_features x n_samples`).

- batch:

  Factor or character vector of batch labels matching
  `fit$batch_levels`.

- mod:

  Optional biological covariate matrix (`n_samples x q`).

## Value

Harmonized numeric matrix of dimensions `dim(features)`.
