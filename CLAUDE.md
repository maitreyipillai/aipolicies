# AI Policy Content Analysis Pipeline (Paper 2)

## Project Overview
This repository conducts automated, systematic content analysis of national AI strategy documents across 6 core themes using an ordinal 0–3 scoring scale:
- Theme 1: State Surveillance & Domestic Control
- Theme 2: Executive Power & Emergency Bypass
- Theme 3: Information Control & Content Curation
- Theme 4: Civil Rights, Privacy & Judicial Guardrails
- Theme 5: Economic & Industrial Strategy
- Theme 6: International Competitiveness & Geopolitical Control

## Core Reference Files
- **Detailed Codebook:** `codebook/codebook_detailed.md`
- **Calibration Benchmarks:** `data/benchmarks/gold_standard_18_benchmarks.json`
- **Raw Policy Documents:** `data/raw_policies/`

## Methodological & Execution Rules
1. **Deterministic Scoring:** Always maintain deterministic scoring (`temperature = 0.0`) with greedy decoding.
2. **Unit of Analysis:** Text is analyzed in discrete paragraphs or sub-clauses (150–300 words).
3. **Scoring Standard (0–3 Scale):**
   - `0`: Absent
   - `1`: Aspirational / Non-binding Principles / Rhetoric
   - `2`: Substantive / Funded / Institutional / Pilots / Draft Laws
   - `3`: Binding Statutory Mandate / State Coercion / Executive Emergency Bypass
4. **Codebook Compliance:** Always strictly apply the priority hierarchy, scope rules, and negative look-for boundaries defined in `codebook/codebook_detailed.md`.

## Required Output Schema
When evaluating any policy text chunk, provide output formatted strictly as a single valid JSON object:

```json
{
  "unit_id": "string",
  "primary_theme": "string",
  "primary_score": 0,
  "secondary_theme": "string",
  "secondary_score": 0,
  "scores_full_breakdown": {
    "theme_1": 0,
    "theme_2": 0,
    "theme_3": 0,
    "theme_4": 0,
    "theme_5": 0,
    "theme_6": 0
  },
  "confidence_level": "High | Moderate | Low",
  "flag_human_review": "YES | NO",
  "flag_reason": "None | Polysemic Uncertainty | Conflicting Statutory Mandates | Missing Operational Context",
  "justification": "2-4 sentence qualitative audit trail citing operative verbs and codebook rules."
}
