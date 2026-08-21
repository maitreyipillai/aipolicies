# =============================================================================
# 03_evaluate.R  --  units -> Claude API -> scored units
#
# Codebook v2.0.0 §1.1 (reproducibility), §7 (provenance), §10 (output schema)
#
# Input  : data/units/{doc_id}.jsonl
# Output : data/coded/{doc_id}.jsonl        one scored record per unit
#          logs/runs/{run_id}.json          hashes, model, settings, cost, failures
#
# Usage (from the project root):
#   Rscript R/03_evaluate.R                 # batch API, all documents, resumable
#   Rscript R/03_evaluate.R --sync          # synchronous, for small tests
#   Rscript R/03_evaluate.R --docs USA_AIAP_2025 --limit 5
#   Rscript R/03_evaluate.R --benchmarks    # score the 30 gold units, for agreement
#
# Design notes
# ------------
# * DETERMINISM. Codebook v1 required temperature = 0.0. That parameter is
#   removed on claude-opus-5 and returns HTTP 400. This script pins
#   output_config.effort instead and records it per unit; run-to-run stability
#   is MEASURED by 05_reliability.R rather than asserted. Set MODEL to
#   "claude-opus-4-6" and USE_TEMPERATURE to TRUE only if the PI rules that the
#   literal temperature parameter must be preserved (CHANGELOG Open items 3).
# * STRUCTURED OUTPUT. output_config.format pins prompts/output_schema.json, so
#   a malformed response is impossible rather than merely rare. Do not "ask for
#   JSON" and parse -- at 36,000 calls a 0.5% malformed rate is 180 hand-fixes.
# * PROMPT CACHING. The codebook + schema + 30 few-shot exemplars are ~12k
#   tokens repeated on every call. They are sent as a single cached system
#   block; nothing volatile may precede the cache breakpoint or the cache
#   silently misses. Verify with usage.cache_read_input_tokens in the run log.
# * BATCH API. 50% of standard price, results in arbitrary order, keyed by
#   custom_id = unit_id. Never key by position.
# * RESUMABILITY. A unit is skipped if data/coded/{doc}.jsonl already holds a
#   record for it with the current codebook_sha256 and prompt_sha256. A codebook
#   edit therefore re-runs exactly the affected units and nothing else.
# =============================================================================

suppressPackageStartupMessages({
  library(jsonlite); library(digest)
})
if (!requireNamespace("httr2", quietly = TRUE)) {
  stop("httr2 is not installed. Run:  install.packages(\"httr2\")")
}
library(httr2)

ROOT <- getwd()
if (!dir.exists(file.path(ROOT, "data"))) stop("run from the project root")

MODEL           <- "claude-opus-5"
EFFORT          <- "high"
MAX_TOKENS      <- 4000
USE_TEMPERATURE <- FALSE     # only meaningful on claude-opus-4-6 and older
API_URL         <- "https://api.anthropic.com/v1/messages"
BATCH_URL       <- "https://api.anthropic.com/v1/messages/batches"
API_VERSION     <- "2023-06-01"

PROMPT_FILE    <- file.path(ROOT, "prompts", "coder_v1.md")
SCHEMA_FILE    <- file.path(ROOT, "prompts", "output_schema.json")
CODEBOOK_FILE  <- file.path(ROOT, "codebook", "codebook_detailed.md")
BENCH_FILE     <- file.path(ROOT, "data", "benchmarks", "gold_standard_v2_30_benchmarks.json")
MANIFEST_FILE  <- file.path(ROOT, "data", "corpus_manifest.csv")
UNIT_DIR       <- file.path(ROOT, "data", "units")
CODED_DIR      <- file.path(ROOT, "data", "coded")
RUNLOG_DIR     <- file.path(ROOT, "logs", "runs")

dir.create(CODED_DIR,  showWarnings = FALSE, recursive = TRUE)
dir.create(RUNLOG_DIR, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
opt <- list(sync = "--sync" %in% args, benchmarks = "--benchmarks" %in% args,
            docs = NULL, limit = Inf)
if ("--docs"  %in% args) opt$docs  <- strsplit(args[which(args == "--docs")  + 1], ",")[[1]]
if ("--limit" %in% args) opt$limit <- as.integer(args[which(args == "--limit") + 1])

api_key <- Sys.getenv("ANTHROPIC_API_KEY")
if (!nzchar(api_key)) {
  stop("ANTHROPIC_API_KEY is not set.\n",
       "  Get a key with billing at console.anthropic.com, then put\n",
       "    ANTHROPIC_API_KEY=sk-ant-...\n",
       "  in ~/.Renviron (which .gitignore already covers) and restart R.\n",
       "  The API is billed separately from a Claude Code subscription.")
}

# -----------------------------------------------------------------------------
# Prompt assembly. The rendered prefix is hashed; that hash is stamped on every
# unit it scores, which is what makes a partial re-run possible after an edit.
# -----------------------------------------------------------------------------
render_fewshot <- function() {
  b <- fromJSON(BENCH_FILE, simplifyVector = FALSE)
  paste(vapply(b, function(x) {
    e <- x$evaluation_output
    sprintf(
      "### Exemplar %s (%s | %s)\nFills: %s\n\nTEXT:\n%s\n\nCORRECT OUTPUT:\n%s\n",
      x$benchmark_id, x$document_metadata$jurisdiction, x$source_type, x$fills_cell,
      x$text_excerpt,
      toJSON(c(list(unit_id = x$unit_id), e), auto_unbox = TRUE, pretty = TRUE, null = "null"))
  }, ""), collapse = "\n---\n")
}

build_prefix <- function() {
  tmpl     <- paste(readLines(PROMPT_FILE, warn = FALSE), collapse = "\n")
  codebook <- paste(readLines(CODEBOOK_FILE, warn = FALSE), collapse = "\n")
  schema   <- paste(readLines(SCHEMA_FILE, warn = FALSE), collapse = "\n")

  sys <- sub("\\{\\{CODEBOOK\\}\\}", codebook, tmpl, fixed = FALSE)
  sys <- sub("\\{\\{FEWSHOT\\}\\}", render_fewshot(), sys)
  parts <- strsplit(sys, "<!-- ============================ CACHE BREAKPOINT ============================ -->",
                    fixed = TRUE)[[1]]
  list(system = trimws(parts[1]), user_tmpl = trimws(parts[2]),
       schema = fromJSON(schema, simplifyVector = FALSE))
}

render_user <- function(user_tmpl, unit, meta) {
  doc <- sprintf(
    "doc_id: %s\njurisdiction: %s\nyear: %s\nissuing_authority: %s\ndocument_title: %s\ndocument_class: %s\nsource_language: %s\nis_translation: %s\nsection_path: %s\npages: %s-%s\nword_count: %s\nis_exec_summary: %s",
    meta$doc_id, meta$jurisdiction, meta$year, meta$issuing_authority,
    meta$document_title, meta$document_class, meta$source_language, meta$is_translation,
    unit$section_path, unit$page_start, unit$page_end, unit$word_count, unit$is_exec_summary)
  u <- sub("{{DOC_META}}", doc, user_tmpl, fixed = TRUE)
  sub("{{UNIT}}", sprintf("unit_id: %s\n\n%s", unit$unit_id, unit$text), u, fixed = TRUE)
}

PREFIX <- build_prefix()
PROVENANCE <- list(
  codebook_version = "2.0.0",
  codebook_sha256  = digest(file = CODEBOOK_FILE, algo = "sha256"),
  prompt_version   = "1.0.0",
  prompt_sha256    = digest(PREFIX$system, algo = "sha256", serialize = FALSE),
  model_id = MODEL, effort = EFFORT)

# -----------------------------------------------------------------------------
request_params <- function(user_text) {
  p <- list(
    model = MODEL,
    max_tokens = MAX_TOKENS,
    system = list(list(type = "text", text = PREFIX$system,
                       cache_control = list(type = "ephemeral", ttl = "1h"))),
    messages = list(list(role = "user", content = user_text)),
    output_config = list(effort = EFFORT,
                         format = list(type = "json_schema", schema = PREFIX$schema))
  )
  if (USE_TEMPERATURE) p$temperature <- 0    # legacy models only
  p
}

anthropic_req <- function(url) {
  request(url) |>
    req_headers(`x-api-key` = api_key, `anthropic-version` = API_VERSION,
                `content-type` = "application/json") |>
    req_retry(max_tries = 4, retry_on_failure = TRUE)
}

# -----------------------------------------------------------------------------
already_coded <- function(doc_id) {
  f <- file.path(CODED_DIR, paste0(doc_id, ".jsonl"))
  if (!file.exists(f)) return(character(0))
  recs <- stream_in(file(f), verbose = FALSE)
  if (!nrow(recs)) return(character(0))
  ok <- recs$codebook_sha256 == PROVENANCE$codebook_sha256 &
        recs$prompt_sha256   == PROVENANCE$prompt_sha256
  unique(recs$unit_id[ok])
}

append_records <- function(doc_id, records) {
  f <- file.path(CODED_DIR, paste0(doc_id, ".jsonl"))
  con <- file(f, open = "a", encoding = "UTF-8")
  on.exit(close(con))
  for (r in records) writeLines(toJSON(r, auto_unbox = TRUE, null = "null"), con, useBytes = TRUE)
}

stamp <- function(parsed, unit, run_id, usage) {
  c(list(unit_id = unit$unit_id, doc_id = unit$doc_id, unit_seq = unit$unit_seq),
    parsed[setdiff(names(parsed), "unit_id")],
    PROVENANCE,
    list(scoring_route = if (opt$sync) "api_sync" else "api_batch",
         scored_at = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"),
         run_id = run_id,
         input_tokens = usage$input_tokens %||% NA,
         output_tokens = usage$output_tokens %||% NA,
         cache_read_input_tokens = usage$cache_read_input_tokens %||% NA))
}
`%||%` <- function(a, b) if (is.null(a)) b else a

extract_json <- function(msg) {
  tb <- Filter(function(b) b$type == "text", msg$content)
  if (!length(tb)) stop("no text block in response")
  fromJSON(tb[[1]]$text, simplifyVector = FALSE)
}

# -----------------------------------------------------------------------------
score_sync <- function(units, meta, run_id) {
  out <- list(); fails <- list()
  for (i in seq_len(nrow(units))) {
    u <- as.list(units[i, ])
    r <- try({
      resp <- anthropic_req(API_URL) |>
        req_body_json(request_params(render_user(PREFIX$user_tmpl, u, meta))) |>
        req_perform() |> resp_body_json()
      stamp(extract_json(resp), u, run_id, resp$usage)
    }, silent = TRUE)
    if (inherits(r, "try-error")) {
      fails[[length(fails) + 1]] <- list(unit_id = u$unit_id, error = as.character(r))
      message("    FAIL ", u$unit_id)
    } else {
      out[[length(out) + 1]] <- r
      message("    ok   ", u$unit_id)
    }
  }
  list(records = out, failures = fails)
}

score_batch <- function(units, meta, run_id) {
  reqs <- lapply(seq_len(nrow(units)), function(i) {
    u <- as.list(units[i, ])
    list(custom_id = u$unit_id,
         params = request_params(render_user(PREFIX$user_tmpl, u, meta)))
  })
  message("    submitting batch of ", length(reqs), " requests")
  b <- anthropic_req(BATCH_URL) |>
    req_body_json(list(requests = reqs)) |> req_perform() |> resp_body_json()
  message("    batch id ", b$id)

  repeat {
    Sys.sleep(30)
    st <- anthropic_req(paste0(BATCH_URL, "/", b$id)) |> req_perform() |> resp_body_json()
    message("      ", st$processing_status, " | succeeded ", st$request_counts$succeeded,
            " errored ", st$request_counts$errored)
    if (identical(st$processing_status, "ended")) break
  }

  lines <- anthropic_req(paste0(BATCH_URL, "/", b$id, "/results")) |>
    req_perform() |> resp_body_string()
  lines <- strsplit(lines, "\n", fixed = TRUE)[[1]]
  lines <- lines[nzchar(trimws(lines))]

  by_id <- setNames(lapply(seq_len(nrow(units)), function(i) as.list(units[i, ])), units$unit_id)
  out <- list(); fails <- list()
  for (ln in lines) {
    res <- fromJSON(ln, simplifyVector = FALSE)
    u <- by_id[[res$custom_id]]                      # key by id, never by position
    if (!identical(res$result$type, "succeeded")) {
      fails[[length(fails) + 1]] <- list(unit_id = res$custom_id, error = res$result$type)
      next
    }
    r <- try(stamp(extract_json(res$result$message), u, run_id, res$result$message$usage), silent = TRUE)
    if (inherits(r, "try-error")) {
      fails[[length(fails) + 1]] <- list(unit_id = res$custom_id, error = as.character(r))
    } else out[[length(out) + 1]] <- r
  }
  list(records = out, failures = fails, batch_id = b$id)
}

# -----------------------------------------------------------------------------
main <- function() {
  run_id <- paste0("run_", format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y%m%dT%H%M%SZ"))
  man <- read.csv(MANIFEST_FILE, stringsAsFactors = FALSE)
  docs <- if (is.null(opt$docs)) man$doc_id else opt$docs

  all_fail <- list(); n_done <- 0L; usage_tot <- c(in_ = 0, out = 0, cache = 0)
  for (doc_id in docs) {
    meta <- as.list(man[man$doc_id == doc_id, ])
    units <- stream_in(file(file.path(UNIT_DIR, paste0(doc_id, ".jsonl"))), verbose = FALSE)
    done <- already_coded(doc_id)
    todo <- units[!units$unit_id %in% done, ]
    if (is.finite(opt$limit)) todo <- head(todo, opt$limit)
    message("[", doc_id, "] ", nrow(todo), " to score (", length(done), " already current)")
    if (!nrow(todo)) next

    res <- if (opt$sync) score_sync(todo, meta, run_id) else score_batch(todo, meta, run_id)
    append_records(doc_id, res$records)
    all_fail <- c(all_fail, res$failures)
    n_done <- n_done + length(res$records)
    for (r in res$records) {
      usage_tot["in_"]   <- usage_tot["in_"]   + (r$input_tokens %||% 0)
      usage_tot["out"]   <- usage_tot["out"]   + (r$output_tokens %||% 0)
      usage_tot["cache"] <- usage_tot["cache"] + (r$cache_read_input_tokens %||% 0)
    }
  }

  log <- c(PROVENANCE, list(
    run_id = run_id, route = if (opt$sync) "api_sync" else "api_batch",
    started_docs = docs, units_scored = n_done,
    input_tokens = unname(usage_tot["in_"]), output_tokens = unname(usage_tot["out"]),
    cache_read_input_tokens = unname(usage_tot["cache"]),
    failures = all_fail,
    finished_at = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ")))
  write(toJSON(log, auto_unbox = TRUE, pretty = TRUE, null = "null"),
        file.path(RUNLOG_DIR, paste0(run_id, ".json")))

  message("\n", n_done, " units scored, ", length(all_fail), " failures")
  if (usage_tot["cache"] == 0 && n_done > 1)
    warning("cache_read_input_tokens is 0 across the run -- the cached prefix is ",
            "not being hit. Check that nothing volatile precedes the cache breakpoint.")
  message("run log: logs/runs/", run_id, ".json")
}

if (sys.nframe() == 0L || identical(environment(), globalenv())) main()
