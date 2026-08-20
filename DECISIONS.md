# Methodological Decisions & Operational Coding Harness (Codebook v2.0 Architecture)

**Target Audience:** Claude / Automated Coding Pipeline & Project PI  
**Document Purpose:** Definitive PI methodological decisions resolving all 7 blocking questions raised in `CODING_READINESS.md` (Part 1). This document provides direct operational instructions to amend `codebook/codebook_detailed.md` to v2.0.0, balance the few-shot benchmark suite, and execute the R extraction and scoring pipeline.

---

## 1. Strategy Document vs. Statutory Mandate Capping (Question 1)

### A. Issue Raised in `CODING_READINESS.md`
The preliminary codebook contained an artificial ceiling rule that capped national AI strategy documents and executive white papers at Score `2`, reserving Score `3` exclusively for enacted statutory legislation. Because national AI strategy documents are executive policy roadmaps rather than passed statutory laws, this rule truncated the scale and made Score `3` unobtainable across the seed corpus that was initially examined.

### B. Operational Decision & Instruction for Claude
- **Directive:** **Adopt Option B — Completely Remove the Statutory Cap.**
- **Operational Rule:** National strategy documents and executive directives ARE eligible for **Score 3 (Hard Mandate / State Coercion / Executive Bypass)** whenever the policy text articulates clear state coercive intent, creates binding executive exclusions, mandates data-intercept architectures, or explicitly directs regulatory bypasses.
- **Scoring Anchors:**
  - `Score 0 (Absent)`: No mention of the thematic dimension.
  - `Score 1 (Aspirational / Rhetorical)`: Non-binding ethical guidelines, high-level vision statements, international soft alignment, or voluntary principles lacking fiscal or administrative enforcement.
  - `Score 2 (Institutional / Funded / Pilots)`: Funded R&D grant programs, public-private research testbeds, regulatory sandboxes, standing inter-agency advisory councils, or voluntary evaluation toolkits.
  - `Score 3 (Coercive Mandate / State Preemption / Bypass)`: Executive emergency mobilization, mandatory export bans/sanctions, statutory/regulatory review bypasses, mass biometric population tracking, or mandatory telecommunications intercept requirements.

### C. Methodological Justification (The "Why")
National AI strategies reflect revealed state preferences and executive intent. Capping strategy documents at `2` artificially compresses the variance of the index and creates a ceiling effect, preventing the model from distinguishing between states that merely encourage tech development versus states actively planning authoritarian population control, coercive supply-chain bans, or sweeping regulatory preemption.

---

## 2. Scoring Scale Resolution & Aggregation Architecture (Question 2)

### A. Issue Raised in `CODING_READINESS.md`
Evaluating whether the coding scheme should remain a 4-point ordinal scale (0, 1, 2, 3), collapse to a binary presence/absence indicator (0 or 1), or expand to a continuous spectrum scale (0–100).

### B. Operational Decision & Instruction for Claude
- **Directive:** **Maintain the 4-Point Ordinal Scale (0, 1, 2, 3) at the Chunk Level; Aggregate to Continuous Spectrum Indices at the Document/Country Level in R.**
- **Operational Rule for Claude:** Evaluate individual text chunks strictly on the discrete ordinal scale: $S_{k} \in \{0, 1, 2, 3\}$.
- **Downstream Aggregation Rule for R:** Compute document-level continuous indices via Mean Thematic Intensity and Normalized Thematic Density:
  $$\text{Thematic Intensity}_{i, t}^{(k)} = \frac{1}{N_i} \sum_{j=1}^{N_i} S_{i, j, k}$$
  $$\text{Thematic Density}_{i, t}^{(k)} = \frac{1}{N_i} \sum_{j=1}^{N_i} \mathbb{I}(S_{i, j, k} \ge 1)$$

### C. Methodological Justification (The "Why")
- **Chunk-Level Reliability:** Prompting an LLM on a continuous 0–100 scale introduces subjective variance and hallucinated decimal shifts (e.g., distinguishing between 64 and 72 without discrete anchors), which severely degrades inter-coder reliability ($\alpha$). The 0–3 ordinal scale provides discrete qualitative anchors (`Absent`, `Rhetoric`, `Funded/Institutional`, `Mandate/Bypass`).
- **Macro-Level Continuous Variance:** Binary coding (0/1) loses critical intensity signals (blurring empty rhetoric with fully-funded programs). By aggregating ordinal chunk scores across the whole document in R, we generate a continuous, length-normalized treatment variable ($Treatment_{it} \in \mathbb{R}$) for panel regression modeling against human rights indices.

---

## 3. Thematic Vector Scoring Architecture & Multi-Label Independence (Question 3)

### A. Issue Raised in `CODING_READINESS.md`
Forcing text chunks into a strict "Primary Theme" and "Secondary Theme" hierarchy creates arbitrary priority rules, produces forced-choice distortion when multiple mechanisms appear at equal intensity, and complicates automated evaluation.

### B. Operational Decision & Instruction for Claude
- **Directive:** **Score as an Independent 6-Theme Vector $\vec{S}$.**
- **Operational Rule:** Every text unit must receive an independent score $(0, 1, 2, \text{ or } 3)$ across all six thematic dimensions simultaneously:
  $$\vec{S} = \langle T_1, T_2, T_3, T_4, T_5, T_6 \rangle, \quad T_k \in \{0, 1, 2, 3\}$$
- **Theme Vector Keys:**
  1. `T1_surveillance`: State Surveillance & Domestic Control
  2. `T2_executive`: Executive Power, Emergency Bypass & Deregulation
  3. `T3_infocontrol`: Information Integrity, Narrative Control & Censorship
  4. `T4_civilrights`: Civil Rights, Privacy & Judicial Guardrails
  5. `T5_economic`: Economic Baseline, Compute Infrastructure & Industrial Policy
  6. `T6_geopolitical`: International Competitiveness, Export Controls & Strategic Rivalry
- **Elimination of Hierarchy:** If a paragraph contains both Theme 2 deregulation (Score 3) and Theme 6 export sanctions (Score 3), both are preserved independently as `3` in the score vector.

### C. Methodological Justification (The "Why")
National policy directives frequently combine multiple distinct governance mechanisms into a single operational clause (e.g., fast-tracking data centers while banning foreign adversary chips). Treating themes as orthogonal dimensions preserves full multi-label variance, eliminates artificial competition between themes, and streamlines ICR metric calculations across independent columns.

---

## 4. Disambiguation Boundary: Human Surveillance vs. Physical Infrastructure (Question 4)

### A. Issue Raised in `CODING_READINESS.md`
Potential coding overlap and polysemic confusion between municipal infrastructure telemetry (e.g., smart power grids, port logistics, traffic optimization) and state population surveillance.

### B. Operational Decision & Instruction for Claude
- **Directive:** **Enforce Strict Human Target Constraint.**
- **Operational Rule:**
  - **Theme 1 (`T1_surveillance`):** Strictly restricted to tracking, monitoring, predictive profiling, biometric identification, data aggregation, or automated risk-scoring directed at **human individuals, citizen populations, or social groups**.
  - **Theme 5 (`T5_economic`):** Applies to sensor monitoring, tracking, algorithmic optimization, or telemetry of **physical equipment, commercial freight logistics, agricultural crop yields, maritime cargo, public utilities, and energy grids**.

### C. Methodological Justification (The "Why")
Infrastructure and municipal logistics monitoring represent standard civil economic optimization and developmental capacity building. Theme 1 is theoretically linked to digital authoritarianism, physical integrity rights, and civil liberties; therefore, it must strictly capture state surveillance directed at human beings.

---

## 5. Unit of Analysis & Semantic Structural Segmentation (Question 5)

### A. Issue Raised in `CODING_READINESS.md`
Arbitrary fixed-word-count chunking (e.g., strictly cutting text every 200 words) chops sentences, fragments policy clauses, and separates operative verbs from their institutional context.

### B. Operational Decision & Instruction for Claude
- **Directive:** **Segment by Natural Semantic Structural Units (Paragraphs & Policy Action Clauses).**
- **Operational Rule:**
  - Segment documents using natural heading and paragraph delimiters.
  - Enforce a minimum floor of **~100 words** (merge short orphan headers/preambles into the following block) and a maximum ceiling of **~350 words** (split massive multi-item lists along numbered sub-action items).
  - Every unit must have a unique identifier: `[DOC_ID]_[SECTION]_[PXX_XX]`.

### C. Methodological Justification (The "Why")
Policy text is written in discrete semantic units (policy recommendations, action lines, and programmatic pillars). Preserving natural syntactic boundaries ensures that Claude evaluates complete policy intentions rather than fragmented sentence artifacts.

---

## 6. Benchmark Suite Calibration & Matrix Balancing (Question 6)

### A. Issue Raised in `CODING_READINESS.md`
The initial 18 hand-coded benchmark units left critical matrix cells empty (e.g., Theme 3 had zero Score 3 examples; Theme 2 had zero Score 2 examples) and reflected the legacy strategy document cap.

### B. Operational Decision & Instruction for Claude
- **Directive:** **Expand and Calibrate the Benchmark Suite to a Complete 30-Unit Balanced Matrix.**
- **Operational Rule:**
  - Update the existing 18 benchmark cases in `data/benchmarks/gold_standard_18_benchmarks.json` to reflect the removed strategy cap and independent 6-theme score vector.
  - Draft and calibrate ~12 additional benchmark units from the seed corpus (or adjacent national AI strategies) to ensure all 24 cells ($6 \text{ themes} \times 4 \text{ scoring tiers } [0, 1, 2, 3]$) have explicit gold-standard few-shot anchor cases.

### C. Methodological Justification (The "Why")
Few-shot calibration requires representative examples across every score level for every theme. Populating the full $6 \times 4$ matrix anchors Claude’s probabilistic thresholds, eliminating blind spots in rare but critical categories like state censorship (`T3`) and emergency executive mobilization (`T2`).

---

## 7. Cross-National Corpus Scaling & Multilingual Source Processing (Question 7)

### A. Issue Raised in `CODING_READINESS.md`
Handling the expansion of the corpus from the initial 5 seed documents to hundreds of OECD/non-OECD national strategies published in non-English languages (e.g., German, French, Spanish, Mandarin, Japanese).

### B. Operational Decision & Instruction for Claude
- **Directive:** **Native Source Language Comprehension with Standardized English JSON Output.**
- **Operational Rule:**
  - Feed raw policy texts into Claude in their original native language without pre-translation.
  - Require Claude to parse the linguistic context natively and produce all structured output keys, numerical score vectors $\vec{S}$, and qualitative justifications strictly in **English**.

### C. Methodological Justification (The "Why")
Pre-translating policy documents often strips legal nuance and alters operative regulatory verbs. Modern large language models comprehend native syntax and legal phrasing with high fidelity, and enforcing English JSON outputs maintains a unified, standardized tabular dataset for statistical processing in R.

---

## 8. Pipeline Execution Blueprint (Steps for Claude & R)

1. **Step 1:** Update `codebook/codebook_detailed.md` to **v2.0.0**, logging an explicit changelog that formalizes these 7 decisions.
2. **Step 2:** Update and expand `data/benchmarks/gold_standard_18_benchmarks.json` to the complete 30-unit benchmark suite.
3. **Step 3:** Construct the R execution pipeline (`01_extract.R`, `02_segment.R`, `03_evaluate.R`) utilizing `httr2`/`ellmer` at `temperature: 0.0` to generate `master_coding_dataset.csv`.
4. **Step 4:** Run the Inter-Coder Reliability (ICR) validation script to calculate Cohen’s $\kappa$ and Krippendorff’s $\alpha$ across the benchmark set.
