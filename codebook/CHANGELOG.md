# Codebook Changelog

All notable changes to `codebook/codebook_detailed.md`. Versions are semantic; every coded unit
records `codebook_version` and `codebook_sha256` so scores can always be traced to the
instrument that produced them.

---

## [2.0.0] — 2026-08-21

Implements the seven PI rulings in `DECISIONS.md`, which resolve the blocking questions raised
in `CODING_READINESS.md` Part 1. **Breaking**: the output schema changed; all v1 coding is
superseded.

### Changed — scale semantics

- **Removed the document-class ceiling.** v1 §4 rule 4 capped "policy recommendations, draft
  white papers, and multi-year vision documents" at Score `2`. Deleted. National strategy
  documents and executive directives are now eligible for Score `3` (`DECISIONS.md` §1).
  Fixes the v1 asymmetry in which the cap was waived for `US1` and enforced against `IND1`.
- The 0–3 scale now measures **coerciveness of the mechanism** only. Legal force moved to a
  separate field (below).
- Rewrote all four universal anchors to the wording ratified in `DECISIONS.md` §1.B.

### Added — `binding_status` (§5.2)

Per-unit field ∈ {`enacted`, `directed`, `proposed`, `aspirational`, `n/a`}, recording the legal
force of the unit's mechanism independently of its intensity. Implements the *split the
variable* half of `CODING_READINESS.md` Decision 1 Option B. Collapsing `binding_status`
reproduces the old uniform-ceiling numbers; the reverse is not possible, so nothing is lost.
**See Open items 1.**

### Added — Score-3 Evidence Test (§2.2)

Every `3` requires an identifiable **instrument**, a specified **addressee**, and a
**consequence**, each quoted in the justification. Two-of-three caps the theme at `2` and
raises a review flag. The **permissive** reading of condition 1 is adopted: an instrument
specified in enough detail to identify its obligations qualifies, even if not yet drafted as
law. **See Open items 2.**

### Changed — thematic architecture (§1, §3, §4.1)

- **Eliminated the primary/secondary hierarchy at scoring time** (`DECISIONS.md` §3). Every unit
  now receives an independent score on all six themes; themes never compete.
- Renamed themes to stable machine keys: `T1_surveillance`, `T2_executive`, `T3_infocontrol`,
  `T4_civilrights`, `T5_economic`, `T6_geopolitical`. Theme 2 gains "& Deregulation", Theme 3 is
  restated as "Information Integrity, Narrative Control & Censorship", Theme 5 gains "Compute
  Infrastructure", Theme 6 gains "Export Controls".
- `primary_theme` / `secondary_theme` are now **derived labels computed in `R/04_assemble.R`**,
  not model output. Fixed tie-break precedence `T3 → T1 → T2 → T5 → T4 → T6`, the order every
  tied case in the v1 benchmark set already followed implicitly. Resolves the v1 contradiction
  where identical inputs (highest non-primary = 1) produced `"None"` in benchmarks 6/8/13 and a
  named theme in benchmarks 2/7/10/12/15/18.

### Changed — Theme 1 / Theme 5 boundary (§3, `DECISIONS.md` §4)

- Codified the **Human Target Constraint**: Theme 1 is surveillance of persons; Theme 5 is
  telemetry of things.
- Added the load-bearing clarification that **infrastructure which observes people is Theme 1**,
  regardless of smart-city or urban-planning framing. The v1 wording ("smart municipal grids →
  Theme 5") read as licence to route municipal camera networks into Theme 5; that is what caused
  the `IND1` safe-city passages to be scored `T1 = 0`.

### Added — Theme 1 and Theme 3 anchor expansion (§3)

Fills the empty calibration cells. Across the 18 v1 benchmarks, Theme 3 scored 0 in all 18 and
Theme 1 was non-zero once; 9 of the 24 theme × tier cells had no exemplar. Theme 3 gains
indicators for procurement conditioned on model viewpoint, state revision of risk-framework
content categories, government watermarking and provenance schemes, and platform transparency
obligations, plus full 1/2/3 anchors. Theme 1 gains explicit `1` and `3` anchors.

### Added — codeable text and segmentation (§6)

New section defining what text is coded (body prose, policy-action lists, executive summaries
tagged `is_exec_summary`) and what is dropped (front matter, forewords, TOC, footnotes,
references, captions, glossaries, name-list annexes). Sets the denominator for every
proportional claim and makes cross-document comparison independent of document design.

Segmentation follows `DECISIONS.md` §5: natural semantic units, floor ~100 words, ceiling ~350,
never splitting a sentence or a bullet. `unit_id` format `[DOC_ID]_[SECTION]_[PXX_XX]` as
specified by the PI, with an integer `unit_seq` carried for joins.

### Added — document class (§5.1)

Controlled vocabulary A–D assigned once per document in `data/corpus_manifest.csv`. Descriptive
only; it never caps a score.

### Added — versioning and provenance (§7)

Every unit stamps `codebook_version`, `codebook_sha256`, `prompt_version`, `prompt_sha256`,
`model_id`, `effort`, `scored_at`, `run_id`, `scoring_route`. Makes partial re-runs possible
after a codebook revision instead of forcing a full corpus re-run.

### Added — confidence and review flags (§8)

Operational definitions for High/Moderate/Low and seven mandatory flag triggers. v1's benchmarks
were uniformly `High` / `NO`, which as few-shot examples would have taught the coder that
nothing is ever uncertain.

### Added — document-level aggregation (§4.3) and multilingual handling (§9)

Thematic Intensity and Thematic Density formulas per `DECISIONS.md` §2; native-language input
with English structured output per `DECISIONS.md` §7.

### Changed — reproducibility standard (§1.1)

**Removed `temperature = 0.0`.** The parameter does not exist on `claude-opus-5` and returns
HTTP 400; it survives only on Opus 4.6 / Sonnet 4.6 and older. Replaced with: hashed prompt and
codebook, pinned `output_config.effort`, and **measured** run-to-run stability on a ≥10% re-scored
sample reported as a reliability statistic. **See Open items 3.**

### Changed — output schema (§10)

Model output is now the six-key score vector plus `binding_status`, `score3_evidence`,
confidence, flag, and justification. `primary_*` / `secondary_*` removed from model output.
Enforced by `prompts/output_schema.json` through `output_config.format`.

---

## Open items — PI ruling still required

These were raised in `CODING_READINESS.md` but not addressed in `DECISIONS.md`. Each has a
defensible default implemented in v2.0.0; each is cheap to change now and expensive to change
after a 300-document run.

1. **`binding_status` — confirm.** `DECISIONS.md` §1 says "Adopt Option B", and Option B in
   `CODING_READINESS.md` is *split the variable* — remove the cap **and** add `binding_status`.
   The PI's summary text mentions only the cap removal. v2.0.0 implements both halves, because
   the field is purely additive: ignoring it reproduces cap-free scoring exactly. If the PI
   wants cap removal alone, delete §5.2 and the `binding_status` key from the schema — no scores
   change.
2. **Score-3 Evidence Test, condition 1 — strict or permissive.** v2.0.0 adopts permissive
   (an instrument specified in enough detail to identify its obligations qualifies). Under
   permissive, `IND1`'s Srikrishna data-protection passage (v1 benchmark 15) moves from `2` to
   `3`; under strict it stays at `2`. This changes real scores and the direction of the
   India–US comparison.
3. **Model and determinism.** v2.0.0 pins `claude-opus-5` at `effort: "high"` and reports
   measured stability. `DECISIONS.md` §8 Step 3 specifies `temperature: 0.0`, which the API
   rejects on this model. If the PI requires the literal `temperature` parameter, the pipeline
   must drop to `claude-opus-4-6`; `R/03_evaluate.R` has that path behind a config switch.
4. **`regime_type` source.** v1 benchmarks mixed V-Dem and EIU labels with no citation.
   `data/corpus_manifest.csv` has `regime_type`, `regime_source`, `regime_year` columns; the
   values are provisional placeholders pending a single named source (V-Dem Regimes of the World
   at document publication year is the recommendation).
5. **Codeable-text exclusions.** §6.1–6.2 implements the `CODING_READINESS.md` Decision 3
   recommendation (exclude mechanical apparatus, code executive summaries but tag them). Not
   ruled on by the PI.
6. **Sampling frame, country vs country-year weighting, human-validation hours.** Unaddressed;
   they do not block the pilot but do block the scale-up and the flag-threshold setting.

---

## [1.0.0] — prior to 2026-08-21

Initial codebook: six themes, 0–3 anchors, primary/secondary hierarchy, `temperature = 0.0`
determinism rule, document-class Score-3 cap. Retained in git history; superseded in full.
