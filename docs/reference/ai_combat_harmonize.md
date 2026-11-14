# Fit and Apply Empirical Bayes ComBat Harmonisation

Fit and Apply Empirical Bayes ComBat Harmonisation

## Usage

``` r
ai_combat_harmonize(features, batch, mod = NULL, eb = TRUE, ref_batch = NULL)
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

A list with `harmonized` (harmonized matrix) and `fit`
(`"dicom_combat_fit"`).

## Examples

``` r
set.seed(1)
mat <- matrix(rnorm(40), nrow = 4, ncol = 10)
b <- rep(c("A", "B"), each = 5)
res <- ai_combat_harmonize(mat, b)
dim(res$harmonized)
#> [1]  4 10
```
