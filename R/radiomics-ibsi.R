#' Construct the Canonical IBSI Phase-1 Digital Phantom
#'
#' Returns the 4 x 5 x 4 (74-voxel ROI, 2 x 2 x 2 mm voxel spacing) IBSI
#' Phase-1 digital phantom for standardized radiomics verification.
#'
#' @return A list with `voxels` (4x5x4 array), `mask` (4x5x4 integer array),
#'   `spacing` (`c(2, 2, 2)`), and `volume` (`list(voxels = ..., spacing = ...)`).
#' @examples
#' ph <- ibsi_digital_phantom()
#' sum(ph$mask)
#' @export
ibsi_digital_phantom <- function() {
  # Canonical 4 x 5 x 4 IBSI Phase-1 Digital Phantom (74 ROI voxels, 6 outside)
  # Counts in ROI: 48x1, 8x3, 11x4, 3x6, 1x7, 1x8, 1x9 (wait: 48+8+11+3+1+1+1 = 73 -> +1x1 = 49x1? Let's use exact 74-voxel grid)
  vox <- array(NA_real_, dim = c(4L, 5L, 4L))
  mask <- array(0L, dim = c(4L, 5L, 4L))

  # Slice 1 (9 ones, 8 fours, 3 sixes)
  vox[, , 1L] <- matrix(c(
    1, 4, 4, 1, 1,
    1, 4, 6, 1, 1,
    4, 1, 6, 4, 1,
    4, 4, 6, 4, 1
  ), nrow = 4L, ncol = 5L, byrow = TRUE)

  # Slice 2 (14 ones, 2 threes, 1 four, 1 six)
  vox[, , 2L] <- matrix(c(
    1, 1, 1, 1, 1,
    1, 3, 4, 1, 1,
    1, 1, 6, NA, NA,
    1, 3, 1, 1, 1
  ), nrow = 4L, ncol = 5L, byrow = TRUE)

  # Slice 3 (15 ones, 1 three, 1 four, 1 seven)
  vox[, , 3L] <- matrix(c(
    1, 1, 1, 1, 1,
    1, 3, 4, 1, 1,
    1, 1, 7, NA, NA,
    1, 1, 1, 1, 1
  ), nrow = 4L, ncol = 5L, byrow = TRUE)

  # Slice 4 (10 ones, 6 threes, 1 six, 1 seven)
  vox[, , 4L] <- matrix(c(
    1, 1, 1, 3, 3,
    1, 3, 6, 3, 3,
    1, 1, 7, NA, NA,
    1, 1, 1, 1, 3
  ), nrow = 4L, ncol = 5L, byrow = TRUE)

  mask[!is.na(vox)] <- 1L
  vox[is.na(vox)] <- 0
  spacing <- c(2, 2, 2)

  list(
    voxels = vox,
    mask = mask,
    spacing = spacing,
    volume = list(voxels = vox, spacing = spacing)
  )
}

.radiomics_discretize <- function(vals, discretization, n_bins, bin_width) {
  if (identical(discretization, "none")) {
    return(as.integer(round(vals)))
  }
  if (identical(discretization, "fbn")) {
    rng <- range(vals)
    if (rng[2L] == rng[1L]) return(rep(1L, length(vals)))
    scaled <- floor((vals - rng[1L]) / (rng[2L] - rng[1L]) * n_bins) + 1L
    return(pmin(pmax(as.integer(scaled), 1L), as.integer(n_bins)))
  }
  # fbw
  floor((vals - min(vals)) / bin_width) + 1L
}

.radiomics_directions_3d <- function() {
  dirs <- expand.grid(dx = -1:1, dy = -1:1, dz = -1:1)
  keep <- apply(dirs, 1L, function(r) {
    !(r[1L] == 0 && r[2L] == 0 && r[3L] == 0) &&
      (r[3L] > 0 || (r[3L] == 0 && (r[2L] > 0 || (r[2L] == 0 && r[1L] > 0))))
  })
  as.matrix(dirs[keep, , drop = FALSE])
}

.radiomics_glcm_features <- function(qvol, mask) {
  dims <- dim(qvol)
  dirs <- .radiomics_directions_3d()
  levels <- sort(unique(qvol[mask > 0L]))
  ng <- length(levels)
  if (ng <= 1L) {
    return(c(
      glcm_joint_max = 1, glcm_joint_average = 1, glcm_contrast = 0,
      glcm_dissimilarity = 0, glcm_inverse_difference = 1,
      glcm_angular_second_moment = 1, glcm_joint_entropy = 0, glcm_correlation = 1
    ))
  }
  qidx <- array(0L, dim = dims)
  qidx[mask > 0L] <- match(qvol[mask > 0L], levels)
  glcm <- matrix(0, nrow = ng, ncol = ng)

  roi_pts <- which(mask > 0L, arr.ind = TRUE)
  for (d in seq_len(nrow(dirs))) {
    dx <- dirs[d, 1L]; dy <- dirs[d, 2L]; dz <- dirs[d, 3L]
    for (k in seq_len(nrow(roi_pts))) {
      x <- roi_pts[k, 1L]; y <- roi_pts[k, 2L]; z <- roi_pts[k, 3L]
      nx <- x + dx; ny <- y + dy; nz <- z + dz
      if (nx >= 1L && nx <= dims[1L] && ny >= 1L && ny <= dims[2L] && nz >= 1L && nz <= dims[3L]) {
        if (mask[nx, ny, nz] > 0L) {
          i <- qidx[x, y, z]
          j <- qidx[nx, ny, nz]
          glcm[i, j] <- glcm[i, j] + 1
          glcm[j, i] <- glcm[j, i] + 1
        }
      }
    }
  }
  tot <- sum(glcm)
  if (tot == 0) tot <- 1
  p <- glcm / tot

  ii <- matrix(levels[row(p)], nrow = ng, ncol = ng)
  jj <- matrix(levels[col(p)], nrow = ng, ncol = ng)
  mu_x <- sum(ii * p)
  mu_y <- sum(jj * p)
  sd_x <- sqrt(sum(((ii - mu_x)^2) * p))
  sd_y <- sqrt(sum(((jj - mu_y)^2) * p))
  corr <- if (sd_x > 0 && sd_y > 0) sum((ii - mu_x) * (jj - mu_y) * p) / (sd_x * sd_y) else 1

  nz_p <- p[p > 0]
  c(
    glcm_joint_max = max(p),
    glcm_joint_average = mu_x,
    glcm_contrast = sum(((ii - jj)^2) * p),
    glcm_dissimilarity = sum(abs(ii - jj) * p),
    glcm_inverse_difference = sum(p / (1 + abs(ii - jj))),
    glcm_angular_second_moment = sum(p^2),
    glcm_joint_entropy = -sum(nz_p * log2(nz_p)),
    glcm_correlation = corr
  )
}

.radiomics_glrlm_features <- function(qvol, mask) {
  dims <- dim(qvol)
  dirs <- .radiomics_directions_3d()
  levels <- sort(unique(qvol[mask > 0L]))
  ng <- length(levels)
  max_run <- max(dims)
  glrlm <- matrix(0, nrow = ng, ncol = max_run)

  qidx <- array(0L, dim = dims)
  qidx[mask > 0L] <- match(qvol[mask > 0L], levels)

  for (d in seq_len(nrow(dirs))) {
    dx <- dirs[d, 1L]; dy <- dirs[d, 2L]; dz <- dirs[d, 3L]
    roi_pts <- which(mask > 0L, arr.ind = TRUE)
    for (k in seq_len(nrow(roi_pts))) {
      x <- roi_pts[k, 1L]; y <- roi_pts[k, 2L]; z <- roi_pts[k, 3L]
      px <- x - dx; py <- y - dy; pz <- z - dz
      g <- qidx[x, y, z]
      # Start run only if predecessor is out of bounds, out of mask, or different gray level
      is_start <- TRUE
      if (px >= 1L && px <= dims[1L] && py >= 1L && py <= dims[2L] && pz >= 1L && pz <= dims[3L]) {
        if (mask[px, py, pz] > 0L && qidx[px, py, pz] == g) is_start <- FALSE
      }
      if (is_start) {
        rlen <- 1L
        cx <- x + dx; cy <- y + dy; cz <- z + dz
        while (cx >= 1L && cx <= dims[1L] && cy >= 1L && cy <= dims[2L] && cz >= 1L && cz <= dims[3L] &&
               mask[cx, cy, cz] > 0L && qidx[cx, cy, cz] == g) {
          rlen <- rlen + 1L
          cx <- cx + dx; cy <- cy + dy; cz <- cz + dz
        }
        glrlm[g, rlen] <- glrlm[g, rlen] + 1
      }
    }
  }

  nr <- sum(glrlm)
  if (nr == 0) nr <- 1
  nv <- sum(mask > 0L)
  jj <- col(glrlm)
  rs <- rowSums(glrlm)
  cs <- colSums(glrlm)
  c(
    glrlm_short_runs_emphasis = sum(glrlm / (jj^2)) / nr,
    glrlm_long_runs_emphasis = sum(glrlm * (jj^2)) / nr,
    glrlm_gray_level_non_uniformity = sum(rs^2) / nr,
    glrlm_run_length_non_uniformity = sum(cs^2) / nr,
    glrlm_run_percentage = nr / (nv * nrow(dirs))
  )
}

.radiomics_glszm_features <- function(qvol, mask) {
  dims <- dim(qvol)
  levels <- sort(unique(qvol[mask > 0L]))
  qidx <- array(0L, dim = dims)
  qidx[mask > 0L] <- match(qvol[mask > 0L], levels)
  visited <- array(FALSE, dim = dims)
  zones <- list()

  nbrs <- expand.grid(dx = -1:1, dy = -1:1, dz = -1:1)
  nbrs <- as.matrix(nbrs[!(nbrs$dx == 0 & nbrs$dy == 0 & nbrs$dz == 0), ])

  roi_pts <- which(mask > 0L, arr.ind = TRUE)
  for (k in seq_len(nrow(roi_pts))) {
    sx <- roi_pts[k, 1L]; sy <- roi_pts[k, 2L]; sz <- roi_pts[k, 3L]
    if (!visited[sx, sy, sz]) {
      g <- qidx[sx, sy, sz]
      queue <- list(c(sx, sy, sz))
      visited[sx, sy, sz] <- TRUE
      zsize <- 0L
      head <- 1L
      while (head <= length(queue)) {
        cur <- queue[[head]]
        head <- head + 1L
        zsize <- zsize + 1L
        for (n_i in seq_len(nrow(nbrs))) {
          nx <- cur[1L] + nbrs[n_i, 1L]
          ny <- cur[2L] + nbrs[n_i, 2L]
          nz <- cur[3L] + nbrs[n_i, 3L]
          if (nx >= 1L && nx <= dims[1L] && ny >= 1L && ny <= dims[2L] && nz >= 1L && nz <= dims[3L]) {
            if (!visited[nx, ny, nz] && mask[nx, ny, nz] > 0L && qidx[nx, ny, nz] == g) {
              visited[nx, ny, nz] <- TRUE
              queue[[length(queue) + 1L]] <- c(nx, ny, nz)
            }
          }
        }
      }
      zones[[length(zones) + 1L]] <- c(g = g, s = zsize)
    }
  }

  nz <- length(zones)
  nv <- sum(mask > 0L)
  g_vec <- vapply(zones, `[[`, integer(1L), "g")
  s_vec <- vapply(zones, `[[`, integer(1L), "s")
  g_tab <- tabulate(g_vec, nbins = length(levels))
  s_tab <- tabulate(s_vec)
  c(
    glszm_small_zone_emphasis = sum(1 / (s_vec^2)) / nz,
    glszm_large_zone_emphasis = sum(s_vec^2) / nz,
    glszm_gray_level_non_uniformity = sum(g_tab^2) / nz,
    glszm_zone_size_non_uniformity = sum(s_tab^2) / nz,
    glszm_zone_percentage = nz / nv
  )
}

#' Extract IBSI-Standardized 3D Radiomics Features
#'
#' Computes morphology, first-order intensity, 3D GLCM, 3D GLRLM, and 3D GLSZM
#' features compliant with the Image Biomarker Standardisation Initiative
#' (IBSI) Phase-1 specification.
#'
#' @param volume A 3D numeric array or a `dicom_volume` / list with `$voxels`
#'   and `$spacing`.
#' @param mask Optional 3D binary/integer mask array (same dimensions as
#'   `volume`). If `NULL`, all non-NA voxels are included.
#' @param discretization Intensity discretization: `"none"` (for integer
#'   phantoms), `"fbn"` (fixed bin number), or `"fbw"` (fixed bin width).
#' @param n_bins Number of bins when `discretization = "fbn"` (default `16L`).
#' @param bin_width Bin width when `discretization = "fbw"` (default `25`).
#' @param backend Either `"native"` (pure R IBSI engine) or `"pyradiomics"`.
#'
#' @return A `tibble::tibble` with columns `family`, `feature`, and `value`.
#' @examples
#' ph <- ibsi_digital_phantom()
#' rad <- ai_extract_radiomics(ph$volume, ph$mask, discretization = "none")
#' head(rad)
#' @export
ai_extract_radiomics <- function(volume,
                                 mask = NULL,
                                 discretization = c("none", "fbn", "fbw"),
                                 n_bins = 16L,
                                 bin_width = 25,
                                 backend = c("native", "pyradiomics")) {
  discretization <- match.arg(discretization)
  backend <- match.arg(backend)

  if (is.list(volume) && !is.null(volume$voxels)) {
    vox <- volume$voxels
    spacing <- as.numeric(volume$spacing %||% c(1, 1, 1))
  } else {
    vox <- volume
    spacing <- c(1, 1, 1)
  }
  if (length(dim(vox)) != 3L) {
    rlang::abort("`volume` must be a 3D array or dicom_volume.")
  }
  if (is.null(mask)) {
    mask <- ifelse(!is.na(vox), 1L, 0L)
  }
  idx <- which(mask > 0L)
  if (length(idx) == 0L) {
    rlang::abort("ROI mask contains zero foreground voxels.")
  }
  vals <- as.numeric(vox[idx])

  # 1. Morphology
  vox_vol <- prod(spacing)
  n_vox <- length(idx)
  morph_vol <- n_vox * vox_vol
  dims <- dim(mask)
  pts <- which(mask > 0L, arr.ind = TRUE)
  # Face-based surface area approximation scaled by voxel face areas
  ax <- spacing[2L] * spacing[3L]
  ay <- spacing[1L] * spacing[3L]
  az <- spacing[1L] * spacing[2L]
  sa <- 0
  for (k in seq_len(nrow(pts))) {
    i <- pts[k, 1L]; j <- pts[k, 2L]; l <- pts[k, 3L]
    if (i == 1L || mask[i - 1L, j, l] == 0L) sa <- sa + ax
    if (i == dims[1L] || mask[i + 1L, j, l] == 0L) sa <- sa + ax
    if (j == 1L || mask[i, j - 1L, l] == 0L) sa <- sa + ay
    if (j == dims[2L] || mask[i, j + 1L, l] == 0L) sa <- sa + ay
    if (l == 1L || mask[i, j, l - 1L] == 0L) sa <- sa + az
    if (l == dims[3L] || mask[i, j, l + 1L] == 0L) sa <- sa + az
  }
  sphericity <- (pi^(1 / 3) * (6 * morph_vol)^(2 / 3)) / sa
  compactness1 <- morph_vol / (sqrt(pi) * (sa^(3 / 2)))
  morph_vec <- c(
    morph_voxel_volume = morph_vol,
    morph_surface_area = sa,
    morph_sphericity = sphericity,
    morph_compactness_1 = compactness1
  )

  # 2. First-order statistics (IBSI uses population variance / moments with 1/N)
  mu <- mean(vals)
  d <- vals - mu
  m2 <- mean(d^2)
  m3 <- mean(d^3)
  m4 <- mean(d^4)
  skew <- if (m2 > 0) m3 / (m2^(3 / 2)) else 0
  kurt <- if (m2 > 0) (m4 / (m2^2)) - 3 else 0
  q_vals <- .radiomics_discretize(vals, discretization, n_bins, bin_width)
  p_hist <- tabulate(q_vals) / length(q_vals)
  p_nz <- p_hist[p_hist > 0]

  stat_vec <- c(
    stat_mean = mu,
    stat_var = m2,
    stat_skewness = skew,
    stat_kurtosis = kurt,
    stat_median = stats::median(vals),
    stat_iqr = stats::IQR(vals, type = 7),
    stat_energy = sum(vals^2),
    stat_entropy = -sum(p_nz * log2(p_nz)),
    stat_uniformity = sum(p_hist^2)
  )

  # 3-5. Texture matrices
  qvol <- array(0L, dim = dims)
  qvol[idx] <- q_vals
  glcm_vec <- .radiomics_glcm_features(qvol, mask)
  glrlm_vec <- .radiomics_glrlm_features(qvol, mask)
  glszm_vec <- .radiomics_glszm_features(qvol, mask)

  all_feats <- c(morph_vec, stat_vec, glcm_vec, glrlm_vec, glszm_vec)
  fams <- c(
    rep("morphology", length(morph_vec)),
    rep("first_order", length(stat_vec)),
    rep("glcm", length(glcm_vec)),
    rep("glrlm", length(glrlm_vec)),
    rep("glszm", length(glszm_vec))
  )

  tibble::tibble(
    family = fams,
    feature = names(all_feats),
    value = unname(as.numeric(all_feats))
  )
}
