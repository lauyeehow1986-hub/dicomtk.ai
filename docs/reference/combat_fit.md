# Fit Train/Test-Safe Empirical Bayes ComBat Harmonisation Parameters

Estimates batch location and scale parameters on a training cohort while
preserving biological covariates (`mod`). Apply the resulting fit to
training or held-out test cohorts with
[`combat_apply()`](https://lauyeehow1986-hub.github.io/dicomtk.ai/reference/combat_apply.md)
without test-set leakage.

## Usage

``` r
combat_fit(features, batch, mod = NULL, eb = TRUE, ref_batch = NULL)
```

## Arguments

- features:

  Numeric matrix (`n_features x n_samples`).

- batch:

  Factor or character vector of scanner/site batch labels of length
  `ncol(features)`.

- mod:

  Optional biological covariate design matrix (`n_samples x q`, e.g.
  from `model.matrix(~ age + sex)`).

- eb:

  Logical; if `TRUE` (default), applies Empirical Bayes shrinkage across
  features.

- ref_batch:

  Optional reference batch name.

## Value

An S3 `"dicom_combat_fit"` object.
