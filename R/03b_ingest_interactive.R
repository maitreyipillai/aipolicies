# =============================================================================
# 03b_ingest_interactive.R  --  first-pass scores from a Claude Code session
#                               -> data/coded/{doc_id}.jsonl
#
# Codebook v2.0.0 §7 (provenance), §8.2 (mandatory flag triggers)
#
# WHY THIS EXISTS, AND ITS LIMIT
# ------------------------------
# The production coder is R/03_evaluate.R, which calls the Claude API with a
# hashed prompt and returns reproducible, provenance-stamped scores. It needs an
# ANTHROPIC_API_KEY that this project does not yet have. This script ingests a
# FIRST PASS produced inside an interactive Claude Code session so the PI can
# audit the instrument, the segmentation, and the score distribution now rather
# than after the key arrives.
#
# Every record it writes is stamped scoring_route = "interactive_session" and
# prompt_sha256 = "INTERACTIVE_SESSION_NOT_REPRODUCIBLE". 05_reliability.R
# detects that value and refuses to treat the run as a reproducibility claim.
# These numbers are an audit artefact. They must be superseded by an api_batch
# run before anything is reported.
#
# INPUT  data/coded_interactive/{doc_id}.psv, pipe-separated, one line per unit:
#          unit_seq|T1,T2,T3,T4,T5,T6|binding_status|confidence|flag|reason|justification
#        Lines beginning # are comments. Field 5 (flag) may be left empty: the
#        mechanical triggers below are applied regardless.
#
# MECHANICAL FLAGS. Four of the seven §8.2 triggers are pure arithmetic and are
# computed here rather than judged, per §4.2's rule that anything derivable from
# the scores is derived in code: two or more themes tied at >= 2; T1 or T3 >= 2;
# word_count outside 100-350; confidence Low. The remaining three are judgment
# calls carried in from the input file.
# =============================================================================

suppressPackageStartupMessages({ library(jsonlite); library(digest) })

ROOT <- getwd()
if (!dir.exists(file.path(ROOT, "data"))) stop("run from the project root")

IN_DIR    <- file.path(ROOT, "data", "coded_interactive")
UNIT_DIR  <- file.path(ROOT, "data", "units")
CODED_DIR <- file.path(ROOT, "data", "coded")
CODEBOOK  <- file.path(ROOT, "codebook", "codebook_detailed.md")
dir.create(CODED_DIR, showWarnings = FALSE, recursive = TRUE)

THEMES <- c("T1_surveillance", "T2_executive", "T3_infocontrol",
            "T4_civilrights", "T5_economic", "T6_geopolitical")
TIEBREAK <- c("T3_infocontrol", "T1_surveillance", "T2_executive",
              "T5_economic", "T4_civilrights", "T6_geopolitical")
VALID_BINDING <- c("enacted", "directed", "proposed", "aspirational", "n/a")
VALID_CONF    <- c("High", "Moderate", "Low")
VALID_REASON  <- c("None", "Polysemic Uncertainty", "Conflicting Statutory Mandates",
                   "Missing Operational Context")

RUN_ID <- paste0("interactive_", format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y%m%dT%H%M%SZ"))
PROV <- list(
  codebook_version = "2.0.0",
  codebook_sha256  = digest(file = CODEBOOK, algo = "sha256"),
  prompt_version   = "INTERACTIVE_SESSION",
  prompt_sha256    = "INTERACTIVE_SESSION_NOT_REPRODUCIBLE",
  model_id = "claude-opus-5 (Claude Code session; not an API call)",
  effort = "n/a")

apply_mechanical_flags <- function(s, word_count, conf, flag_in, reason_in) {
  reasons <- character(0)
  srt <- sort(s, decreasing = TRUE)
  if (sum(s == max(s)) >= 2 && max(s) >= 2) reasons <- c(reasons, "Polysemic Uncertainty")
  if (s[["T1_surveillance"]] >= 2 || s[["T3_infocontrol"]] >= 2)
    reasons <- c(reasons, "Polysemic Uncertainty")
  if (word_count < 100 || word_count > 350) reasons <- c(reasons, "Missing Operational Context")
  if (identical(conf, "Low")) reasons <- c(reasons, "Missing Operational Context")
  if (identical(flag_in, "YES") && nzchar(reason_in) && reason_in != "None")
    reasons <- c(reasons, reason_in)

  if (!length(reasons)) return(list(flag = "NO", reason = "None"))
  # report the most specific reason present, in this precedence
  pref <- c("Conflicting Statutory Mandates", "Polysemic Uncertainty",
            "Missing Operational Context")
  list(flag = "YES", reason = pref[pref %in% reasons][1])
}

ingest_doc <- function(doc_id) {
  psv <- file.path(IN_DIR, paste0(doc_id, ".psv"))
  if (!file.exists(psv)) { message("  (no input for ", doc_id, ")"); return(0L) }
  units <- stream_in(file(file.path(UNIT_DIR, paste0(doc_id, ".jsonl"))), verbose = FALSE)

  lines <- readLines(psv, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nzchar(trimws(lines)) & !startsWith(trimws(lines), "#")]

  recs <- list(); seen <- integer(0)
  for (ln in lines) {
    f <- strsplit(ln, "|", fixed = TRUE)[[1]]
    if (length(f) < 7) stop(doc_id, ": malformed line (need 7 fields): ", substr(ln, 1, 80))
    seq_i <- as.integer(trimws(f[1]))
    sv <- as.integer(strsplit(trimws(f[2]), ",", fixed = TRUE)[[1]])
    if (length(sv) != 6 || any(is.na(sv)) || any(sv < 0 | sv > 3))
      stop(doc_id, " unit ", seq_i, ": score vector must be six integers 0-3, got '", f[2], "'")
    names(sv) <- THEMES

    binding <- trimws(f[3]); conf <- trimws(f[4])
    if (!binding %in% VALID_BINDING) stop(doc_id, " unit ", seq_i, ": bad binding_status '", binding, "'")
    if (!conf %in% VALID_CONF) stop(doc_id, " unit ", seq_i, ": bad confidence '", conf, "'")
    if (all(sv == 0) && binding != "n/a")
      stop(doc_id, " unit ", seq_i, ": all-zero vector requires binding_status 'n/a'")
    if (any(sv > 0) && binding == "n/a")
      stop(doc_id, " unit ", seq_i, ": non-zero vector cannot have binding_status 'n/a'")

    reason_in <- trimws(f[6])
    if (nzchar(reason_in) && !reason_in %in% VALID_REASON)
      stop(doc_id, " unit ", seq_i, ": bad flag_reason '", reason_in, "'")

    u <- units[units$unit_seq == seq_i, ]
    if (!nrow(u)) stop(doc_id, ": no unit with unit_seq ", seq_i)
    if (seq_i %in% seen) stop(doc_id, ": duplicate unit_seq ", seq_i)
    seen <- c(seen, seq_i)

    fl <- apply_mechanical_flags(sv, u$word_count[1], conf, trimws(f[5]), reason_in)

    recs[[length(recs) + 1]] <- c(
      list(unit_id = u$unit_id[1], doc_id = doc_id, unit_seq = seq_i,
           scores_full_breakdown = as.list(sv),
           binding_status = binding,
           score3_evidence = list(instrument = NULL, addressee = NULL, consequence = NULL),
           confidence_level = conf,
           flag_human_review = fl$flag, flag_reason = fl$reason,
           justification = paste(trimws(f[7:length(f)]), collapse = "|")),
      PROV,
      list(scoring_route = "interactive_session",
           scored_at = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ"),
           run_id = RUN_ID,
           input_tokens = NA, output_tokens = NA, cache_read_input_tokens = NA))
  }

  missing <- setdiff(units$unit_seq, seen)
  if (length(missing))
    warning(doc_id, ": ", length(missing), " units not scored (unit_seq ",
            paste(head(missing, 20), collapse = ","), if (length(missing) > 20) ", ...", ")")

  out <- file.path(CODED_DIR, paste0(doc_id, ".jsonl"))
  con <- file(out, "w", encoding = "UTF-8"); on.exit(close(con))
  for (r in recs) writeLines(toJSON(r, auto_unbox = TRUE, null = "null"), con, useBytes = TRUE)
  message("  ", doc_id, ": ", length(recs), " units -> ", basename(out))
  length(recs)
}

main <- function() {
  man <- read.csv(file.path(ROOT, "data", "corpus_manifest.csv"), stringsAsFactors = FALSE)
  n <- sum(vapply(man$doc_id, ingest_doc, 0L))
  message("\ningested ", n, " interactive first-pass scores (run ", RUN_ID, ")")
  message("These are NOT reproducible. Supersede with R/03_evaluate.R once an API key exists.")
}

if (sys.nframe() == 0L || identical(environment(), globalenv())) main()
