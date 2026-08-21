# =============================================================================
# 04_assemble.R  --  coded units -> tidy analysis tables
#
# Codebook v2.0.0 §4.2 (derived labels), §4.3 (document-level aggregation)
#
# Input  : data/coded/{doc_id}.jsonl, data/units/{doc_id}.jsonl,
#          data/corpus_manifest.csv
# Output : output/coded_units.csv        one row per unit -- the analysis dataset
#          output/document_indices.csv   one row per document -- Intensity / Density
#          output/flag_queue.csv         units awaiting human adjudication
#
# primary_theme / secondary_theme are computed HERE, not by the model. Anything
# derivable from the six scores is derived in code, so it cannot drift across
# tens of thousands of units, and changing the tie-break order later is a
# recomputation rather than a re-run.
# =============================================================================

suppressPackageStartupMessages({ library(jsonlite) })

ROOT <- getwd()
if (!dir.exists(file.path(ROOT, "data"))) stop("run from the project root")

CODED_DIR <- file.path(ROOT, "data", "coded")
UNIT_DIR  <- file.path(ROOT, "data", "units")
OUT_DIR   <- file.path(ROOT, "output")
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

THEMES <- c("T1_surveillance", "T2_executive", "T3_infocontrol",
            "T4_civilrights", "T5_economic", "T6_geopolitical")

# Codebook §4.2 step 4. Arbitrary but fixed; it reproduces the label choice made
# implicitly by every tied case in the v1 benchmark set.
TIEBREAK <- c("T3_infocontrol", "T1_surveillance", "T2_executive",
              "T5_economic", "T4_civilrights", "T6_geopolitical")

derive_labels <- function(S) {
  # S: numeric matrix, one row per unit, columns in THEMES order
  rank_of <- match(THEMES, TIEBREAK)
  pick <- function(v, exclude = NULL) {
    idx <- seq_along(v)
    if (!is.null(exclude)) idx <- idx[idx != exclude]
    best <- idx[v[idx] == max(v[idx])]
    best[which.min(rank_of[best])]
  }
  p <- integer(nrow(S)); s <- integer(nrow(S))
  for (i in seq_len(nrow(S))) {
    v <- S[i, ]
    p[i] <- pick(v)
    s[i] <- pick(v, exclude = p[i])
  }
  sec_score <- S[cbind(seq_len(nrow(S)), s)]
  data.frame(
    primary_theme  = THEMES[p],
    primary_score  = S[cbind(seq_len(nrow(S)), p)],
    secondary_theme = ifelse(sec_score >= 1, THEMES[s], "None"),
    secondary_score = ifelse(sec_score >= 1, sec_score, 0L),
    stringsAsFactors = FALSE)
}

read_coded <- function() {
  fs <- list.files(CODED_DIR, pattern = "[.]jsonl$", full.names = TRUE)
  if (!length(fs)) stop("no coded output in data/coded/. Run R/03_evaluate.R first.")
  do.call(rbind, lapply(fs, function(f) {
    x <- stream_in(file(f), verbose = FALSE)
    sc <- x$scores_full_breakdown
    for (k in THEMES) x[[k]] <- as.integer(sc[[k]])
    ev <- x$score3_evidence
    x$evidence_instrument  <- as.character(ev$instrument)
    x$evidence_addressee   <- as.character(ev$addressee)
    x$evidence_consequence <- as.character(ev$consequence)
    x$scores_full_breakdown <- NULL; x$score3_evidence <- NULL
    x
  }))
}

read_units <- function() {
  fs <- list.files(UNIT_DIR, pattern = "[.]jsonl$", full.names = TRUE)
  do.call(rbind, lapply(fs, function(f) stream_in(file(f), verbose = FALSE)))
}

main <- function() {
  coded <- read_coded()
  units <- read_units()
  man   <- read.csv(file.path(ROOT, "data", "corpus_manifest.csv"), stringsAsFactors = FALSE)

  u <- units[, c("unit_id", "section_path", "page_start", "page_end",
                 "word_count", "is_exec_summary")]
  d <- merge(coded, u, by = "unit_id", all.x = TRUE, suffixes = c("", "_unit"))
  d <- merge(d, man[, c("doc_id", "country_iso3", "jurisdiction", "year",
                        "document_class", "source_language", "is_translation",
                        "regime_type", "regime_source", "regime_year")],
             by = "doc_id", all.x = TRUE)

  S <- as.matrix(d[, THEMES])
  d <- cbind(d, derive_labels(S))
  d$n_themes_nonzero <- rowSums(S >= 1)
  d$max_score        <- apply(S, 1, max)
  d <- d[order(d$doc_id, d$unit_seq), ]

  front <- c("unit_id", "doc_id", "unit_seq", "country_iso3", "jurisdiction", "year",
             "document_class", "section_path", "page_start", "page_end", "word_count",
             "is_exec_summary", THEMES, "primary_theme", "primary_score",
             "secondary_theme", "secondary_score", "n_themes_nonzero", "max_score",
             "binding_status", "confidence_level", "flag_human_review", "flag_reason")
  d <- d[, c(front, setdiff(names(d), front))]
  write.csv(d, file.path(OUT_DIR, "coded_units.csv"), row.names = FALSE, na = "")

  # ---- document-level indices (codebook §4.3) ------------------------------
  agg <- do.call(rbind, lapply(split(d, d$doc_id), function(g) {
    row <- data.frame(doc_id = g$doc_id[1], jurisdiction = g$jurisdiction[1],
                      year = g$year[1], document_class = g$document_class[1],
                      n_units = nrow(g), n_words = sum(g$word_count, na.rm = TRUE),
                      stringsAsFactors = FALSE)
    for (k in THEMES) {
      row[[paste0("intensity_", k)]] <- round(mean(g[[k]]), 4)
      row[[paste0("density_",   k)]] <- round(mean(g[[k]] >= 1), 4)
      row[[paste0("max_",       k)]] <- max(g[[k]])
      row[[paste0("n3_",        k)]] <- sum(g[[k]] == 3)
    }
    row$flag_rate <- round(mean(g$flag_human_review == "YES"), 4)
    row
  }))
  write.csv(agg, file.path(OUT_DIR, "document_indices.csv"), row.names = FALSE)

  # ---- human review queue --------------------------------------------------
  fq <- d[d$flag_human_review == "YES",
          c("unit_id", "doc_id", "jurisdiction", "section_path", "page_start",
            "word_count", THEMES, "binding_status", "confidence_level",
            "flag_reason", "justification")]
  write.csv(fq, file.path(OUT_DIR, "flag_queue.csv"), row.names = FALSE, na = "")

  message("output/coded_units.csv      ", nrow(d), " units")
  message("output/document_indices.csv ", nrow(agg), " documents")
  message("output/flag_queue.csv       ", nrow(fq), " flagged (",
          round(100 * nrow(fq) / nrow(d), 1), "%)")
  message("")
  print(agg[, c("doc_id", "n_units", grep("^intensity_", names(agg), value = TRUE))],
        row.names = FALSE)
}

if (sys.nframe() == 0L || identical(environment(), globalenv())) main()
