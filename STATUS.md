# Project Status — Codebook v2 and the First Coded Corpus

**Date:** 2026-08-21
**Codebook:** v2.0.1 · **Benchmarks:** v2 (30 units) · **Corpus:** 389 units coded
**Audience:** Project PI

This is the third document in the sequence. `CODING_READINESS.md` raised seven blocking
questions; `DECISIONS.md` answered them; this file reports what was built, what it found,
and what still needs a decision.

**A fuller write-up with the tables is published here:**
https://claude.ai/code/artifact/b1a8cec4-92b7-4d7a-99c8-91a8c593d3c7

---

## 1. Read this before the numbers

The 389 scores in `output/coded_units.csv` were produced **inside a Claude Code session**,
not by a versioned API call. There is no `ANTHROPIC_API_KEY` on this machine, so
`R/03_evaluate.R` could not run.

Every record is stamped `scoring_route: "interactive_session"` and
`prompt_sha256: "INTERACTIVE_SESSION_NOT_REPRODUCIBLE"`. `R/05_reliability.R` detects that
stamp and refuses to treat the run as a reproducibility claim.

**This pass is an audit of the instrument, not the dataset.** It tells you whether the
codebook, the segmenter and the flag rules behave sensibly on real text. Nothing here is
reportable until the API run replaces it.

---

## 2. What was built

### Codebook v2.0.0 → v2.0.1
Full changelog in `codebook/CHANGELOG.md`. All seven `DECISIONS.md` rulings implemented:

| Ruling | Implemented as |
| :--- | :--- |
| 1 · Remove the Score-3 cap | Cap deleted; **`binding_status`** added per unit (enacted / directed / proposed / aspirational / n/a); **Score-3 Evidence Test** (instrument + addressee + consequence, each quoted) gates every 3 |
| 2 · Ordinal chunk, continuous document | Thematic Intensity + Density computed in `R/04_assemble.R` |
| 3 · Independent six-theme vector | Model returns only the vector; `primary_theme`/`secondary_theme` derived in R, tie-break `T3→T1→T2→T5→T4→T6` |
| 4 · Human Target Constraint | Codified, plus the "infrastructure that observes people is Theme 1" clarification and a new **purpose test** (see §4.3) |
| 5 · Semantic segmentation | `R/02_segment.R`, 100–350 words, your `[DOC_ID]_[SECTION]_[PXX_XX]` ID format |
| 6 · 30-unit balanced benchmark matrix | `data/benchmarks/gold_standard_v2_30_benchmarks.json`, all 24 cells populated |
| 7 · Native language in, English out | In the codebook and `prompts/coder_v1.md`; non-English units auto-flagged |

Also added: codeable-text rules (§6), version/provenance stamping (§7), operational
confidence and flag triggers (§8).

### Pipeline
```
R/01_extract.R            PDF -> layout-aware line records
R/02_segment.R            lines -> units, exclusions logged
R/build_benchmarks_v2.R   v1 18 benchmarks -> v2 30-unit matrix
R/03_evaluate.R           units -> Claude API (batch, cached prefix, structured output)
R/03b_ingest_interactive.R  first-pass scores from a Claude Code session
R/04_assemble.R           coded -> coded_units.csv, document_indices.csv, flag_queue.csv
R/05_reliability.R        stability, benchmark agreement, human agreement, diagnostics
```
`prompts/coder_v1.md` + `prompts/output_schema.json` are the production instrument, hashed
and stamped on every record. `CLAUDE.md` is explicitly **not** the coder.

One extraction note worth keeping: `SING1` and `SING2` are printed as two-page spreads.
`pdf_text()` walks them in raster order and interleaves the columns line by line, producing
text that reads as nonsense. `01_extract.R` detects the gutter geometrically and rebuilds
reading order. Any future document with a multi-column or spread layout is handled.

---

## 3. What the first pass found

**389 units · 92,688 words coded (89.5% of extracted) · 21.6% flagged · High 335 / Moderate 54 / Low 0**

Both problems `CODING_READINESS.md` predicted are confirmed as instrument artefacts, not
properties of the documents:

- **Theme 1 and Theme 3 blind spot closed.** Across the 18 v1 benchmarks Theme 3 scored 0
  every time and Theme 1 was non-zero once. Under v2 the corpus yields **31 non-zero Theme 1
  units and 27 non-zero Theme 3 units** — Surat's 600-camera network, Singapore's border
  risk-profiling, the IMDA–SUTD "automated surveillance monitoring" trial, India's proposed
  police procurement line for "face detection and object tracking, number plate detection".

- **Score 3 is no longer American-only.** v1 had all four 3s in `US1.pdf`. v2 has 13 score-3
  observations across three jurisdictions: USA (T2 ×4, T3 ×1, T6 ×4), Germany (T4 ×3 —
  Works Constitution Act co-determination and the GDPR right to human review), India (T4 ×1
  — Srikrishna). One correction cut *against* the US: v1 benchmark 5 scored T6 = 3 on
  "maintain its global military preeminence", which names no instrument, addressee or
  consequence and is now a 1.

`binding_status` is carrying real information the intensity score cannot: India is ~85%
`proposed` (a discussion paper), the US ~86% `directed` (an executive action plan),
Singapore ~45% `enacted` (documenting operating programmes).

**Honest null result:** no unit reaches T1 = 3 or T5 = 3. None of these five documents
mandates biometric population tracking or a statutory production quota. See §4.6.

---

## 4. Outstanding issues

Each has a defensible default already implemented, and each is cheap to change now and
expensive after a 300-document run. Items 1–6 are also listed under *Open items* in
`codebook/CHANGELOG.md`.

### 4.1 Does "Option B" include `binding_status`? — **needs your ruling**
`DECISIONS.md` §1 says "Adopt Option B", and Option B in `CODING_READINESS.md` is *split the
variable* — remove the cap **and** add `binding_status`. Your summary text mentions only the
cap. I implemented both halves because the field is purely additive: ignoring it reproduces
cap-free scoring exactly. If you want cap removal alone, delete codebook §5.2 and the schema
key; **no scores change**.

### 4.2 Score-3 Evidence Test, condition 1: strict or permissive? — **changes a real score**
I adopted permissive: an instrument specified in enough detail to identify its obligations
qualifies, even if not yet drafted as law. Under permissive, India's Srikrishna passage is a
3; under strict it stays at 2. This changes the direction of the India–US comparison.

### 4.3 The Theme 1 purpose test — **the one thing I added that you did not rule on**
The Human Target Constraint alone makes every personalised public service score as
surveillance: clinical risk scores, Andhra Pradesh's dropout model, adaptive learning. v2.0.1
adds a purpose test — Theme 1 requires a security, enforcement, border, eligibility or
population-management purpose; prediction that delivers a benefit *to the person scored* is
Theme 5. This is what keeps the theme measuring digital authoritarianism, per `DECISIONS.md`
§4.C. Confirm it, or tell me you want the capability recorded regardless of purpose.

### 4.4 Model and determinism — **`DECISIONS.md` §8 is not executable as written**
`temperature: 0.0` does not exist on `claude-opus-5` and returns HTTP 400. The pipeline pins
`claude-opus-5` at `effort: "high"` and replaces the determinism *claim* with a *measured*
run-to-run stability statistic. If you need the literal parameter, the pipeline must drop to
`claude-opus-4-6` — there is a config switch at the top of `R/03_evaluate.R`.

### 4.5 `regime_type` source — **blocking for Paper 2's independent variable**
v1 benchmarks mixed V-Dem and EIU labels with no citation. `data/corpus_manifest.csv` has
`regime_type`, `regime_source` and `regime_year` columns, all currently `PENDING`. Name one
source and one year rule (V-Dem Regimes of the World at publication year is the usual choice
for this literature) and it gets joined in rather than typed per unit.

### 4.6 Sampling frame — **decide before document 200, not after**
With four liberal or electoral jurisdictions, Themes 1 and 3 will show low variance however
well the instrument works. If the paper's contribution rests on variation in surveillance and
information control, the sample needs cases that vary on it. That is a sampling-frame
decision, not a coding one.

### 4.7 Human validation hours — **still the binding constraint**
The flag threshold cannot be tuned without a number, and the pipeline is unvalidated until a
blind human-coded sample exists. `R/05_reliability.R` already consumes
`data/benchmarks/human_coded_sample.csv` the moment it appears.

### 4.8 Known limitations in the current output
- **Seven of the 30 benchmarks are synthetic exemplars.** No corpus document reaches T1=3,
  T3=3, T4=3-enacted, T5=3, T6=3-non-US or T2=3-non-US, so those cells are anchored by text
  written in the register of the instrument class it represents, marked
  `source_type: "synthetic_exemplar"` with a warning field. They are calibration anchors only
  and must never be cited as corpus evidence. Replacing them with verbatim units from real
  instruments (EU AI Act, India DPDP Act 2023, a deep-synthesis provision) is the highest-value
  benchmark work remaining.
- **12 units exceed the 350-word ceiling** (max 424). All are the deliberate merge-into-previous
  rule for short residual fragments, and all are flagged.
- **Section paths are imperfect on heavily-designed pages.** `SGP_NAIS_2019` in particular has
  a few units whose `section_path` root is an interview question rather than a section head.
  This affects the `unit_id` slug and nothing else — not the text, not the scores.
- **PDFs are tracked in git.** Roughly 40 MB. `.gitignore` no longer claims otherwise. If you
  want them out, `git rm --cached` them and rely on the manifest's SHA-256 and `source_url`
  columns — but `source_url` and `retrieved_date` are also `PENDING` and need filling first.

---

## 5. Next iteration

In order. Only the first step is blocking.

1. **Get an API key** with billing at `console.anthropic.com`, put it in `~/.Renviron` (which
   `.gitignore` covers), and `install.packages("httr2")`. The API is billed separately from a
   Claude Code subscription. The whole corpus is roughly **$7** on the batch endpoint.

2. **Answer §4.1–§4.4.** These four change the instrument. Doing them before the API run
   avoids re-scoring.

3. **Run `Rscript R/03_evaluate.R`.** Batch endpoint, cached prefix, structured output pinned
   to the JSON schema, resumable — it skips any unit already scored under the current codebook
   and prompt hash. It writes real provenance over the interactive stamps.

4. **Diff the two passes.** The interactive scores stay in `data/coded_interactive/*.psv`, so
   the API run can be compared unit by unit. **Where they disagree is where the codebook is
   ambiguous** — that diff is the cheapest codebook-improvement signal available.

5. **Re-score a random ≥10% a second time** and run
   `Rscript R/05_reliability.R --stability-run data/coded_rerun`. That number replaces the
   determinism claim and belongs in the methods section.

6. **Work the flag queue.** `output/flag_queue.csv` has 84 units with text, scores, binding
   status and justification, so it can be adjudicated without opening the PDFs. This is also
   how the corpus-verbatim benchmarks that would replace the synthetic exemplars get built.

7. **Code 100–150 units blind** and drop them in as `data/benchmarks/human_coded_sample.csv`
   with columns `unit_id, T1_surveillance, ..., T6_geopolitical, coder_id`. Until that exists
   the instrument is unvalidated and the output is not publishable.

8. **Then scale.** Sampling frame (§4.6), the corpus manifest, OCR fallback for scanned
   documents, and language handling. Nothing about the pipeline needs to change to go from 5
   documents to 300 — it is already batched, cached, resumable and per-document.

---

## 6. Where things are

| Path | What |
| :--- | :--- |
| `codebook/codebook_detailed.md` | The instrument, v2.0.1 |
| `codebook/CHANGELOG.md` | Every change, dated, with open items |
| `prompts/coder_v1.md`, `prompts/output_schema.json` | The production coder, hashed |
| `data/corpus_manifest.csv` | One row per document; `PENDING` fields need filling |
| `data/benchmarks/gold_standard_v2_30_benchmarks.json` | Calibration set, 24/24 cells |
| `data/units/*.jsonl` | 389 units of analysis |
| `data/coded/*.jsonl` | Scored units with full provenance |
| `data/coded_interactive/*.psv` | First-pass scores as editable pipe-separated text |
| `output/coded_units.csv` | **The analysis dataset** |
| `output/document_indices.csv` | Intensity, density, max, n3 per document per theme |
| `output/flag_queue.csv` | 84 units awaiting human adjudication |
| `output/reliability_report.md` | Regenerated by `R/05_reliability.R` |
| `logs/segmentation_log.csv` | Every dropped line, with a reason |

Run every script from the project root.
