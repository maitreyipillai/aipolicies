# =============================================================================
# 05_reliability.R  --  the reliability evidence the paper has to report
#
# Codebook v2.0.0 §1.1
#
# Three checks, each written to output/reliability_report.md:
#
#   1. STABILITY   Same units, two independent runs, same settings. Reports
#                  exact-match agreement on the whole six-score vector and
#                  per-theme agreement. This REPLACES the v1 claim that
#                  temperature = 0.0 makes scoring deterministic -- a parameter
#                  that no longer exists on current models, and that never
#                  guaranteed identical output anyway. A measured number in a
#                  table is a stronger claim than an asserted parameter.
#
#   2. BENCHMARK   Model scores for the 30 gold units against their hand-coded
#      AGREEMENT   values. Per-theme exact agreement, +/-1 agreement, Cohen's
#                  kappa (weighted, ordinal) and Krippendorff's alpha.
#
#   3. HUMAN       Same statistics against a human-coded sample supplied as
#      AGREEMENT   data/benchmarks/human_coded_sample.csv (unit_id + six theme
#                  columns). Skipped with a notice if that file is absent --
#                  it does not exist until the PI or an RA codes the sample.
#
# Usage:
#   Rscript R/05_reliability.R
#   Rscript R/05_reliability.R --stability-run data/coded_rerun
# =============================================================================

suppressPackageStartupMessages({ library(jsonlite) })

ROOT <- getwd()
if (!dir.exists(file.path(ROOT, "data"))) stop("run from the project root")

THEMES <- c("T1_surveillance", "T2_executive", "T3_infocontrol",
            "T4_civilrights", "T5_economic", "T6_geopolitical")
OUT <- file.path(ROOT, "output", "reliability_report.md")
dir.create(dirname(OUT), showWarnings = FALSE, recursive = TRUE)

args <- commandArgs(trailingOnly = TRUE)
rerun_dir <- if ("--stability-run" %in% args) args[which(args == "--stability-run") + 1] else
             file.path(ROOT, "data", "coded_rerun")

# -----------------------------------------------------------------------------
# Ordinal agreement statistics, implemented directly so the pipeline does not
# depend on `irr`/`icr` being installable on the analysis machine. Both are
# standard definitions; both are checked against the degenerate cases.
# -----------------------------------------------------------------------------
weighted_kappa <- function(a, b, categories = 0:3, weights = c("quadratic", "linear")) {
  weights <- match.arg(weights)
  k <- length(categories)
  a <- factor(a, levels = categories); b <- factor(b, levels = categories)
  O <- table(a, b) / length(a)
  E <- outer(rowSums(O), colSums(O))
  W <- outer(seq_len(k), seq_len(k), function(i, j)
    if (weights == "quadratic") (i - j)^2 / (k - 1)^2 else abs(i - j) / (k - 1))
  den <- sum(W * E)
  if (den == 0) return(NA_real_)
  1 - sum(W * O) / den
}

krippendorff_alpha_ordinal <- function(m) {
  # m: units x coders matrix, ordinal values, NA allowed
  vals <- sort(unique(as.vector(m[!is.na(m)])))
  if (length(vals) < 2) return(NA_real_)
  # coincidence matrix
  coinc <- matrix(0, length(vals), length(vals), dimnames = list(vals, vals))
  for (i in seq_len(nrow(m))) {
    u <- m[i, ][!is.na(m[i, ])]
    mu <- length(u)
    if (mu < 2) next
    for (p in seq_len(mu)) for (q in seq_len(mu)) if (p != q) {
      coinc[as.character(u[p]), as.character(u[q])] <-
        coinc[as.character(u[p]), as.character(u[q])] + 1 / (mu - 1)
    }
  }
  n <- sum(coinc); nc <- rowSums(coinc)
  # ordinal difference function
  delta <- outer(seq_along(vals), seq_along(vals), Vectorize(function(i, j) {
    if (i == j) return(0)
    lo <- min(i, j); hi <- max(i, j)
    (sum(nc[lo:hi]) - (nc[lo] + nc[hi]) / 2)^2
  }))
  Do <- sum(coinc * delta) / n
  De <- sum(outer(nc, nc) * delta) / (n * (n - 1))
  if (De == 0) return(NA_real_)
  1 - Do / De
}

pair_stats <- function(x, y, label) {
  keep <- !is.na(x) & !is.na(y)
  x <- x[keep]; y <- y[keep]
  data.frame(
    comparison = label, n = length(x),
    exact = round(mean(x == y), 4),
    within1 = round(mean(abs(x - y) <= 1), 4),
    kappa_quad = round(weighted_kappa(x, y), 4),
    alpha_ord = round(krippendorff_alpha_ordinal(cbind(x, y)), 4),
    stringsAsFactors = FALSE)
}

vector_exact <- function(A, B) mean(rowSums(A == B) == ncol(A))

read_coded_dir <- function(dir) {
  fs <- list.files(dir, pattern = "[.]jsonl$", full.names = TRUE)
  if (!length(fs)) return(NULL)
  d <- do.call(rbind, lapply(fs, function(f) {
    x <- stream_in(file(f), verbose = FALSE)
    sc <- x$scores_full_breakdown
    for (k in THEMES) x[[k]] <- as.integer(sc[[k]])
    x[, c("unit_id", "doc_id", THEMES, "confidence_level", "flag_human_review",
          "model_id", "effort", "codebook_sha256", "prompt_sha256", "scoring_route")]
  }))
  d[!duplicated(d$unit_id, fromLast = TRUE), ]
}

sect <- function(...) cat(..., "\n", sep = "", file = OUT, append = TRUE)

# -----------------------------------------------------------------------------
main <- function() {
  main_d <- read_coded_dir(file.path(ROOT, "data", "coded"))
  if (is.null(main_d)) stop("no coded output in data/coded/")

  cat("# Reliability Report\n\n", file = OUT)
  sect("Codebook 2.0.0 | generated ",
       format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%d %H:%M UTC"), "\n")
  sect("Units in the main run: **", nrow(main_d), "**  \n",
       "Scoring routes present: ", paste(unique(main_d$scoring_route), collapse = ", "), "  \n",
       "Models present: ", paste(unique(main_d$model_id), collapse = ", "), "\n")

  if (any(main_d$scoring_route == "interactive_session")) {
    sect("\n> **Warning.** Some or all units carry `scoring_route: \"interactive_session\"`. ",
         "Those scores were produced inside a Claude Code session, not by a versioned API ",
         "call, so they are not reproducible and the stability statistic below cannot be ",
         "computed for them. They are a first-pass audit artefact and must be superseded ",
         "by an `api_batch` run before anything is reported.\n")
  }

  # ---- 1. stability --------------------------------------------------------
  sect("\n## 1. Run-to-run stability\n")
  rerun <- read_coded_dir(rerun_dir)
  if (is.null(rerun)) {
    sect("Not yet measured. Produce a second independent run over a random >=10% sample:\n\n",
         "```\n",
         "# copy data/coded aside, then re-score the sample into data/coded_rerun/\n",
         "Rscript R/03_evaluate.R --limit 40\n",
         "Rscript R/05_reliability.R --stability-run data/coded_rerun\n",
         "```\n\n",
         "**This statistic replaces the `temperature = 0.0` determinism claim ",
         "(codebook §1.1) and the paper cannot make a reproducibility claim without it.**\n")
  } else {
    m <- merge(main_d, rerun, by = "unit_id", suffixes = c("_a", "_b"))
    A <- as.matrix(m[, paste0(THEMES, "_a")]); B <- as.matrix(m[, paste0(THEMES, "_b")])
    sect("Units re-scored: **", nrow(m), "**  \n",
         "Whole-vector exact agreement: **", round(100 * vector_exact(A, B), 1), "%**\n\n")
    st <- do.call(rbind, lapply(seq_along(THEMES), function(i)
      pair_stats(A[, i], B[, i], THEMES[i])))
    sect(knit_table(st))
  }

  # ---- 2. benchmark agreement ----------------------------------------------
  sect("\n## 2. Agreement with the gold standard (30 benchmarks)\n")
  bf <- file.path(ROOT, "data", "benchmarks", "gold_standard_v2_30_benchmarks.json")
  b <- fromJSON(bf, simplifyVector = FALSE)
  gold <- do.call(rbind, lapply(b, function(x) {
    s <- x$evaluation_output$scores_full_breakdown
    data.frame(unit_id = x$unit_id, as.data.frame(s), stringsAsFactors = FALSE)
  }))
  m <- merge(gold, main_d, by = "unit_id", suffixes = c("_gold", "_model"))
  if (!nrow(m)) {
    sect("No benchmark units have been scored by the model yet. Run:\n\n",
         "```\nRscript R/03_evaluate.R --benchmarks\n```\n\n",
         "Note that 12 of the 30 benchmarks are calibration exemplars that are also used ",
         "as few-shot examples, so agreement against them measures instruction-following, ",
         "not validity. Validity requires the held-out set in section 3.\n")
  } else {
    A <- as.matrix(m[, paste0(THEMES, "_gold")]); B <- as.matrix(m[, paste0(THEMES, "_model")])
    sect("Benchmark units scored: **", nrow(m), "**  \n",
         "Whole-vector exact agreement: **", round(100 * vector_exact(A, B), 1), "%**\n\n")
    st <- do.call(rbind, lapply(seq_along(THEMES), function(i)
      pair_stats(A[, i], B[, i], THEMES[i])))
    sect(knit_table(st))
  }

  # ---- 3. human agreement --------------------------------------------------
  sect("\n## 3. Agreement with human coding\n")
  hf <- file.path(ROOT, "data", "benchmarks", "human_coded_sample.csv")
  if (!file.exists(hf)) {
    sect("**Not yet available.** Create `data/benchmarks/human_coded_sample.csv` with columns\n\n",
         "`unit_id, ", paste(THEMES, collapse = ", "), ", coder_id`\n\n",
         "coded blind on a random sample of units drawn from `output/coded_units.csv`, ",
         "*before* seeing model output. 100-150 units is the usual minimum. ",
         "Until this exists the pipeline is unvalidated and its output is not publishable ",
         "(CODING_READINESS.md Decision 7).\n")
  } else {
    h <- read.csv(hf, stringsAsFactors = FALSE)
    m <- merge(h, main_d, by = "unit_id", suffixes = c("_human", "_model"))
    A <- as.matrix(m[, paste0(THEMES, "_human")]); B <- as.matrix(m[, paste0(THEMES, "_model")])
    sect("Units double-coded: **", nrow(m), "**  \n",
         "Whole-vector exact agreement: **", round(100 * vector_exact(A, B), 1), "%**\n\n")
    st <- do.call(rbind, lapply(seq_along(THEMES), function(i)
      pair_stats(A[, i], B[, i], THEMES[i])))
    sect(knit_table(st))
  }

  # ---- 4. descriptive diagnostics -----------------------------------------
  sect("\n## 4. Diagnostics\n")
  sect("Flag rate: **", round(100 * mean(main_d$flag_human_review == "YES"), 1), "%**  \n")
  sect("Confidence distribution: ",
       paste(sprintf("%s %d", names(table(main_d$confidence_level)),
                     as.integer(table(main_d$confidence_level))), collapse = " | "), "\n\n")
  dist <- do.call(rbind, lapply(THEMES, function(k) {
    t <- table(factor(main_d[[k]], levels = 0:3))
    data.frame(theme = k, s0 = t[[1]], s1 = t[[2]], s2 = t[[3]], s3 = t[[4]])
  }))
  sect("Score distribution across the corpus:\n\n", knit_table(dist))
  zero <- dist$theme[dist$s1 + dist$s2 + dist$s3 == 0]
  if (length(zero)) sect("\n> Themes that never scored above 0: **", paste(zero, collapse = ", "),
                         "**. Check whether that is a property of the corpus or of the ",
                         "instrument before reporting it as a finding.\n")

  message("wrote ", OUT)
}

knit_table <- function(df) {
  h <- paste0("| ", paste(names(df), collapse = " | "), " |\n")
  s <- paste0("|", paste(rep("---", ncol(df)), collapse = "|"), "|\n")
  rows <- apply(df, 1, function(r) paste0("| ", paste(r, collapse = " | "), " |\n"))
  paste0(h, s, paste(rows, collapse = ""))
}

if (sys.nframe() == 0L || identical(environment(), globalenv())) main()
