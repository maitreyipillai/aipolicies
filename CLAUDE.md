# AI Policy Content Analysis Pipeline (Paper 2)

## Project Overview
This repository conducts automated, systematic content analysis of national AI strategy
documents across 6 themes, scoring each text unit **independently on all six** using an
ordinal 0–3 scale.

| Key | Theme |
| :--- | :--- |
| `T1_surveillance` | State Surveillance & Domestic Control |
| `T2_executive` | Executive Power, Emergency Bypass & Deregulation |
| `T3_infocontrol` | Information Integrity, Narrative Control & Censorship |
| `T4_civilrights` | Civil Rights, Privacy & Judicial Guardrails |
| `T5_economic` | Economic Baseline, Compute Infrastructure & Industrial Policy |
| `T6_geopolitical` | International Competitiveness, Export Controls & Strategic Rivalry |

## Core Reference Files
- **Codebook (authoritative):** `codebook/codebook_detailed.md` — **v2.0.0**
- **Changelog & open PI items:** `codebook/CHANGELOG.md`
- **Production prompt:** `prompts/coder_v1.md` + `prompts/output_schema.json`
- **Calibration benchmarks:** `data/benchmarks/gold_standard_v2_30_benchmarks.json`
  (v1's 18-unit file is retained for provenance only)
- **PI rulings:** `DECISIONS.md` — **overrides anything that conflicts with it**
- **Outstanding questions:** `CODING_READINESS.md`

## Methodological & Execution Rules

1. **Reproducibility — NOT `temperature`.** `temperature` does not exist on `claude-opus-5`
   and returns HTTP 400. Determinism is established by (a) hashed prompt and codebook,
   (b) pinned `output_config.effort` (`high`), (c) **measured** run-to-run stability on a
   ≥10% re-scored sample. Never write `temperature` into a request for a current model.
2. **Unit of analysis:** natural semantic units — paragraphs and policy-action clauses.
   Floor ~100 words, ceiling ~350. Never split a sentence or a bullet item.
3. **Scoring scale (0–3)** measures **coerciveness of the mechanism**, not whether it is in
   force. Legal force is recorded separately in `binding_status`.
   - `0` Absent · `1` Aspirational/rhetorical · `2` Substantive/funded/institutional ·
     `3` Coercive mandate / state preemption / bypass
4. **No document-class ceiling.** Strategy documents and executive action plans are eligible
   for `3`. Every `3` must pass the **Score-3 Evidence Test** (instrument + addressee +
   consequence, each quoted). Two of three caps the theme at `2` and raises a flag.
5. **Rhetoric is 1, not 0.** Themes do not compete; a concrete mechanism in one theme never
   suppresses another theme to 0.
6. **Human Target Constraint.** T1 = observation of people (including municipal camera
   networks and safe-city command centres, whatever their framing). T5 = telemetry of things
   (freight, crops, grids, utilities).
7. **No primary/secondary at scoring time.** Those labels are derived in `R/04_assemble.R`
   from the six-score vector, with fixed tie-break `T3 → T1 → T2 → T5 → T4 → T6`.
8. **Native language in, English out.** Never pre-translate source text.

## Pipeline

```
R/01_extract.R          PDF -> layout-aware line records (column-aware; SING1 is 2-up)
R/02_segment.R          lines -> units, with the §6.2 exclusions logged
R/build_benchmarks_v2.R v1 18 benchmarks -> v2 30-unit balanced matrix
R/03_evaluate.R         units -> Claude API (batch, cached prefix, structured output)
R/04_assemble.R         coded -> output/coded_units.csv + document_indices.csv + flag_queue.csv
R/05_reliability.R      stability, benchmark agreement, human agreement, diagnostics
```

Run every script from the project root. `03_evaluate.R` needs `ANTHROPIC_API_KEY` in
`~/.Renviron` and the `httr2` package; the API is billed separately from a Claude Code
subscription.

## Required Output Schema (per unit)

The model returns **only** this. `primary_*` / `secondary_*` are added later in R.

```json
{
  "unit_id": "string",
  "scores_full_breakdown": {
    "T1_surveillance": 0, "T2_executive": 0, "T3_infocontrol": 0,
    "T4_civilrights": 0, "T5_economic": 0, "T6_geopolitical": 0
  },
  "binding_status": "enacted | directed | proposed | aspirational | n/a",
  "score3_evidence": { "instrument": null, "addressee": null, "consequence": null },
  "confidence_level": "High | Moderate | Low",
  "flag_human_review": "YES | NO",
  "flag_reason": "None | Polysemic Uncertainty | Conflicting Statutory Mandates | Missing Operational Context",
  "justification": "2-4 sentences citing operative verbs and the codebook rule applied."
}
```

## Working rules for interactive sessions

- **This file is not the coder.** The production instrument is `prompts/coder_v1.md`, which
  is hashed and version-controlled. Scoring policy text by pasting it into a chat produces
  unversioned, unreproducible numbers — if a first pass is done that way it must be stamped
  `scoring_route: "interactive_session"` and superseded before anything is reported.
- Every coded record carries `codebook_version`, `codebook_sha256`, `prompt_version`,
  `prompt_sha256`, `model_id`, `effort`, `scored_at`, `run_id`, `scoring_route`.
- When a codebook change alters scores, bump the version, log it in
  `codebook/CHANGELOG.md`, and re-run — `03_evaluate.R` re-scores only affected units.
