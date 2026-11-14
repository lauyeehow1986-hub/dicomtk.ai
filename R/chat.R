#' Configure an `ellmer`-Backed Chat Session for `dicomtk.ai`
#'
#' Creates a `"dicom_ai_chat"` object wrapping an `ellmer` chat client (or a
#' deterministic `"offline"` rule-based planner for CI and air-gapped testing).
#'
#' @param provider Chat provider: `"offline"`, `"ollama"`, `"openai"`,
#'   `"anthropic"`, `"gemini"`, or `"openai_compatible"`.
#' @param model Optional model identifier.
#' @param base_url Optional API base URL (used for `"ollama"` and
#'   `"openai_compatible"`).
#' @param api_key Optional API key (defaults to standard provider environment
#'   variables).
#' @param system_prompt Optional system prompt string.
#' @param ... Additional arguments passed to the underlying `ellmer` chat
#'   constructor.
#'
#' @return An object of class `"dicom_ai_chat"`.
#' @export
ai_chat <- function(provider = c("offline", "ollama", "openai", "anthropic", "gemini", "openai_compatible"),
                    model = NULL,
                    base_url = NULL,
                    api_key = NULL,
                    system_prompt = NULL,
                    ...) {
  provider <- match.arg(provider)
  sys_p <- system_prompt %||% paste(
    "You are a clinical medical imaging AI orchestrator.",
    "Never weaken DICOM de-identification profiles or fabricate findings."
  )

  if (identical(provider, "offline")) {
    return(structure(
      list(
        provider = "offline",
        model = model %||% "offline-rule-engine",
        system_prompt = sys_p,
        ellmer_chat = NULL
      ),
      class = "dicom_ai_chat"
    ))
  }

  ell_chat <- switch(provider,
    ollama = ellmer::chat_ollama(
      system_prompt = sys_p,
      base_url = base_url %||% Sys.getenv("OLLAMA_BASE_URL", "http://localhost:11434"),
      model = model %||% "llama3.2:3b",
      ...
    ),
    openai = ellmer::chat_openai(
      system_prompt = sys_p,
      model = model %||% "gpt-4o",
      ...
    ),
    anthropic = ellmer::chat_anthropic(
      system_prompt = sys_p,
      model = model %||% "claude-sonnet-4-20250514",
      ...
    ),
    gemini = ellmer::chat_google_gemini(
      system_prompt = sys_p,
      model = model %||% "gemini-2.5-flash",
      ...
    ),
    openai_compatible = ellmer::chat_openai_compatible(
      system_prompt = sys_p,
      base_url = base_url %||% Sys.getenv("OPENAI_BASE_URL", "http://localhost:8000/v1"),
      model = model %||% "gpt-4o",
      ...
    )
  )

  structure(
    list(
      provider = provider,
      model = model %||% "default",
      system_prompt = sys_p,
      ellmer_chat = ell_chat
    ),
    class = "dicom_ai_chat"
  )
}

#' Convert a Legacy `dicomtk::dicom_llm` Object to `dicom_ai_chat`
#'
#' @param x A `dicom_llm`, `dicom_ai_chat`, or `ellmer` `Chat` object.
#' @return A `"dicom_ai_chat"` object.
#' @export
as_ellmer_chat <- function(x) {
  if (inherits(x, "dicom_ai_chat")) {
    return(x)
  }
  if (inherits(x, "Chat")) {
    return(structure(
      list(
        provider = "ellmer",
        model = "custom",
        system_prompt = NULL,
        ellmer_chat = x
      ),
      class = "dicom_ai_chat"
    ))
  }
  if (inherits(x, "dicom_llm")) {
    prov <- if (identical(x$provider, "custom")) "openai_compatible" else x$provider
    return(ai_chat(
      provider = prov,
      model = x$model,
      base_url = x$base_url,
      api_key = x$api_key
    ))
  }
  cli::cli_abort("{.arg x} must be a {.cls dicom_llm}, {.cls dicom_ai_chat}, or {.cls Chat} object.")
}
