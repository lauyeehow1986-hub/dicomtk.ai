# Check Health of a Registered AI Backend

Probes a registered backend's readiness (`"offline_ready"` for offline
backends, or HTTP GET `/health` / base URL for REST backends).

## Usage

``` r
ai_backend_health(name, timeout_sec = 3)
```

## Arguments

- name:

  Backend name.

- timeout_sec:

  HTTP timeout in seconds for REST backends (default `3`).

## Value

A list with `name`, `mode`, `status`, and `endpoint`.
