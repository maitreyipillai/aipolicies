# =============================================================================
# 02_segment.R  --  line records -> codeable units of analysis
#
# Codebook v2.0.0 §6 (Codeable Text and Unit Segmentation)
#
# Input  : data/extracted/{doc_id}_lines.jsonl   (from 01_extract.R)
# Output : data/units/{doc_id}.jsonl             one record per unit of analysis
#          logs/segmentation_log.csv             every dropped line, with reason
#          logs/segmentation_summary.csv         per-document counts
#
# Four stages:
#   A. Drop mechanical apparatus (codebook §6.2) -- running heads, page numbers,
#      footnotes, TOC pages, cover/divider pages, figure captions, URLs.
#   B. Classify remaining lines as heading or body, using font height rather
#      than string heuristics, and maintain a heading stack -> section_path.
#      Sections whose heading matches the exclusion vocabulary (foreword,
#      acknowledgments, references, glossary...) are dropped wholesale.
#   C. Assemble lines into paragraphs, joining hyphenated line breaks and
#      continuing paragraphs across page and column boundaries.
#   D. Assemble paragraphs into units: floor ~100 words, ceiling ~350, never
#      splitting a sentence or a bullet item (codebook §6.3).
#
# Every exclusion is written to the segmentation log so the denominator is
# auditable rather than asserted.
# =============================================================================

suppressPackageStartupMessages({
  library(jsonlite)
})

ROOT <- getwd()
if (!dir.exists(file.path(ROOT, "data"))) {
  stop("Run this script from the project root; data/ not found in ", ROOT)
}

EXT_DIR  <- file.path(ROOT, "data", "extracted")
UNIT_DIR <- file.path(ROOT, "data", "units")
LOG_DIR  <- file.path(ROOT, "logs")
MANIFEST <- file.path(ROOT, "data", "corpus_manifest.csv")

dir.create(UNIT_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(LOG_DIR,  showWarnings = FALSE, recursive = TRUE)

WORD_FLOOR   <- 100
WORD_TARGET  <- 300
WORD_CEILING <- 350
WORD_HARDCAP <- 450

# -----------------------------------------------------------------------------
# Exclusion vocabulary (codebook §6.2). Matched case-insensitively against
# heading text. A matching heading drops its whole section until a heading of
# equal or higher level that does not match.
# -----------------------------------------------------------------------------
EXCLUDE_SECTION <- paste(
  "^contents?$", "^table of contents", "^index$",
  "foreword", "^preface", "^message from", "^a message",
  "acknowledg", "^credits?$",
  "^references?$", "^bibliograph", "^endnotes?$", "^notes$", "^footnotes?$",
  "^glossar", "^abbreviations", "^acronyms", "^list of (figures|tables|boxes)",
  "^about (the|this|us)", "^copyright", "^published", "^imprint", "^legal notice",
  "^disclaimer", "^partnering agencies", "^brought to you by",
  "what the experts say",          # SGP_NAIS_2019 s.6: third-party endorsements
  "^(steering|advisory) committee$", "^members of", "^contributors?$",
  "^annexure of members",
  sep = "|"
)

BULLET_RE <- "^([•▪▶●◦‣·⁃∙*–—-]|\\(?[a-z]\\)|[0-9]{1,2}[.)])\\s+"

EXEC_SUMMARY_RE <- "executive summary|^summary\\b|^summary of|zusammenfassung"

CAPTION_RE <- paste0(
  "^(figure|fig\\.|exhibit|table|chart|box|source|note|photo|image)\\s*[0-9ivx]*\\s*[:.–-]",
  "|^source\\s*:", "|^adapted from", "|^\\(source"
)

URL_RE <- "^(www\\.|https?://)[^ ]+$"

# -----------------------------------------------------------------------------
read_lines_jsonl <- function(path) {
  x <- stream_in(file(path), verbose = FALSE)
  x$text <- as.character(x$text)
  x
}

nwords <- function(s) lengths(strsplit(trimws(s), "[[:space:]]+"))

# -----------------------------------------------------------------------------
# Stage A -- mechanical apparatus
# -----------------------------------------------------------------------------
mark_apparatus <- function(L) {
  L$drop_reason <- NA_character_
  npages <- length(unique(L$page))

  # page geometry, per page: where is the top / bottom band?
  ytop <- stats::quantile(L$y, 0.02, na.rm = TRUE)
  ybot <- stats::quantile(L$y, 0.98, na.rm = TRUE)
  yrange <- ybot - ytop
  L$in_top    <- L$y <= ytop + yrange * 0.06
  L$in_bottom <- L$y >= ybot - yrange * 0.14

  body_h <- as.numeric(names(sort(table(round(L$height[L$n_words >= 6])), decreasing = TRUE))[1])
  L$body_h <- body_h

  # ---- printed page number (kept as metadata, then dropped) ----
  L$printed_page <- NA_integer_
  numonly <- grepl("^[0-9ivxlcIVXLC]{1,5}$", trimws(L$text))
  for (p in unique(L$page)) {
    idx <- which(L$page == p & numonly & (L$in_top | L$in_bottom))
    if (length(idx)) {
      n <- suppressWarnings(as.integer(trimws(L$text[idx])))
      n <- n[!is.na(n)]
      if (length(n)) L$printed_page[L$page == p] <- min(n)
    }
  }

  # ---- running heads / feet: same normalised text on many pages, in a band ----
  norm <- tolower(gsub("[^a-z ]", "", tolower(L$text)))
  norm <- trimws(gsub(" +", " ", norm))
  tab <- table(norm[nzchar(norm) & (L$in_top | L$in_bottom)])
  repeated <- names(tab)[tab >= max(3, 0.20 * npages)]
  hit <- nzchar(norm) & norm %in% repeated & (L$in_top | L$in_bottom)
  L$drop_reason[is.na(L$drop_reason) & hit] <- "running_head"

  # ---- bare page numbers / roman numerals anywhere in a band ----
  L$drop_reason[is.na(L$drop_reason) & numonly & (L$in_top | L$in_bottom)] <- "page_number"

  # ---- footnotes: small type in the bottom band, or numeric-leader footnotes --
  small <- round(L$height) < body_h
  fn_leader <- grepl("^[0-9]{1,3}[ ]+[A-Z“‘\"']", L$text)
  L$drop_reason[is.na(L$drop_reason) & small & L$in_bottom] <- "footnote_small_type"
  L$drop_reason[is.na(L$drop_reason) & fn_leader & small] <- "footnote_small_type"

  # ---- figure captions, sources, URLs ----
  L$drop_reason[is.na(L$drop_reason) & grepl(CAPTION_RE, L$text, ignore.case = TRUE)] <- "caption_or_source"
  L$drop_reason[is.na(L$drop_reason) & grepl(URL_RE, trimws(L$text))] <- "url_line"

  # ---- dot-leader TOC lines, and pages that are mostly dot-leader lines ------
  toc_line <- grepl("[.]{4,}|( \\. ){4,}", L$text) |
              grepl("^.{3,80}[ . ]{2,}[0-9]{1,3}$", L$text)
  L$drop_reason[is.na(L$drop_reason) & toc_line] <- "toc_line"
  for (p in unique(L$page)) {
    idx <- which(L$page == p)
    if (length(idx) >= 4 && mean(toc_line[idx]) >= 0.40) {
      L$drop_reason[idx][is.na(L$drop_reason[idx])] <- "toc_page"
    }
  }
  # Not every contents page uses dot leaders. SGP_NAIS_2019's is a bare list of
  # page numbers and section titles set in display type, so its entries were
  # being read as headings -- and because "CONTENTS" was the largest type in the
  # document, it became the root of every section_path and its "EXECUTIVE
  # SUMMARY" entry tagged all 62 units as exec-summary. Any page in the front of
  # the document that announces itself as a contents page is dropped whole.
  front <- unique(L$page)[unique(L$page) <= max(2, ceiling(0.20 * npages))]
  for (p in front) {
    idx <- which(L$page == p)
    if (any(grepl("^(contents?|table of contents|index)$", trimws(L$text[idx]), ignore.case = TRUE))) {
      L$drop_reason[idx][is.na(L$drop_reason[idx])] <- "toc_page"
    }
  }

  # ---- sparse pages: covers, section dividers, graphic-only pages ------------
  for (p in unique(L$page)) {
    idx <- which(L$page == p)
    if (sum(L$n_words[idx][is.na(L$drop_reason[idx])]) < 40) {
      L$drop_reason[idx][is.na(L$drop_reason[idx])] <- "sparse_page"
    }
  }

  L
}

# -----------------------------------------------------------------------------
# Stage B -- headings, section path, section-level exclusion
# -----------------------------------------------------------------------------
classify_headings <- function(L) {
  body_h <- L$body_h[1]
  txt <- trimws(L$text)
  is_caps <- grepl("^[^a-z]+$", txt) & nchar(txt) > 3
  numbered <- grepl("^([0-9]{1,2}[.)]|[0-9]{1,2}\\.[0-9]{1,2})[ ]+[A-Z“]", txt)

  # A heading candidate must look like a label, not a fragment of running prose.
  # Without these guards, emphasised first lines and lettered bullets ("b) Agri-
  # culture...") are read as headings and end up polluting section_path -- which
  # then propagates into unit_id via the section slug.
  # BULLET_RE also matches a numbered *heading* ("1. Goals", "3. Fields of
  # action"), which is how DEU_AISTRAT_2018 lost every top-level section head.
  # A numbered heading is short and unterminated; a numbered list item is prose.
  numbered_head <- numbered & L$n_words <= 8 & !grepl("[.,;:]$", txt)

  looks_like_label <-
    grepl("^[A-Z0-9“#(]", txt) &                              # not a mid-sentence continuation
    (!grepl(BULLET_RE, txt) | numbered_head) &                # not a bullet item
    !grepl("[,;]$", txt) &                                    # not a clause left hanging
    L$n_words <= 14

  L$is_heading <- looks_like_label &
    ((round(L$height) > body_h) | is_caps | numbered)

  # a long "heading" that terminates like a sentence is really body text
  L$is_heading[L$is_heading & L$n_words > 10 & grepl("[.:;]$", txt)] <- FALSE
  L$head_level <- ifelse(L$is_heading, round(L$height), NA_real_)

  # Which font sizes act as top-level section heads in this document. Needed
  # because SGP_NAIS_2019 sets "EXECUTIVE SUMMARY" larger than every real
  # section head, so height-ranking alone made it the ancestor of the whole book.
  # Count only headings that survive stage A, and only font sizes used more than
  # once: SGP_NAIS_2019 carries one-off display type at sizes 267, 88, 63 and 60
  # on cover and divider pages, which otherwise monopolise the top two slots and
  # stop any real section head from resetting the stack.
  keep <- !is.na(L$head_level) & is.na(L$drop_reason)
  tab <- table(L$head_level[keep])
  lv <- as.numeric(names(tab)[tab >= 2])
  lv <- sort(lv, decreasing = TRUE)
  if (!length(lv)) lv <- sort(unique(L$head_level[keep]), decreasing = TRUE)
  L$toplevel_sizes <- if (length(lv) >= 3) list(lv[1:2]) else list(lv[1])
  L
}

# A heading's rank is normally its font height, but display type defeats that:
# in DEU_AISTRAT_2018 the "Summary" headline is set larger than the numbered
# section heads that follow it, and in SGP_NAIS_2019 "EXECUTIVE SUMMARY" is the
# largest type in the book. Height alone therefore made those two headings the
# ancestor of every later unit, and tagged whole documents as exec-summary.
# Explicitly numbered or enumerated section heads reset the stack to depth 1.
TOPLEVEL_RE <- "^(section|chapter|part|pillar|system|phase|annex(ure)?|appendix)[ ]+[0-9IVXivx]+[ ]*[:.)-]?|^[0-9]{1,2}[.)][ ]+[A-Z]"
SUBLEVEL_RE <- "^[0-9]{1,2}[.][0-9]{1,2}[ ]+"

apply_section_paths <- function(L) {
  stack_txt <- character(0); stack_lvl <- numeric(0)
  excl_lvl <- NA_real_
  L$section_path <- ""
  L$is_exec_summary <- FALSE
  in_exec <- NA_real_

  for (i in seq_len(nrow(L))) {
    if (isTRUE(L$is_heading[i]) && is.na(L$drop_reason[i])) {
      htxt <- trimws(L$text[i])
      lvl <- L$head_level[i]

      if (grepl(TOPLEVEL_RE, htxt, ignore.case = TRUE) ||
          lvl %in% L$toplevel_sizes[[1]]) {
        stack_txt <- character(0); stack_lvl <- numeric(0)
        excl_lvl <- NA_real_; in_exec <- NA_real_
        lvl <- Inf                    # nothing can be its ancestor
      } else if (grepl(SUBLEVEL_RE, htxt) && length(stack_lvl) > 1) {
        stack_txt <- stack_txt[1]; stack_lvl <- stack_lvl[1]
        if (!is.na(excl_lvl) && excl_lvl < stack_lvl[1]) excl_lvl <- NA_real_
        if (!is.na(in_exec)  && in_exec  < stack_lvl[1]) in_exec  <- NA_real_
      } else {
        keep <- which(stack_lvl > lvl)
        stack_txt <- stack_txt[keep]; stack_lvl <- stack_lvl[keep]
        if (!is.na(excl_lvl) && lvl >= excl_lvl) excl_lvl <- NA_real_
        if (!is.na(in_exec)  && lvl >= in_exec)  in_exec  <- NA_real_
      }

      stack_txt <- c(stack_txt, htxt); stack_lvl <- c(stack_lvl, lvl)

      if (grepl(EXCLUDE_SECTION, htxt, ignore.case = TRUE)) excl_lvl <- lvl
      if (grepl(EXEC_SUMMARY_RE, htxt, ignore.case = TRUE)) in_exec <- lvl
    }
    L$section_path[i] <- paste(stack_txt, collapse = " > ")
    L$is_exec_summary[i] <- !is.na(in_exec)
    if (!is.na(excl_lvl) && is.na(L$drop_reason[i])) {
      L$drop_reason[i] <- "excluded_section"
    }
  }
  L
}

# -----------------------------------------------------------------------------
# Stage C -- paragraphs
# -----------------------------------------------------------------------------

build_paragraphs <- function(B) {
  if (!nrow(B)) return(list())
  # median line pitch within a column, for gap detection
  pitch <- stats::median(abs(diff(B$y[B$page == B$page[1] & B$col == B$col[1]])), na.rm = TRUE)
  if (!is.finite(pitch) || pitch <= 0) pitch <- stats::median(B$height, na.rm = TRUE) * 1.4

  paras <- list(); cur <- NULL
  flush <- function() {
    if (!is.null(cur)) paras[[length(paras) + 1]] <<- cur
    cur <<- NULL
  }

  for (i in seq_len(nrow(B))) {
    txt <- trimws(B$text[i])
    newpara <- FALSE
    if (is.null(cur)) {
      newpara <- TRUE
    } else {
      same_col <- B$page[i] == cur$page_end && B$col[i] == cur$col_end
      if (isTRUE(B$is_heading[i])) {
        newpara <- TRUE
      } else if (same_col) {
        gap <- B$y[i] - cur$y_last
        if (gap > pitch * 1.65) newpara <- TRUE
      } else {
        # page or column break: continue only if the previous line was clearly
        # mid-sentence and this one starts lower-case
        prev_open <- !grepl("[.;:!?”\"')]$", cur$text_last)
        starts_lower <- grepl("^[a-z(]", txt)
        if (!(prev_open && starts_lower)) newpara <- TRUE
      }
      if (grepl(BULLET_RE, txt)) newpara <- TRUE
      if (isTRUE(cur$is_heading)) newpara <- TRUE
    }

    if (newpara) {
      flush()
      cur <- list(text = txt, page_start = B$page[i], page_end = B$page[i],
                  col_end = B$col[i], y_last = B$y[i], text_last = txt,
                  is_heading = isTRUE(B$is_heading[i]),
                  section_path = B$section_path[i],
                  is_exec_summary = B$is_exec_summary[i],
                  printed_page = B$printed_page[i])
    } else {
      # de-hyphenate a line break inside a word
      if (grepl("[a-zäöü]-$", cur$text) && grepl("^[a-z]", txt)) {
        cur$text <- paste0(sub("-$", "", cur$text), txt)
      } else {
        cur$text <- paste(cur$text, txt)
      }
      cur$page_end <- B$page[i]; cur$col_end <- B$col[i]
      cur$y_last <- B$y[i]; cur$text_last <- txt
    }
  }
  flush()
  paras
}

# -----------------------------------------------------------------------------
# Stage D -- units
# -----------------------------------------------------------------------------
split_long_paragraph <- function(p) {
  # split a >CEILING paragraph at sentence boundaries, never mid-sentence
  sents <- unlist(regmatches(p$text, gregexpr("[^.!?]+[.!?]+[\"”')]*\\s*|[^.!?]+$", p$text)))
  sents <- sents[nzchar(trimws(sents))]
  if (length(sents) <= 1) return(list(p))
  out <- list(); buf <- character(0); bw <- 0
  for (s in sents) {
    sw <- nwords(s)
    if (bw > 0 && bw + sw > WORD_CEILING) {
      q <- p; q$text <- paste(buf, collapse = " "); out[[length(out) + 1]] <- q
      buf <- character(0); bw <- 0
    }
    buf <- c(buf, trimws(s)); bw <- bw + sw
  }
  if (bw > 0) { q <- p; q$text <- paste(buf, collapse = " "); out[[length(out) + 1]] <- q }
  out
}

slugify_section <- function(path) {
  parts <- trimws(strsplit(path, ">", fixed = TRUE)[[1]])
  parts <- parts[nzchar(parts)]
  if (!length(parts)) return("BODY")
  mk <- function(s, n) {
    s <- toupper(gsub("[^A-Za-z0-9]", "", s))
    if (!nchar(s)) return("")
    substr(s, 1, n)
  }
  a <- mk(parts[1], 8)
  b <- if (length(parts) > 1) mk(parts[length(parts)], 6) else ""
  paste(c(a, b)[nzchar(c(a, b))], collapse = "_")
}

assemble_units <- function(paras, doc_id) {
  units <- list(); buf <- list(); bw <- 0

  flush <- function() {
    if (!length(buf)) return(invisible())
    txt <- paste(vapply(buf, function(x) x$text, ""), collapse = "\n")
    if (length(units) && nwords(txt) < WORD_FLOOR) {
      prev <- units[[length(units)]]
      if (nwords(prev$text) + nwords(txt) <= WORD_HARDCAP) {
        prev$text <- paste(prev$text, txt, sep = "\n")
        prev$page_end <- max(prev$page_end, buf[[length(buf)]]$page_end)
        units[[length(units)]] <<- prev
        buf <<- list(); bw <<- 0
        return(invisible())
      }
    }
    # section_path of a unit = the deepest path seen in it that is non-empty
    sp <- Filter(nzchar, vapply(buf, function(x) x$section_path, ""))
    units[[length(units) + 1]] <<- list(
      doc_id = doc_id,
      text = txt,
      section_path = if (length(sp)) sp[[length(sp)]] else "",
      page_start = buf[[1]]$page_start,
      page_end = buf[[length(buf)]]$page_end,
      printed_page_start = buf[[1]]$printed_page,
      printed_page_end = buf[[length(buf)]]$printed_page,
      is_exec_summary = any(vapply(buf, function(x) isTRUE(x$is_exec_summary), TRUE))
    )
    buf <<- list(); bw <<- 0
  }

  i <- 1
  while (i <= length(paras)) {
    p <- paras[[i]]
    pw <- nwords(p$text)

    if (isTRUE(p$is_heading)) {
      # a heading opens a unit only if the current one already stands alone
      if (bw >= WORD_FLOOR) flush()
      buf[[length(buf) + 1]] <- p; bw <- bw + pw
      i <- i + 1; next
    }

    if (pw > WORD_CEILING) {
      if (bw >= WORD_FLOOR) flush()
      for (q in split_long_paragraph(p)) {
        buf[[length(buf) + 1]] <- q; bw <- bw + nwords(q$text)
        if (bw >= WORD_TARGET) flush()
      }
      i <- i + 1; next
    }

    # a unit must be contiguous: a jump of more than one page means the buffer
    # and this paragraph are not the same passage (e.g. an epigraph page
    # followed by the first body page)
    if (length(buf) && p$page_start > buf[[length(buf)]]$page_end + 1) flush()

    if (bw > 0 && bw + pw > WORD_CEILING && bw >= WORD_FLOOR) flush()
    buf[[length(buf) + 1]] <- p; bw <- bw + pw
    if (bw >= WORD_TARGET) flush()
    i <- i + 1
  }
  flush()

  # drop units that are nothing but a heading
  units <- Filter(function(u) nwords(u$text) >= 25, units)

  # identifiers (codebook §6.4): [DOC_ID]_[SECTION]_[PXX_XX]
  ids <- character(length(units))
  for (k in seq_along(units)) {
    u <- units[[k]]
    use_printed <- !is.na(u$printed_page_start) && !is.na(u$printed_page_end)
    ps <- if (use_printed) u$printed_page_start else u$page_start
    pe <- if (use_printed) u$printed_page_end   else u$page_end
    ids[k] <- sprintf("%s_%s_P%02d_%02d", u$doc_id, slugify_section(u$section_path), ps, pe)
  }
  dup <- ave(seq_along(ids), ids, FUN = seq_along)
  ids <- ifelse(dup > 1, paste0(ids, "_", dup), ids)

  for (k in seq_along(units)) {
    units[[k]]$unit_id <- ids[k]
    units[[k]]$unit_seq <- k
    units[[k]]$word_count <- nwords(units[[k]]$text)
  }
  units
}

# -----------------------------------------------------------------------------
segment_document <- function(doc_id) {
  message("[", doc_id, "]")
  L <- read_lines_jsonl(file.path(EXT_DIR, paste0(doc_id, "_lines.jsonl")))
  L <- mark_apparatus(L)
  L <- classify_headings(L)
  L <- apply_section_paths(L)

  dropped <- L[!is.na(L$drop_reason), c("page", "col", "y", "n_words", "text", "drop_reason")]
  dropped$doc_id <- doc_id

  B <- L[is.na(L$drop_reason), ]
  paras <- build_paragraphs(B)
  units <- assemble_units(paras, doc_id)

  out <- file.path(UNIT_DIR, paste0(doc_id, ".jsonl"))
  con <- file(out, "w", encoding = "UTF-8")
  for (u in units) {
    writeLines(toJSON(list(
      unit_id = u$unit_id, unit_seq = u$unit_seq, doc_id = u$doc_id,
      section_path = u$section_path,
      page_start = u$page_start, page_end = u$page_end,
      printed_page_start = u$printed_page_start, printed_page_end = u$printed_page_end,
      word_count = u$word_count, is_exec_summary = u$is_exec_summary,
      text = u$text
    ), auto_unbox = TRUE, na = "null"), con, useBytes = TRUE)
  }
  close(con)

  wc <- vapply(units, function(u) u$word_count, 0)
  message(sprintf("    %d units | words %d-%d (median %d) | %d lines dropped (%d words)",
                  length(units), min(wc), max(wc), as.integer(stats::median(wc)),
                  nrow(dropped), sum(dropped$n_words)))
  list(dropped = dropped, n_units = length(units), wc = wc,
       kept_words = sum(vapply(units, function(u) u$word_count, 0)),
       dropped_words = sum(dropped$n_words))
}

main <- function() {
  man <- read.csv(MANIFEST, stringsAsFactors = FALSE)
  all_drop <- list(); summ <- list()
  for (doc_id in man$doc_id) {
    r <- segment_document(doc_id)
    all_drop[[doc_id]] <- r$dropped
    summ[[doc_id]] <- data.frame(
      doc_id = doc_id, n_units = r$n_units,
      words_coded = r$kept_words, words_dropped = r$dropped_words,
      pct_coded = round(100 * r$kept_words / (r$kept_words + r$dropped_words), 1),
      min_words = min(r$wc), median_words = stats::median(r$wc), max_words = max(r$wc),
      n_under_floor = sum(r$wc < WORD_FLOOR), n_over_ceiling = sum(r$wc > WORD_CEILING),
      stringsAsFactors = FALSE
    )
  }
  write.csv(do.call(rbind, all_drop), file.path(LOG_DIR, "segmentation_log.csv"), row.names = FALSE)
  s <- do.call(rbind, summ)
  write.csv(s, file.path(LOG_DIR, "segmentation_summary.csv"), row.names = FALSE)
  message("\n"); print(s)
  message("\ntotal units: ", sum(s$n_units))
}

if (sys.nframe() == 0L || identical(environment(), globalenv())) main()
