# =============================================================================
# 01_extract.R  --  PDF -> layout-aware line records
#
# Paper 2: AI Policy Content Analysis Pipeline
# Codebook v2.0.0 | see codebook/codebook_detailed.md
#
# Reads every PDF named in data/corpus_manifest.csv and emits, per document:
#   data/extracted/{doc_id}_lines.jsonl   one record per reconstructed text line
#   data/extracted/{doc_id}.txt           human-readable text, for eyeballing
# and updates the manifest's page_count and sha256 columns in place.
#
# Why not pdf_text(): several corpus documents (SING1 in particular) are
# two-column layouts. pdf_text() walks the page in raster order and interleaves
# the columns line by line, producing text that reads as nonsense and would
# corrupt every downstream score. This script works from pdf_data() word
# coordinates, detects the column gutter geometrically, and reconstructs reading
# order column by column.
#
# Line records carry x/y/height so that 02_segment.R can identify headings (by
# font size), footnotes (small type at page foot), and running heads (repeated
# text at fixed y) without guessing from the string alone.
# =============================================================================

suppressPackageStartupMessages({
  library(pdftools)
  library(jsonlite)
  library(digest)
})

# Run from the project root (the .Rproj directory).
ROOT       <- getwd()
if (!dir.exists(file.path(ROOT, "data"))) {
  stop("Run this script from the project root; data/ not found in ", ROOT)
}

RAW_DIR    <- file.path(ROOT, "data", "raw_policies")
OUT_DIR    <- file.path(ROOT, "data", "extracted")
LOG_DIR    <- file.path(ROOT, "logs")
MANIFEST   <- file.path(ROOT, "data", "corpus_manifest.csv")

`%||%` <- function(a, b) if (is.null(a)) b else a

dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(LOG_DIR, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# Column detection
#
# Scan candidate vertical cut positions across the middle 50% of the page. A cut
# is valid if no word's horizontal extent crosses it. The widest run of valid
# cuts is the gutter; we require it to be at least MIN_GUTTER wide and to leave
# at least MIN_SIDE_SHARE of the page's words on each side, which prevents a
# ragged single-column page or a centred figure from being read as two columns.
# -----------------------------------------------------------------------------
MIN_GUTTER     <- 18    # pt
MIN_SIDE_SHARE <- 0.18
MAX_COLS       <- 4

detect_gutter <- function(words, x_lo, x_hi) {
  if (nrow(words) < 40) return(NA_real_)
  span <- x_hi - x_lo
  if (span < 4 * MIN_GUTTER) return(NA_real_)
  lo <- x_lo + span * 0.25; hi <- x_lo + span * 0.75
  cuts <- seq(lo, hi, by = 2)
  if (length(cuts) < 2) return(NA_real_)
  left  <- words$x
  right <- words$x + words$width
  free <- vapply(cuts, function(c) !any(left < c & right > c), logical(1))
  if (!any(free)) return(NA_real_)

  # longest contiguous run of free cuts
  r <- rle(free)
  ends <- cumsum(r$lengths); starts <- ends - r$lengths + 1
  ok <- which(r$values)
  if (!length(ok)) return(NA_real_)
  widths <- (r$lengths[ok] - 1) * 2
  best <- ok[which.max(widths)]
  if (max(widths) < MIN_GUTTER) return(NA_real_)

  mid <- mean(c(cuts[starts[best]], cuts[ends[best]]))
  share_l <- mean(right <= mid)
  if (share_l < MIN_SIDE_SHARE || (1 - share_l) < MIN_SIDE_SHARE) return(NA_real_)
  mid
}

# Recursive split: several corpus documents are printed as two-page spreads
# (SING1/SING2 pages are 1190pt wide, i.e. two A4 pages side by side), and a
# spread half may itself be two-column. Split until no valid gutter remains or
# MAX_COLS is reached. Returns a list of word frames in left-to-right order.
split_columns <- function(words, x_lo, x_hi, depth = 1L) {
  if (depth >= log2(MAX_COLS) + 1L) return(list(words))
  gut <- detect_gutter(words, x_lo, x_hi)
  if (is.na(gut)) return(list(words))
  l <- words[words$x + words$width <= gut, , drop = FALSE]
  rgt <- words[words$x + words$width >  gut, , drop = FALSE]
  c(split_columns(l,   x_lo, gut,  depth + 1L),
    split_columns(rgt, gut,  x_hi, depth + 1L))
}

# -----------------------------------------------------------------------------
# Line reconstruction: group words sharing a baseline, order left to right.
# pdftools reports y as the top of the word box; words on one visual line can
# differ by a point or two, so we cluster on a tolerance rather than on equality.
# -----------------------------------------------------------------------------
build_lines <- function(words, page, col) {
  if (!nrow(words)) return(NULL)
  words <- words[order(words$y, words$x), ]
  tol <- max(2, stats::median(words$height, na.rm = TRUE) * 0.5)

  grp <- integer(nrow(words)); g <- 1L; grp[1] <- 1L
  if (nrow(words) > 1) for (i in 2:nrow(words)) {
    if (abs(words$y[i] - words$y[i - 1]) > tol) g <- g + 1L
    grp[i] <- g
  }

  do.call(rbind, lapply(split(seq_len(nrow(words)), grp), function(idx) {
    w <- words[idx, ][order(words$x[idx]), ]
    data.frame(
      page       = page,
      col        = col,
      y          = min(w$y),
      x          = min(w$x),
      x_end      = max(w$x + w$width),
      height     = stats::median(w$height),
      n_words    = nrow(w),
      text       = paste(w$text, collapse = " "),
      stringsAsFactors = FALSE
    )
  }))
}

extract_document <- function(pdf_path, doc_id) {
  message("  extracting ", basename(pdf_path))
  pages <- suppressWarnings(pdf_data(pdf_path))
  sizes <- pdf_pagesize(pdf_path)

  out <- list()
  for (p in seq_along(pages)) {
    w <- pages[[p]]
    if (is.null(w) || !nrow(w)) next
    w <- w[nzchar(trimws(w$text)), , drop = FALSE]
    if (!nrow(w)) next

    page_w <- sizes$width[p]
    cols <- split_columns(w, 0, page_w)
    for (ci in seq_along(cols)) {
      out[[length(out) + 1]] <- build_lines(cols[[ci]], p, ci)
    }
  }

  lines <- do.call(rbind, out)
  lines <- lines[order(lines$page, lines$col, lines$y), ]
  lines$line_no <- seq_len(nrow(lines))
  rownames(lines) <- NULL
  lines
}

# -----------------------------------------------------------------------------
main <- function() {
  man <- read.csv(MANIFEST, stringsAsFactors = FALSE, check.names = FALSE)
  log_rows <- list()

  for (i in seq_len(nrow(man))) {
    doc_id <- man$doc_id[i]
    pdf_path <- file.path(RAW_DIR, man$filename[i])
    if (!file.exists(pdf_path)) {
      warning("missing PDF: ", pdf_path); next
    }
    message("[", doc_id, "]")

    lines <- extract_document(pdf_path, doc_id)

    jsonl <- file.path(OUT_DIR, paste0(doc_id, "_lines.jsonl"))
    con <- file(jsonl, "w", encoding = "UTF-8")
    for (r in seq_len(nrow(lines))) {
      writeLines(toJSON(as.list(lines[r, ]), auto_unbox = TRUE), con, useBytes = TRUE)
    }
    close(con)

    # human-readable dump, page-marked
    txt <- character()
    for (p in unique(lines$page)) {
      txt <- c(txt, sprintf("<<<PAGE %d>>>", p), lines$text[lines$page == p], "")
    }
    writeLines(txt, file.path(OUT_DIR, paste0(doc_id, ".txt")), useBytes = TRUE)

    sha <- digest(file = pdf_path, algo = "sha256")
    npg <- length(unique(lines$page))
    man$sha256[i]     <- sha
    man$page_count[i] <- npg

    log_rows[[length(log_rows) + 1]] <- data.frame(
      doc_id = doc_id, filename = man$filename[i], pages = npg,
      lines = nrow(lines),
      words = sum(lines$n_words),
      multicol_pages = length(unique(lines$page[lines$col > 1L])),
      sha256 = sha, stringsAsFactors = FALSE
    )
    message("    ", npg, " pages, ", nrow(lines), " lines, ",
            sum(lines$n_words), " words, ",
            length(unique(lines$page[lines$col > 1L])), " multi-column pages (max ",
            max(lines$col), " cols)")
  }

  write.csv(man, MANIFEST, row.names = FALSE, na = "")
  write.csv(do.call(rbind, log_rows), file.path(LOG_DIR, "extraction_log.csv"), row.names = FALSE)
  message("\nmanifest updated with sha256 + page_count; log at logs/extraction_log.csv")
}

if (sys.nframe() == 0L || identical(environment(), globalenv())) main()
