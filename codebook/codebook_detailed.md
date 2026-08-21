# Comprehensive AI Policy Content Analysis Codebook

**Version:** 2.0.1
**Status:** Active
**Supersedes:** v1.0.0 (see `codebook/CHANGELOG.md`)
**Authority:** `DECISIONS.md` (PI rulings on the seven blocking questions in `CODING_READINESS.md`)

---

## 1. Unit of Analysis & Evaluation Protocol

- **Unit of Analysis:** A natural semantic structural unit of policy text — a paragraph, a
  policy-action clause, or a bounded run of paragraphs under one heading. Target 150–300
  words; **hard floor ~100 words, hard ceiling ~350 words** (§6.3).
- **Core Task:** Assign an independent ordinal intensity score (0–3) to **every one of the six
  thematic dimensions** for every unit, plus a `binding_status`, a confidence level, a review
  flag, and a qualitative justification.
- **No thematic hierarchy at scoring time.** `primary_theme` and `secondary_theme` are
  *derived labels*, computed downstream in R from the six-score vector (§4.2). The coder never
  decides them.
- **Analytic record:** the six-score vector $\vec{S} = \langle T_1, T_2, T_3, T_4, T_5, T_6 \rangle$,
  $T_k \in \{0,1,2,3\}$, is the data of record. Everything else is metadata or derived.

### 1.1 Reproducibility standard (replaces the v1 `temperature = 0.0` rule)

The v1 rule required `temperature = 0.0` with greedy decoding. **That parameter no longer
exists on current Claude models** — sending `temperature` to `claude-opus-5` returns HTTP 400.
It is accepted only on Opus 4.6 / Sonnet 4.6 and older. The v1 rule is therefore not
executable on the model this project uses.

The replacement standard has three parts:

1. **Fixed, hashed inputs.** Every scoring call uses a version-controlled prompt template and
   codebook, both SHA-256 hashed and recorded per unit (§7).
2. **Fixed sampling controls.** `output_config.effort` is pinned (default `high`) and recorded
   per unit. Adaptive thinking is on. No sampling parameters are sent.
3. **Measured stability, not asserted determinism.** A random ≥10% of units is re-scored in an
   independent run and exact-match agreement on the six-score vector is reported as a
   reliability statistic (`R/05_reliability.R`). The paper reports a measured number rather
   than a parameter claim.

*Rationale:* `temperature = 0` never guaranteed identical output — greedy decoding still varies
with batching and hardware. A measured stability rate is a stronger and more defensible claim
than a parameter setting. This resolves an open item that `DECISIONS.md` §8 Step 3 did not
address (it specifies `temperature: 0.0`, which the API will reject). **PI ruling required —
see `codebook/CHANGELOG.md` § Open items.**

---

## 2. Universal Scoring Anchor Definitions (0–3 Scale)

The scale measures **coerciveness of the mechanism described**. It does *not* measure whether
that mechanism is already in force — that is recorded separately in `binding_status` (§5.2).

| Score | Level | Definition & Operational Thresholds |
| :--- | :--- | :--- |
| **0** | **Absent** | The thematic concept is unmentioned, irrelevant, or explicitly disclaimed. |
| **1** | **Aspirational / Rhetorical** | Non-binding ethical guidelines, high-level vision statements, international soft alignment, voluntary principles, or study-group mandates lacking dedicated budget, statutory enforcement, or administrative apparatus. |
| **2** | **Substantive / Funded / Institutional** | Funded R&D grant programmes, public-private research testbeds, regulatory sandboxes, pilot implementations, standing inter-agency councils or task forces, voluntary evaluation toolkits, published draft legislative frameworks. |
| **3** | **Coercive Mandate / State Preemption / Bypass** | Executive emergency mobilisation, mandatory export bans or sanctions, statutory or regulatory review bypasses, mass biometric population tracking, mandatory telecommunications intercept requirements, punitive sanction regimes, compulsory compliance audits, coercive state security deployment. |

### 2.1 No document-class ceiling

**National strategy documents and executive directives are eligible for Score 3.** The v1 rule
capping "policy recommendations, draft white papers, and multi-year vision documents" at Score
`2` is **removed** (`DECISIONS.md` §1).

*Rationale:* national AI strategies reveal state preferences and executive intent. Capping them
at `2` produced a ceiling effect that made Score 3 unobtainable across the corpus and prevented
the instrument from distinguishing states that encourage technology development from states
planning population control, coercive supply-chain exclusion, or sweeping regulatory
preemption. It also applied unevenly in v1 — waived for `US1`, enforced against `IND1`.

### 2.2 The Score-3 Evidence Test

A score of `3` on any theme requires **all three** of the following, each citable in the
justification:

1. **Instrument** — an identifiable legal, regulatory, or executive instrument, not a goal.
   *Reading adopted (permissive):* the instrument must be specified in enough detail to
   identify the obligations it imposes. A named bill, published framework, signed order, or a
   recommendation enumerating the specific obligations of a proposed regime all qualify. A bare
   intention ("the government will consider regulating X") does not.
2. **Addressee** — a specified party placed under obligation: a platform, an ISP, an agency, a
   class of firms, a population. "The government will strive to…" has no addressee.
3. **Consequence** — a penalty, sanction, compliance audit, mandatory exclusion, licence or
   contract loss, or an explicit override of an otherwise-applicable legal requirement.

If only two of the three are present, the ceiling for that theme is `2`, and the unit is
flagged for human review (§8.2). State in the justification which of the three were found and
quote the operative language.

The Evidence Test governs **intensity only**. It is deliberately silent on whether the
instrument is in force; that is `binding_status`. A directive that would compel platform
takedowns under penalty scores `3` with `binding_status: "directed"`; the same measure once in
force scores `3` with `binding_status: "enacted"`.

---

## 3. Thematic Dimensions & Coding Criteria

Score every theme independently. A unit may score `3` on two themes simultaneously; themes do
not compete.

| Key | Theme |
| :--- | :--- |
| `T1_surveillance` | State Surveillance & Domestic Control |
| `T2_executive` | Executive Power, Emergency Bypass & Deregulation |
| `T3_infocontrol` | Information Integrity, Narrative Control & Censorship |
| `T4_civilrights` | Civil Rights, Privacy & Judicial Guardrails |
| `T5_economic` | Economic Baseline, Compute Infrastructure & Industrial Policy |
| `T6_geopolitical` | International Competitiveness, Export Controls & Strategic Rivalry |

### Theme 1 — `T1_surveillance`: State Surveillance & Domestic Control

- **Scope:** State monitoring, biometric profiling, mass surveillance grids, intelligence
  data-sharing, predictive policing, automated risk-scoring of persons.
- **Human Target Constraint (binding):** Theme 1 applies **only** to tracking, monitoring,
  predictive profiling, biometric identification, data aggregation, or automated risk-scoring
  directed at **human individuals, citizen populations, or social groups**.
- **Look-For Indicators:** facial recognition grids, automated border and immigration
  screening, CCTV sensor fusion, "safe city" and integrated command centres, law-enforcement
  analytics, predictive crime detection, crowd and movement analytics, population registries
  linked to identification systems.
- **Negative Boundary:** automated monitoring of *physical* infrastructure — smart power grids,
  freight and cargo tracking, agricultural soil sensors, traffic-flow optimisation of vehicles
  as objects, utility telemetry — belongs to **Theme 5**, not Theme 1.
- **Purpose test (v2.0.1):** the Human Target Constraint identifies *what* is observed; this test
  identifies *why*. Theme 1 requires that the state observe, profile, or score persons for
  **security, law enforcement, intelligence, order maintenance, border or immigration control,
  eligibility restriction, or population management**. Individual-level prediction whose stated
  purpose is delivering a benefit *to the person scored* — clinical risk prediction, learning
  personalisation, outreach to individuals at risk of dropping out — is **Theme 5** sectoral
  deployment, not Theme 1, unless the text indicates enforcement, restriction, denial, or a
  security purpose. Without this test, every personalised public service scores as surveillance
  and the theme stops measuring digital authoritarianism, which is what `DECISIONS.md` §4.C says
  it is for. Where a system serves both purposes, dual-code and flag.
- **Boundary clarification (v2, load-bearing):** the negative boundary excludes *infrastructure*
  monitoring. It does **not** exclude infrastructure that observes *people*. Municipal camera
  networks, "safe city" command centres, and crowd or movement analytics are **Theme 1** even
  when presented as smart-city, urban-planning, or traffic programmes. The test is whether
  individuals or populations are the object of observation, regardless of the programme's
  stated framing. Where a system observes both (e.g. a traffic system that also reads number
  plates against a watchlist), dual-code T1 and T5.
- **Scoring Anchors:**
  - `0`: No monitoring of persons mentioned.
  - `1`: AI named as a tool for public safety, policing, national security, or emergency
    response with no programme, budget, procurement, or named implementing body.
  - `2`: Funded municipal surveillance pilots, integrated police database trials, automated
    port/border biometric screening programmes, named command centres with allocated resources.
  - `3`: Binding mandates for data forwarding to state security bodies; warrantless algorithmic
    monitoring; statutorily authorised nationwide biometric identification; compulsory
    registration of individuals in a state-operated identification or monitoring system.

### Theme 2 — `T2_executive`: Executive Power, Emergency Bypass & Deregulation

- **Scope:** Centralisation of presidential/prime-ministerial authority, fast-track permitting,
  emergency deregulation, suspension or override of normal statutory oversight.
- **Look-For Indicators:** fast-track permitting regimes (e.g. FAST-41), NEPA categorical
  exclusions, national-security procurement waivers, defence production authorities invoked for
  compute, unilateral executive task forces displacing legislative procedure, sunset or
  moratorium of existing regulation by executive action, preemption of subnational law.
- **Negative Boundary:** ordinary inter-ministerial coordination bodies with no exemption or
  override power are Theme 5 institutional capacity, not Theme 2.
- **Scoring Anchors:**
  - `0`: No executive bypass, preemption, or regulatory fast-tracking.
  - `1`: High-level statements about "speeding up bureaucracy", "cutting red tape", or
    "streamlining government" with no mechanism named.
  - `2`: Inter-agency bodies established by executive action **to propose or design** regulatory
    exemptions, waivers, or fast-track pathways; regulatory sandboxes that suspend specified
    requirements for enrolled participants; published review of rules "for possible repeal".
  - `3`: Executive directives overriding statutory environmental, labour, or procurement
    review; categorical exclusions from an otherwise-applicable statutory process; invocation
    of defence production or emergency powers for AI compute; conditioning federal funds on
    subnational regulatory forbearance.

### Theme 3 — `T3_infocontrol`: Information Integrity, Narrative Control & Censorship

- **Scope:** Algorithmic content moderation, online speech filtering, automated censorship,
  synthetic-media provenance and watermarking, and state curation of what information reaches
  the public — including the informational character of state-procured AI systems.
- **Look-For Indicators:** deepfake detection or removal mandates, platform liability regimes,
  real-time social-media filtering, mandatory content verification pipelines, **state
  procurement conditioned on model viewpoint, output neutrality, or ideological character**,
  government-mandated or government-funded provenance and watermarking schemes, **official
  revision of state risk frameworks to add or remove categories of disfavoured content**, state
  evaluation of foreign models for political alignment, platform transparency-reporting
  obligations, misinformation/disinformation programmes.
- **Negative Boundary:** cybersecurity measures protecting infrastructure integrity are Theme 5;
  monitoring of *individuals* is Theme 1. Where a measure restricts content **and** monitors
  individuals, dual-code T3 and T1.
- **Scoring Anchors:**
  - `0`: No speech, media, content, or information-integrity dimension.
  - `1`: Voluntary guidelines, digital-literacy campaigns, or statements of concern about
    mis/disinformation and synthetic media with no mechanism attached.
  - `2`: State-funded watermarking, provenance, or synthetic-media detection research and
    pilots; consultative platform–government forums; procurement or funding guidance that
    references content characteristics without an enforcement consequence; revision of a
    non-binding state framework's content categories.
  - `3`: Binding obligations on platforms or model developers to remove, label, filter, or
    alter content — or to satisfy a viewpoint or neutrality condition — where non-compliance
    carries a penalty, disqualification, or loss of contract.

### Theme 4 — `T4_civilrights`: Civil Rights, Privacy & Judicial Guardrails

- **Scope:** Statutory data protection, algorithmic transparency and explainability, anti-bias
  audit, independent oversight, worker co-determination, judicial review and redress rights.
- **Look-For Indicators:** statutory privacy rights (GDPR-style), algorithmic impact
  assessments, mandatory red-teaming, right to explanation, workforce co-determination law,
  independent audit bodies, data protection authorities, private rights of action.
- **Negative Boundary:** high-level slogans ("we support ethical AI", "human-centric AI",
  "trustworthy AI") without independent enforcement or legal liability score `1`, however
  frequently repeated.
- **Scoring Anchors:**
  - `0`: No civil rights, privacy, or judicial guardrail dimension.
  - `1`: Non-binding ethical principles, voluntary "responsible AI" pledges, awareness campaigns.
  - `2`: Institutional testing toolkits (e.g. AI Verify), regulatory sandbox compliance
    programmes, draft privacy-commission frameworks and recommendations, funded workforce data
    protection studies, standing ethics councils with a defined remit.
  - `3`: Enacted or specified statutory data privacy regimes with binding financial penalties;
    legally enforceable private rights of action; mandatory pre-deployment algorithmic
    discrimination bans; compulsory independent audit with sanction for non-compliance.

### Theme 5 — `T5_economic`: Economic Baseline, Compute Infrastructure & Industrial Policy

- **Scope:** Domestic baseline capacity: research grants, SME adoption, STEM education and
  workforce training, digital infrastructure (data centres, compute clusters, broadband),
  sectoral deployment (agriculture, health, logistics, manufacturing), industrial automation.
- **Look-For Indicators:** national compute clusters, university R&D funding, workforce
  upskilling, smart agriculture, public-private research partnerships, gigabit expansion,
  sector deployment programmes, **telemetry and algorithmic optimisation of physical equipment,
  freight, crops, cargo, utilities and energy grids**.
- **Scoring Anchors:**
  - `0`: No economic, infrastructural, or domestic capacity dimension.
  - `1`: Broad economic vision statements ("AI will transform our economy by 2030"), market-size
    projections, generic calls for competitiveness with no programme.
  - `2`: Committed state R&D grants, named sectoral deployment programmes, SME digital adoption
    centres, funded supercomputing access, established research institutes and chairs,
    workforce training schemes with targets.
  - `3`: Statutory state-directed industrial mandates; sovereign capital allocation tied to
    mandatory production quotas; compulsory domestic-content or localisation requirements
    enforced by penalty or market exclusion.

### Theme 6 — `T6_geopolitical`: International Competitiveness, Export Controls & Strategic Rivalry

- **Scope:** Cross-border strategic competition, export controls, sovereign supply-chain
  security, foreign-adversary exclusion, multilateral alliance building and standard-setting.
- **Look-For Indicators:** semiconductor export restrictions, foreign-adversary ICTS
  prohibitions, bilateral and multilateral R&D clusters, international standard-setting
  leadership, technology-transfer restrictions, inbound/outbound investment screening,
  full-stack technology export promotion to allies.
- **Scoring Anchors:**
  - `0`: No international or cross-border dimension.
  - `1`: General rhetoric about "maintaining national leadership", "winning the AI race", or
    "collaborating with global partners".
  - `2`: Formalised cross-border R&D funding clusters, bilateral data-sharing frameworks,
    funded participation in international standard-setting bodies, diplomatic AI initiatives
    with named programmes.
  - `3`: Technology export bans or licence regimes; mandatory supply-chain exclusions barring
    foreign-adversary hardware or software from critical infrastructure; sanctions, tariffs, or
    investment prohibitions imposed on named jurisdictions.

---

## 4. Disambiguation & Derived Labels

### 4.1 Disambiguation rules (applied at scoring time)

1. **Independence.** Score all six themes independently. If a paragraph contains Theme 2
   deregulation at `3` and Theme 6 export controls at `3`, record both as `3`. There is no
   forced choice and no "primary" decision.
2. **Operative action over preamble rhetoric — within a theme, not between themes.** Aspirational
   framing about rights alongside concrete spending does not suppress the Theme 4 score to 0; it
   scores Theme 4 = `1` (rhetoric) and Theme 5 = `2` (funded programme). Rhetoric is `1`, not
   absence.
3. **Human Target Constraint.** Theme 1 = surveillance of persons. Theme 5 = telemetry of
   things. See the Theme 1 boundary clarification for infrastructure that observes people.
4. **No document-class ceiling.** §2.1. Legal force is recorded in `binding_status`, never
   smuggled into the intensity score.
5. **Score-3 Evidence Test.** §2.2 gates every `3`.

### 4.2 Derived labels — computed in R, never by the coder

`primary_theme` and `secondary_theme` are computed by `R/04_assemble.R` from
`scores_full_breakdown`:

1. `primary_theme` = theme with the highest score.
2. `secondary_theme` = highest-scoring of the remaining five, provided that score is ≥ 1;
   otherwise `"None"` with `secondary_score: 0`.
3. **Tie-break precedence (fixed):** `T3 → T1 → T2 → T5 → T4 → T6`.
   This order is arbitrary but fixed; it reproduces the label choice made implicitly by every
   tied case in the v1 benchmark set. Changing it later is a recomputation, not a re-run.
4. A unit may have `primary_score: 1`. Never inflate a score to justify a label.

*Rationale:* anything computable from the scores is computed in code, not generated by the
model. Every field the model does not decide is a field that cannot drift across 36,000 units.

### 4.3 Document-level aggregation (computed in R)

For document $i$ and theme $k$ over $N_i$ units:

$$\text{Thematic Intensity}_{i}^{(k)} = \frac{1}{N_i} \sum_{j=1}^{N_i} S_{i,j,k}
\qquad
\text{Thematic Density}_{i}^{(k)} = \frac{1}{N_i} \sum_{j=1}^{N_i} \mathbb{I}(S_{i,j,k} \ge 1)$$

Also reported: `max_score` per theme, `n_units_at_3`, and the length-normalised composite used
as the panel treatment variable. Chunk-level scores remain strictly ordinal; continuous
variation is manufactured at the document level, not asked of the coder.

---

## 5. Document Class and Binding Status

### 5.1 Document Class — assigned once per document in `data/corpus_manifest.csv`

| Class | Definition | Examples |
| :--- | :--- | :--- |
| **A — Instrument in force** | Legal instrument with current operative effect: statute in force, promulgated regulation, signed order with immediate legal effect. | EU AI Act; India DPDP Act 2023 |
| **B — Executive action plan** | Issued under executive authority, instructing named agencies to act, but whose listed actions are prospective or recommendatory. | America's AI Action Plan (2025) |
| **C — Strategy or advisory document** | Roadmap, vision document, discussion paper, or committee report with no direct legal effect. | NITI Aayog NAIS (2018); Germany AI Strategy (2018); Singapore NAIS (2019, 2023) |
| **D — Consultative input** | Non-governmental submission, stakeholder response, or draft circulated for comment. | Public consultation responses |

Document class is a property of issuing authority and legal form. It is **never re-decided per
unit** and it **never caps a score**.

### 5.2 Binding Status — coded per unit

Records the legal force of the mechanism in that unit, independent of its intensity score.

| Value | Definition |
| :--- | :--- |
| `enacted` | In force now. Cites an existing statute, regulation, or order, or describes an operating programme. |
| `directed` | A competent authority has instructed a named body to implement it; not yet in force. |
| `proposed` | Recommended, under study, or awaiting decision by a body with authority to decide. |
| `aspirational` | Stated as a goal or value with no implementation pathway identified. |
| `n/a` | All six themes score 0. |

Where binding status differs across themes within a unit, record the status of the
**highest-scoring** theme's mechanism (ties broken by §4.2's precedence order).

---

## 6. Codeable Text and Unit Segmentation

### 6.1 Included

- Body prose of substantive sections, including boxed text, case studies, and narrative inside
  tables.
- Bulleted or numbered policy-action lists, treated as prose.
- Executive summaries — coded, but tagged `is_exec_summary: true` so they can be excluded in
  robustness checks.

### 6.2 Excluded

Cover and title pages; tables of contents; section-divider and graphic-only pages; ministerial
forewords and prefaces; acknowledgments, contributor and author lists; endnotes, footnotes and
reference lists; image captions, figure labels and chart source lines; page headers, footers and
page numbers; glossaries; annexes consisting of names, membership lists, or reproduced
correspondence.

Excluded text is dropped at segmentation and never reaches the coder. `logs/segmentation_log.csv`
records what was dropped and why, so the exclusion is auditable.

### 6.3 Segmentation rules

1. Segment on natural heading and paragraph delimiters. Target 150–300 words; **floor ~100,
   ceiling ~350**.
2. Never split a sentence. Never split a bullet mid-item.
3. Boundary preference order: paragraph break → bullet-item boundary → subheading.
4. A subheading and the prose immediately beneath it belong to the same unit.
5. A policy-action list under one heading forms a single unit if ≤ 350 words; otherwise split at
   bullet-item boundaries, never inside one.
6. A residual fragment under ~100 words is merged into the **preceding** unit even if the result
   exceeds 350 words (absolute cap 450); an orphan heading or short preamble is merged into the
   **following** block.
7. Every unit records `word_count`, `page_start`, `page_end`, `section_path`, and
   `is_exec_summary`.

### 6.4 Unit identifiers

`unit_id` format (`DECISIONS.md` §5): `[DOC_ID]_[SECTION]_[PXX_XX]`

    USA_AIAP_2025_PIL02_P14_15
    IND_NAIS_2018_AGRI_P30_33

`SECTION` is a deterministic slug derived from the heading chain. Where two units in one section
share a page span, a numeric discriminator is appended (`..._P14_15_2`). A guaranteed-unique
integer `unit_seq` is carried alongside for joins; `section_path` carries the human-readable
heading chain.

---

## 7. Versioning and Provenance

Every coded unit records, alongside its scores:

`codebook_version`, `codebook_sha256`, `prompt_version`, `prompt_sha256`, `model_id`, `effort`,
`scored_at` (UTC), `run_id`, `scoring_route`.

`scoring_route` distinguishes `api_batch` / `api_sync` (reproducible production runs) from
`interactive_session` (exploratory passes made inside a Claude Code session, which are **not**
reproducible and must be superseded before publication).

The codebook will change during the project. Without these fields you cannot tell which version
scored which unit, which makes partial re-runs impossible and turns any mid-project revision
into a full corpus re-run.

---

## 8. Confidence and Human Review

### 8.1 Confidence

- **High** — operative language is explicit; the mechanism and its binding status are stated in
  the unit itself.
- **Moderate** — the mechanism is clear but its intensity sits on a boundary (e.g. two of the
  three Score-3 conditions met), or two themes are close and the distinction is contestable.
- **Low** — the unit is fragmentary, refers to an instrument it does not describe, or its
  meaning depends on context outside the unit.

### 8.2 Mandatory review flags — set `flag_human_review: "YES"` if ANY apply

| Trigger | `flag_reason` |
| :--- | :--- |
| Two or more themes tie at ≥ 2 | `Polysemic Uncertainty` |
| Exactly two of the three Score-3 conditions met | `Conflicting Statutory Mandates` |
| Unit cites an external instrument without describing its content | `Missing Operational Context` |
| `word_count` < 100 or > 350 | `Missing Operational Context` |
| Confidence is `Low` | (as applicable) |
| Source text is non-English or translated | `Missing Operational Context` |
| Theme 1 or Theme 3 scored ≥ 2 | `Polysemic Uncertainty` |

The last row is deliberate: Themes 1 and 3 are the project's substantive focus and its
least-calibrated dimensions. Every positive finding on them is human-confirmed until the
benchmark set covers those cells with corpus-verbatim exemplars.

Expect a 15–25% flag rate initially. Thresholds are tightened after the pilot reports what
actually fires.

---

## 9. Multilingual Sources

- Policy texts are fed to the coder **in their original language, without pre-translation**.
- All structured output — keys, score vector, `binding_status`, `justification` — is produced in
  **English**.
- `source_language` and `is_translation` are recorded in the corpus manifest; any non-English
  unit is flagged for human review (§8.2) until multilingual agreement has been measured.

*Rationale:* pre-translation strips legal nuance and alters operative regulatory verbs. Native
comprehension with standardised English output preserves the nuance and keeps one tabular
dataset for analysis in R.

---

## 10. Required Output Schema (per unit)

Enforced by `prompts/output_schema.json` via the Messages API `output_config.format`, so
malformed output is impossible rather than merely rare.

```json
{
  "unit_id": "string",
  "scores_full_breakdown": {
    "T1_surveillance": 0,
    "T2_executive": 0,
    "T3_infocontrol": 0,
    "T4_civilrights": 0,
    "T5_economic": 0,
    "T6_geopolitical": 0
  },
  "binding_status": "enacted | directed | proposed | aspirational | n/a",
  "score3_evidence": {
    "instrument": "string | null",
    "addressee": "string | null",
    "consequence": "string | null"
  },
  "confidence_level": "High | Moderate | Low",
  "flag_human_review": "YES | NO",
  "flag_reason": "None | Polysemic Uncertainty | Conflicting Statutory Mandates | Missing Operational Context",
  "justification": "2-4 sentences citing operative verbs and the codebook rule applied."
}
```

`primary_theme`, `primary_score`, `secondary_theme`, `secondary_score` are **absent by design**.
They are added by `R/04_assemble.R` (§4.2). `score3_evidence` is populated whenever any theme
scores 3 (and whenever the two-of-three near-miss triggers a flag); otherwise its fields are
`null`.
