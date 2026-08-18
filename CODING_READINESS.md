# Getting Ready to Code: What's Needed Before This Pipeline Can Run

**Status:** Draft for review
**Date:** 2026-08-18
**Audience:** Project PI (you). Assumes no prior experience with Claude Code or the Claude API.
**Scope note:** This plan assumes the project eventually scales from the current 5 documents to **hundreds** of documents. Several recommendations below would be overkill for 5 documents and are essential at 300.

---

## How to read this document

The work splits into two kinds:

| Kind | Who does it | Where it appears |
|---|---|---|
| **Research decisions** — judgment calls about what your scale *means*. I cannot make these for you without changing your findings. | You | Part 1 |
| **Construction** — codebook text, scripts, file formats, cost control, reliability machinery. | Me, once Part 1 is settled | Parts 2–6 |

Part 1 is the only part that blocks progress. It is seven questions, each with my recommendation attached, so you can reply "agree with all" or amend individual items. Everything after that is work I can do.

**Read Part 1 and Part 7. Skim the rest.** Part 7 is the short version of what I need from you.

---

## Part 0: Where things stand

You have a genuinely good starting position. Five national AI strategy documents, all with clean extractable text (no scanning or OCR needed), a six-theme codebook with written scoring anchors, and 18 hand-coded benchmark units spanning all five documents. That is more preparation than most content-analysis projects have at this stage.

What is missing is not substance. It is **the machinery that makes the coding reproducible**, plus four internal contradictions in the codebook that will cause the same text to be scored differently depending on when it happens to be coded. At 5 documents you might absorb that. At 300 documents it becomes the finding — reviewers will ask how you know the instrument was stable, and right now there is no answer.

### The corpus as it stands

| File | Document | Pages | Words | Est. units @200 words |
|---|---|---|---|---|
| `US1.pdf` | America's AI Action Plan (White House, Jul 2025) | 28 | 9,543 | ~48 |
| `GER1.pdf` | AI Strategy (Federal Government, Nov 2018) | 45 | 27,250 | ~136 |
| `IND1 (1).pdf` | National Strategy for AI (NITI Aayog, 2018) | 114 | 41,140 | ~206 |
| `SING1.pdf` | National AI Strategy (SNDGO, 2019) | 45 | 14,988 | ~75 |
| `SING2.pdf` | NAIS 2.0 — AI for the Public Good (2023) | 68 | 10,067 | ~50 |
| **Total** | | **300** | **102,988** | **~515** |

Roughly 515 units of analysis in the pilot corpus. At 300 documents, expect **30,000–40,000 units**. That number drives most of the recommendations in Part 5.

---

## Part 1: Seven decisions I need from you

### Decision 1 — Does a "recommended policy action" count as a hard mandate?

**This is the most consequential item in this document.** Everything else is plumbing.

**The problem.** `codebook/codebook_detailed.md:86` says:

> Policy recommendations, draft white papers, and multi-year vision documents are capped at Score `2`. Reserve Score `3` strictly for enacted statutory mandates, binding executive orders, or active coercive enforcement.

But benchmarks 1, 2, and 5 assign **score 3** to passages from `US1.pdf` that sit under the literal heading **"Recommended Policy Actions."** I verified this in the source PDF — the NEPA passage in benchmark 1 begins "Recommended Policy Actions ▪ Establish new Categorical Exclusions under NEPA…". It is a prospective recommendation, not an enacted exclusion.

Meanwhile benchmark 15 caps India at 2 and says so explicitly: *"capped at 2 because it refers to the Srikrishna Committee's draft work rather than an already-enacted statute."*

So the same rule is enforced against India and waived for the United States.

**Why this matters more than it looks.** Every score-3 observation in your entire gold standard — all four of them, across Themes 2 and 6 — comes from `US1.pdf`. If the cap is applied consistently, those become 2s and your top anchor has no exemplars at all. If it is not applied, the US is systematically scored higher than the other three jurisdictions for reasons of document genre rather than policy content. Either way, your central cross-national comparison is affected. This is not a rounding error; it is directional bias in the dependent variable.

**The deeper cause.** Your 0–3 scale is currently trying to measure two different things at once:

1. **How coercive is the mechanism?** (a censorship mandate is more coercive than a literacy campaign)
2. **How legally binding is it right now?** (in force vs. proposed vs. aspirational)

A proposed nationwide biometric mandate is *highly coercive* but *not yet binding*. A funded research grant is *not coercive* but *fully in force*. One number cannot carry both, and the contradiction above is what happens when you try.

**Your options:**

| Option | What it does | Cost | Benefit |
|---|---|---|---|
| **A — Uniform ceiling** | Apply the existing cap strictly. US benchmarks 1/2/5 become 2. Score 3 requires an instrument in force. | You lose all score-3 variance in this corpus. Themes 2 and 6 lose their top anchor. | Simple, one number, defensible. |
| **B — Split the variable** *(recommended)* | Keep 0–3 measuring **coerciveness of the mechanism described**. Add a separate field `binding_status` ∈ {`enacted`, `directed`, `proposed`, `aspirational`}. | One extra field per unit; slightly longer codebook. | Nothing is thrown away. You can report intensity, legal force, or the interaction. Resolves the contradiction without flattening your data. |
| **C — Status quo** | Leave it. | Non-reproducible, and a reviewer will find it. | None. |

**My recommendation: Option B.** It is the only choice that resolves the contradiction by *adding* information rather than discarding it. Concretely, benchmark 1 becomes `primary_score: 3, binding_status: "directed"` — the mechanism is a statutory-review bypass (genuinely a 3 on coerciveness), and the record shows it was directed but not yet in force. India's benchmark 15 becomes `primary_score: 2, binding_status: "proposed"`. Both are now honest, and you can filter either way at analysis time.

If you pick B, you can still produce Option A's numbers later by collapsing `binding_status` — but not the reverse. Draft codebook text is in Part 2, Amendment 1.

---

### Decision 2 — When does a unit get a secondary theme?

**The problem.** `codebook_detailed.md:84` says a secondary theme requires **both** mechanisms to score ≥ 2. Only 3 of your 18 benchmarks satisfy that. Eleven others name a secondary theme scoring 1 — contradicting the rule they were built to demonstrate.

Worse, at the *identical* input condition (highest non-primary theme = 1), the benchmarks do two different things:

| Benchmark | Highest non-primary score | Secondary recorded |
|---|---|---|
| 6, 8, 13 | 1 (Theme 6) | `"None"` |
| 2, 7, 10, 12, 15, 18 | 1 | named |

Same input, different output. A coder — human or model — cannot reproduce that. There is also no tie-break rule, though the benchmarks clearly follow an unstated one: where Themes 4 and 6 tie at 1 (benchmarks 3, 9, 11, 16), Theme 4 wins every time.

**Good news: the stakes are lower than they appear.** `scores_full_breakdown` already contains all six scores for every unit. `primary_theme` and `secondary_theme` are *derived labels*, not independent data. If your analysis uses the six-score vector — which it should — these fields are presentational convenience.

**My recommendation:** (a) state explicitly in the codebook that the **six-score breakdown is the analytic data** and primary/secondary are derived labels; (b) define them by a deterministic rule so they stop varying (draft in Part 2, Amendment 2); (c) recompute them from the breakdown in R rather than asking the model to decide, which removes this failure mode entirely.

That last point is worth emphasising: **anything that can be computed from the scores should be computed in code, not generated by the model.** Every field the model doesn't have to decide is a field that cannot drift across 36,000 units.

---

### Decision 3 — Which text is codeable?

Nothing currently says whether these count:

- Tables of contents, cover pages, section dividers
- Ministerial forewords and prefaces
- Executive summaries (they restate the body — do they get coded twice?)
- Acknowledgments, contributor lists, funding statements
- Endnotes, references, image captions, figure labels
- Annexes, glossaries, appendices

This is not pedantry. It sets the **denominator** for every proportional claim you make. "Theme 1 appears in 12% of India's units" means something different if India's 114 pages include 20 pages of front and back matter and the US's 28 pages include almost none. `IND1` is heavy with front/back matter; `US1` is dense body text throughout. Without a rule, the comparison is distorted by document design.

**My recommendation:** code substantive body text only; exclude the mechanical apparatus; **code executive summaries but tag them** so you can include or exclude them in robustness checks. Draft text in Part 2, Amendment 3.

---

### Decision 4 — Where does `regime_type` come from?

Your benchmarks assert regime classifications inline: Singapore as *"Electoral Autocracy / Dominant Party,"* India as *"Electoral Democracy / Flawed Democracy."* These look like V-Dem and EIU labels respectively — two different schemes, mixed together, with no source cited.

If regime type is an independent variable in Paper 2 — and the framing suggests it is — it needs a single named source, a stated year, and a documented rule. Otherwise a reviewer reasonably asks whether the classification was chosen to fit the result.

**My recommendation:** pick **one** source (V-Dem's Regimes of the World is the usual choice for this literature, and it is free and machine-readable), take the value for the **document's publication year** rather than today, and store it in the corpus manifest — not typed by hand into each unit. At 300 documents, hand-typing regime labels will produce errors; a join against a downloaded V-Dem table will not.

---

### Decision 5 — Model choice, and a problem with your determinism rule

**There is a problem with methodological rule #1.** Both `CLAUDE.md` and `codebook_detailed.md:6` require `temperature = 0.0` with greedy decoding. **On current Claude models, the `temperature` parameter no longer exists.** Sending it to Opus 5, Sonnet 5, Opus 4.8, or Opus 4.7 returns an HTTP 400 error. It is still accepted on Opus 4.6 and Sonnet 4.6 and older models.

So the protocol as written cannot be executed on a current model. You have to choose:

| Option | What it means |
|---|---|
| **A — Use an older model** (Opus 4.6 / Sonnet 4.6) | Preserves the literal `temperature = 0.0` wording. Costs you the newest models' reasoning quality on a task that is genuinely hard. |
| **B — Use Opus 5 and change how you claim determinism** *(recommended)* | Drop the temperature language. Replace it with **measured run-to-run stability**: re-score a random 10% of units a second time and report exact-match agreement on the six-score vector. |

**My recommendation: Option B**, for a reason that is worth understanding. `temperature = 0` was never a guarantee of identical output anyway — it makes token selection greedy, but real inference varies slightly with batching and hardware, so repeated runs can still differ. A paper that *asserts* determinism from a parameter setting is making a weaker claim than one that *measures* stability and reports the number. Option B gives you a reliability statistic you can put in a table; Option A gives you a sentence a methods reviewer may not accept.

Instead of temperature, current models use `effort` (`low` → `max`) to control reasoning depth. For this task I would start at `medium` and test whether `high` changes the scores on your benchmark set.

**Which model.** Default to **Opus 5** for the pilot — this task involves genuinely subtle distinctions (the draft-vs-enacted line, the Theme 1 vs Theme 5 boundary), and the pilot is cheap (~$7–13 for all 515 units; see Part 5). Whether to drop to Sonnet 5 or Haiku 4.5 for the 300-document run is **your call on cost**, and it is a decision you can make with evidence rather than guesswork: score your gold-standard benchmarks with each model and compare agreement. If Sonnet 5 matches Opus 5 on 95% of units, the saving is free. If it doesn't, you know what you'd be buying. I would not switch models without running that comparison.

---

### Decision 6 — What is the corpus, and what language is it in?

At 5 documents this is trivial. At 300 it is a research design question:

**a) Sampling frame.** Where does the list of documents come from? The OECD AI Policy Observatory is the standard source and covers 70+ countries. Whatever you use, it must be written down and dated, because "hundreds of AI policy documents" is not a population — it is a convenience sample unless you define the frame.

**b) One document per country, or all of them?** You currently have Singapore twice (2019 and 2023). That is valuable — it gives within-country change over time — but it means Singapore contributes 7 of your 18 benchmarks and would contribute disproportionate units. Decide whether the unit of comparison is the **country** or the **country-year**, and whether to weight accordingly.

**c) Language.** All five current documents are in English. Across 300 documents, most will not be. Three choices:

1. **English-language official versions only.** Cleanest, but it biases the sample toward countries that publish in English, which correlates with the very variables you are studying.
2. **Code in the original language.** Claude handles many languages well, but your codebook anchors are English and the codebook relies on identifying "operative verbs" — a distinction that does not travel identically across legal traditions.
3. **Machine-translate, then code.** Adds a transformation layer that must be documented and validated.

**My recommendation:** option 1 where an official English version exists, option 2 otherwise, and record which in the manifest as a `source_language` field so you can test whether it predicts scores. Never option 3 silently — if you translate, the translation is part of your method and belongs in the paper.

**d) Document class taxonomy.** Decision 1's approach requires knowing what class each document belongs to. You need a small controlled vocabulary fixed *now*, before 300 documents arrive with 300 self-descriptions. My proposed starting list is in Part 2, Amendment 1.

---

### Decision 7 — How much human validation will you fund?

Automated content analysis is publishable when validated against human coding, and not before. Concretely you need:

| Check | What it is | Suggested size |
|---|---|---|
| **Stability** | Same units scored twice by the model; do you get the same answer? | 10% of units, automated, cheap |
| **Human agreement** | You (or a trained RA) code a random sample blind; compare with Krippendorff's α on each theme | 100–150 units minimum |
| **Held-out gold set** | Verbatim units, coded by hand *before* seeing model output, never used to tune prompts | 50–80 units |
| **Flagged-unit adjudication** | Every unit the model flags for review gets human eyes | Unknown until you see the flag rate — this is why Amendment 6 matters |

**The thing to decide:** how many hours of human coding you can commit. That number determines whether the flag threshold is set tight (fewer flags, more missed) or loose (more flags, more human time). I can't set it without knowing your budget.

**One warning on the current benchmark set.** All 18 benchmarks have `confidence_level: "High"` and `flag_human_review: "NO"`. If those are used as few-shot examples, you are teaching the model that nothing is ever uncertain and nothing ever needs review — across 36,000 units, that field will be dead weight. Amendment 6 fixes this.

---

## Part 2: Example codebook amendments

These are drafts. They are written to be pasted into `codebook/codebook_detailed.md` and edited, not adopted verbatim. Each is keyed to a decision above.

---

### Amendment 1 — Document class and binding status *(Decision 1)*

**Replaces** rule 4 in §4.

```markdown
## 5. Document Class and Binding Status

### 5.1 Document Class (coded once per document, recorded in the corpus manifest)

| Class | Definition | Examples |
| :--- | :--- | :--- |
| **A — Instrument in force** | A legal instrument with current operative effect: statute in force, promulgated regulation, signed executive order or decree with immediate legal effect. | EU AI Act; India DPDP Act 2023 |
| **B — Executive action plan** | Issued under executive authority, instructing named agencies to act, but whose listed actions are prospective or recommendatory. | America's AI Action Plan (2025) |
| **C — Strategy or advisory document** | Roadmap, vision document, discussion paper, or committee report with no direct legal effect. | NITI Aayog NAIS (2018); Germany AI Strategy (2018); Singapore NAIS (2019, 2023) |
| **D — Consultative input** | Non-governmental submission, stakeholder response, or draft circulated for comment. | Public consultation responses |

Document class is assigned once per document from its issuing authority and legal
form — never re-decided per unit.

### 5.2 Binding Status (coded per unit)

Every unit receives a `binding_status` describing the *legal force of the specific
mechanism in that unit*, independent of its intensity score:

| Value | Definition |
| :--- | :--- |
| `enacted` | Mechanism is in force now. Text cites an existing statute, regulation, or order, or describes an operating program. |
| `directed` | A competent authority has instructed a named body to implement it, but it is not yet in force. |
| `proposed` | Recommended, under study, or awaiting a decision by a body with authority to make it. |
| `aspirational` | Stated as a goal or value with no implementation pathway identified. |
| `n/a` | Unit scores 0 on this theme. |

Where a unit's binding status differs across themes, record the status of the
**primary theme's** mechanism.

### 5.3 The Score-3 Evidence Test

A score of `3` on any theme requires **all three** of the following, each citable
in the justification:

1. **Instrument** — an identifiable legal or executive instrument, not a goal.
2. **Addressee** — a specified party placed under obligation (a platform, an ISP,
   an agency, a class of firms). "The government will strive to…" has no addressee.
3. **Consequence** — a penalty, sanction, compliance audit, mandatory exclusion, or
   an explicit override of an otherwise-applicable legal requirement.

If only two of the three are present, the ceiling is `2`. State in the
justification which of the three you found and quote the operative language.

**Note:** the Score-3 Evidence Test governs *intensity*. It is deliberately silent
on whether the instrument is already in force — that is what `binding_status`
records. A directive that would compel platform takedowns under penalty scores 3
with `binding_status: "directed"`; the same measure once in force scores 3 with
`binding_status: "enacted"`.
```

**Effect on existing benchmarks.** Benchmarks 1, 2, and 5 keep `primary_score: 3` and gain `binding_status: "directed"`. Benchmarks 6–14 and 16–18 keep their scores and gain `directed` or `proposed`. The India/US asymmetry disappears because legal force is now recorded in its own field instead of being smuggled into the intensity score.

**Benchmark 15 is the case you need to rule on, and it cuts against the US.** It currently reads `2`, justified as *"capped at 2 because it refers to the Srikrishna Committee's draft work."* Under Option B that cap no longer exists — and the mechanism described is a data-protection regime with *"deterrent penalties and structured enforcement,"* which satisfies all three conditions of the Score-3 Evidence Test. So benchmark 15 arguably becomes **`3` / `proposed`**, raising India rather than lowering the US.

Whether you accept that depends on how tightly you read condition 1. Two readings:

- **Strict** — the instrument must exist as a text (a named bill, published framework, or signed order). A committee recommendation that a law be written is a goal, not an instrument. Benchmark 15 stays at 2.
- **Permissive** *(my lean)* — the instrument must be *specified in enough detail to identify its obligations*. The Srikrishna framework's seven enumerated principles qualify. Benchmark 15 becomes 3.

I lean permissive because it keeps the intensity score measuring one thing consistently, and `binding_status: "proposed"` already carries the "not real yet" information. But this is your call, it changes a real score, and whichever you pick needs one sentence added to condition 1 so the next coder reads it the same way.

---

### Amendment 2 — Deterministic primary and secondary theme *(Decision 2)*

**Replaces** rule 2 in §4.

```markdown
### Primary and Secondary Theme Assignment

The six-score breakdown in `scores_full_breakdown` is the analytic data of record.
`primary_theme` and `secondary_theme` are **derived labels** computed from it, not
independent judgments.

1. Score all six themes independently first.
2. `primary_theme` = the theme with the highest score.
3. `secondary_theme` = the theme with the highest score among the remaining five,
   provided that score is ≥ 1. If all remaining scores are 0, record `"None"` and
   `secondary_score: 0`.
4. **Tie-break.** Where two or more themes tie, select the one appearing first in
   this fixed precedence order:

       Theme 3 → Theme 1 → Theme 2 → Theme 5 → Theme 4 → Theme 6

   This order is arbitrary but fixed. Its only purpose is to make the label
   reproducible, and it is the order the v1 benchmark set was already following
   implicitly. (An alternative, ordering by descending coerciveness —
   `T3 → T1 → T2 → T6 → T4 → T5` — is equally valid but relabels six of the
   eighteen benchmarks; see the note below.)
5. A unit may have `primary_score: 1`. Do not inflate a score to justify a label.
```

**Practical note:** steps 2–4 are pure arithmetic. Compute them in R from the breakdown rather than asking the model to produce them. That eliminates this entire class of inconsistency, and it means changing the tie-break order later is a five-second recomputation rather than a 36,000-unit re-run.

**Effect on existing benchmarks:** benchmarks 6, 8, and 13 gain `secondary_theme: "Theme 6"`, `secondary_score: 1` (they currently record `"None"` despite Theme 6 scoring 1). Benchmark 14 correctly keeps `"None"` — all five non-primary themes are 0.

Six other benchmarks currently resolve ties by unstated convention, so their *labels* depend on which order you adopt. I tested both candidate orders against all 18:

| Precedence order | Benchmarks whose label changes |
|---|---|
| `T3 → T1 → T2 → T6 → T4 → T5` (coercion-first) | 9 — the 3 intended `"None"` fixes, plus 3, 9, 11, 12, 15, 16 flip |
| `T3 → T1 → T2 → T5 → T4 → T6` | 3 — only the intended `"None"` fixes |

The second order reproduces the existing choice in **every** tied case; your benchmarks turn out to have been following it implicitly all along. It is equally arbitrary and equally reproducible — it just isn't ordered by coerciveness. **No scores change under either order**, only the derived label, which is why this is a cosmetic choice: pick one, write it down, and move on.

---

### Amendment 3 — Codeable text and unit segmentation *(Decision 3)*

**New section.**

```markdown
## 6. Codeable Text and Unit Segmentation

### 6.1 Included

- Body prose of substantive sections, including boxed text, case studies, and
  narrative inside tables.
- Bulleted or numbered policy-action lists, treated as prose.
- Executive summaries — coded, but tagged `is_exec_summary: true` so they can be
  excluded in robustness checks. (They restate body content; leaving them in
  double-counts, dropping them silently loses the document's own framing of
  priorities.)

### 6.2 Excluded

Cover and title pages; tables of contents; section-divider and graphic-only pages;
ministerial forewords and prefaces; acknowledgments, contributor and author lists;
endnotes, footnotes, and reference lists; image captions and figure labels; page
headers, footers, and page numbers; glossaries; annexes consisting of names,
membership lists, or reproduced correspondence.

Excluded text is dropped at the segmentation stage and never reaches the coder.
The segmentation log records what was dropped and why, so the exclusion is auditable.

### 6.3 Segmentation rules

1. Target 150–300 words per unit; hard bounds 80–400.
2. Never split a sentence. Never split a bullet mid-item.
3. Prefer natural boundaries: paragraph breaks, then bullet-item boundaries, then
   subheadings.
4. A subheading and the prose immediately under it belong to the same unit.
5. A policy-action list under one heading forms a single unit if ≤ 300 words;
   otherwise split at bullet boundaries, never inside one.
6. A fragment of fewer than 80 words after splitting is merged into the preceding
   unit, even if the result exceeds 300 words, up to the hard bound of 400.
7. Every unit records: `word_count`, `page_start`, `page_end`, `section_path`
   (the heading chain above it), and `is_exec_summary`.
```

**Note on your existing benchmarks:** 14 of the 18 use ellipses to compress non-contiguous passages, and 6 fall outside the declared 150–300 word window (benchmark 18 is 50 words; benchmark 1 is 78). This does not make them useless — they are good *calibration exemplars* and I would keep using them as few-shot examples. But they cannot serve as a validation set, because no segmentation script will ever reproduce those exact units. Your held-out gold set (Decision 7) must be built from **verbatim, contiguous units produced by the actual segmenter.**

---

### Amendment 4 — Theme 1 and Theme 3 calibration *(fills the empty anchor cells)*

**Why this is needed.** Across all 18 benchmarks, **Theme 3 scores 0 every single time** and Theme 1 is non-zero only once. Nine of the 24 theme × score cells have no exemplar at all:

```
      s0  s1  s2  s3
T1    17   0   1   0     Surveillance         -- no 1, no 3
T2    16   0   1   1     Executive power      -- no 1
T3    18   0   0   0     Information control  -- nothing, at any level
T4     8   8   2   0     Civil rights         -- no 3
T5     0   7  11   0     Economic             -- no 0, no 3
T6     5   8   2   3     International        -- complete
```

**And here is the important part: this is a coding blind spot, not a property of the documents.** I searched the five PDFs and found clear Theme 1 and Theme 3 content that the gold standard scored as zero:

| Document | Passage | Should plausibly be |
|---|---|---|
| `SING2.pdf` | *"…policy measures including regulatory sandboxes, pilots for solutions such as **watermarking** and model cards…"* — this is benchmark 11, scored `theme_3: 0` | **T3 = 2.** The codebook's own Theme 3 anchor for score 2 reads *"State-funded research into deepfake watermarking tools."* This is a direct contradiction between an anchor and a benchmark. |
| `US1.pdf` | *"Update Federal procurement guidelines to ensure that the government only contracts with frontier large language model developers who ensure that their systems are objective and **free from top-down ideological bias**"*; and *"revise the NIST AI Risk Management Framework to **eliminate references to misinformation**, Diversity, Equity, and Inclusion, and climate change"* | **T3 = 2 or 3.** Procurement conditioned on model viewpoint is state curation of information systems — squarely Theme 3's scope ("state narrative curation"). |
| `US1.pdf` | "Combat Synthetic Media in the Legal System" section; deepfake standards; reference to enacted non-consensual deepfake legislation | **T3 = 2, possibly 3** given the enacted statute reference. |
| `IND1 (1).pdf` | *"smart command centres with sophisticated surveillance systems that could keep checks on **people's movement**, potential crime incidents"*; Surat's 600+ camera network being expanded | **T1 = 2.** Matches the Theme 1 score-2 anchor almost word for word ("Funded municipal surveillance pilots"). |
| `GER1.pdf` | *"AI can be used in law enforcement/emergency response… for coordinating the deployment of police forces"*; *"surveillance and monitoring of networks, interfaces and protocol data"* | **T1 = 1 or 2.** |
| `SING1.pdf` | *"Automated surveillance monitoring and detection of safety and security"* | **T1 = 1 or 2.** |

This matters for your argument, not just your reliability statistics. A paper about information control and surveillance in AI policy that reports **zero** information-control content in the US, Singapore, German, and Indian strategies is reporting an artifact of its instrument. The content is there.

**Draft amendment** — add to Themes 1 and 3 in §3:

```markdown
### Theme 3: Information Control & Content Curation (expanded anchors)

- **Additional Look-For Indicators:** state procurement conditioned on model
  viewpoint, output neutrality, or ideological character; government-mandated or
  government-funded provenance and watermarking schemes; official revision of
  state risk frameworks to add or remove categories of disfavoured content;
  state evaluation of foreign models for political alignment; platform
  transparency-reporting obligations.
- **Scoring Anchors (expanded):**
  - `1`: Voluntary guidelines, digital-literacy campaigns, or statements of
    concern about mis/disinformation with no mechanism attached.
  - `2`: State-funded watermarking, provenance, or synthetic-media detection
    pilots; consultative platform-government forums; procurement or funding
    guidance that references content characteristics without an enforcement
    consequence.
  - `3`: Binding obligations on platforms or model developers to remove, label,
    filter, or alter content — or to satisfy a viewpoint or neutrality condition —
    where non-compliance carries a penalty, disqualification, or loss of contract.
- **Boundary note:** Theme 3 covers state action shaping *what information reaches
  the public*. Cybersecurity measures protecting infrastructure integrity belong
  to Theme 5; monitoring of *individuals* belongs to Theme 1. Where a measure
  restricts content **and** monitors individuals, dual-code.

### Theme 1: State Surveillance & Domestic Control (added anchors)

  - `1`: AI named as a tool for public safety, policing, or national security with
    no program, budget, procurement, or named implementing body.
  - `3`: Binding mandates for data forwarding to state security bodies;
    warrantless algorithmic monitoring; statutorily authorised nationwide
    biometric identification; compulsory registration of individuals in a
    state-operated identification or monitoring system.
- **Clarification of the Theme 5 boundary:** the existing negative boundary
  excludes *infrastructure* monitoring. It does **not** exclude infrastructure
  that observes people. Municipal camera networks, "safe city" command centres,
  and crowd or movement analytics are Theme 1 even when presented as smart-city
  or urban-planning programs. The test is whether individuals or populations are
  the object of observation, regardless of the program's stated framing.
```

That last clarification is the one that would have caught the India smart-cities passage. As written, the "smart municipal grids → Theme 5" boundary at `codebook_detailed.md:26` reads as licence to route camera networks into Theme 5 because they are municipal.

---

### Amendment 5 — Version stamping *(required for reproducibility at any scale)*

```markdown
## 7. Versioning and Provenance

Every coded unit records, alongside its scores:

- `codebook_version` — semantic version of this file (e.g. `2.0.0`)
- `codebook_sha256` — hash of this file at scoring time
- `prompt_version` — version of the scoring prompt template
- `prompt_sha256` — hash of the rendered prompt template
- `model_id` — exact model string used
- `effort` — reasoning-effort setting
- `scored_at` — UTC timestamp
- `run_id` — identifier of the batch run

The codebook **will** change during the project. Without these fields you cannot
tell which version scored which unit, which makes partial re-runs impossible and
turns any mid-project revision into a full 36,000-unit re-run.
```

This one is cheap and non-negotiable. It is the difference between "we revised the Theme 3 anchors and re-scored the 4,000 affected units" and "we revised the codebook and had to start over."

---

### Amendment 6 — Confidence and review flags *(Decision 7)*

Currently all 18 benchmarks are `High` / `NO`, which teaches the model never to flag anything.

```markdown
## 8. Confidence and Human Review

### 8.1 Confidence
- **High** — operative language is explicit; one theme is clearly dominant; the
  binding status is stated in the text.
- **Moderate** — the mechanism is clear but its intensity sits on a boundary
  (e.g. two of the three Score-3 conditions are met), or two themes are close.
- **Low** — the unit is fragmentary, refers to an instrument it does not describe,
  or its meaning depends on context outside the unit.

### 8.2 Mandatory review flags — set `flag_human_review: "YES"` if ANY apply

| Trigger | `flag_reason` |
| :--- | :--- |
| Two or more themes tie for primary at ≥ 2 | `Polysemic Uncertainty` |
| Exactly two of the three Score-3 conditions met | `Conflicting Statutory Mandates` |
| Unit cites an external instrument without describing its content | `Missing Operational Context` |
| `word_count` < 100 or > 350 | `Missing Operational Context` |
| Confidence is `Low` | (as applicable) |
| Unit is translated or non-English source | `Missing Operational Context` |
| Theme 1 or Theme 3 scored ≥ 2 | `Polysemic Uncertainty` |

The last row is deliberate. Themes 1 and 3 are the project's substantive focus and
its least-calibrated dimensions; every positive finding on them should be
human-confirmed until the benchmark set covers those cells.
```

Expect a flag rate of 15–25% at first. On 515 pilot units that is 75–130 units to review — very manageable, and reviewing them is how you build the additional benchmarks Amendment 4 needs. On 36,000 units it is 5,000–9,000, which is why you tighten the thresholds after the pilot tells you what actually fires.

---

## Part 3: What has to be built

Nothing exists yet — the repository has no code. Here is what needs to, described in plain terms.

### 3.1 The single most important thing to understand

**`CLAUDE.md` is not your coder.**

`CLAUDE.md` is the instruction file that Claude Code (me, in this terminal) reads at the start of every session. It is useful for interactive work — spot-checking a passage, discussing a boundary case. It is **not** the prompt that will code 36,000 units.

The production coder must be a **separate, version-controlled, hashed prompt template** that a script sends to the Claude API. Two reasons:

1. If the instructions live only in `CLAUDE.md`, they change whenever someone edits that file, and you cannot reconstruct what instructions produced a given score.
2. Interactive sessions cannot process 36,000 units. That is a batch job.

The mental model: **this terminal is the workshop where we build and test the machine. The API is the machine that runs at scale.** Confusing the two is the most common way projects like this become irreproducible.

### 3.2 Proposed repository layout

```
aipolicies/
├── CLAUDE.md                          # instructions for interactive sessions
├── CODING_READINESS.md                # this document
├── codebook/
│   ├── codebook_detailed.md           # v2.0.0 after amendments
│   └── CHANGELOG.md                   # every codebook change, dated
├── prompts/
│   ├── coder_v1.md                    # THE production prompt template
│   └── output_schema.json             # JSON schema the model must satisfy
├── data/
│   ├── corpus_manifest.csv            # one row per document (see 3.3)
│   ├── raw_policies/                  # PDFs
│   ├── extracted/                     # plain text, one .txt per document
│   ├── units/                         # segmented units, one .jsonl per document
│   ├── coded/                         # model output, one .jsonl per document
│   └── benchmarks/
│       ├── gold_standard_18_benchmarks.json   # calibration exemplars (v2)
│       └── holdout_gold.json                  # verbatim validation set (new)
├── R/
│   ├── 01_extract.R                   # PDF -> text
│   ├── 02_segment.R                   # text -> units
│   ├── 03_code.R                      # units -> API -> scores
│   ├── 04_assemble.R                  # scores -> tidy analysis table
│   └── 05_reliability.R               # stability, agreement, alpha
├── output/
│   ├── coded_units.csv                # the analysis dataset
│   └── reliability_report.md
└── logs/
    └── runs/                          # one log per run, with all hashes
```

### 3.3 The corpus manifest

A CSV, one row per document, filled in **before** coding. This is where all document-level metadata lives so it is never retyped per unit:

`doc_id`, `filename`, `country_iso3`, `jurisdiction`, `year`, `issuing_authority`, `document_title`, `document_class` (A–D, Amendment 1), `source_language`, `is_translation`, `regime_type`, `regime_source`, `regime_year`, `source_url`, `retrieved_date`, `page_count`, `sha256`.

At 300 documents this file *is* your corpus. Building it is genuinely the largest piece of human work in the project and it cannot be automated away — sourcing documents, verifying they are the official version, and recording provenance is manual.

**Small but real problem right now:** `IND1 (1).pdf` contains a space and parentheses, which break shell scripts and R paths in ways that produce confusing errors. Rename to `IND1.pdf`. For 300 documents adopt a convention immediately — I suggest `{ISO3}_{YEAR}_{ISSUER}_{SHORTTITLE}.pdf`, e.g. `IND_2018_NITI_NAIS.pdf`.

### 3.4 Unit IDs

Your benchmarks mix two schemes: page-based (`USA_AIAP_2025_PIL02_P14_15`) and label-based (`SGP_NAIS_2019_PROJ05_BORDER`). Pick one that a script can generate deterministically:

```
{doc_id}_U{unit_number:04d}
IND_2018_NITI_NAIS_U0087
```

Human-readable section context goes in the separate `section_path` field, where it belongs. A unit ID's only job is to be unique and stable.

### 3.5 The scoring call — three technical choices that matter

**Use structured outputs.** The Claude API can be given a JSON schema and will guarantee the response matches it (`output_config.format`). Do not ask the model to "please return JSON" and parse the result — across 36,000 calls, a 0.5% malformed-output rate is 180 failures to hand-fix. With a schema it is zero.

**Use the Batch API.** For work that doesn't need an immediate answer, requests submitted in a batch run asynchronously at **50% of the standard price**. For 36,000 units this halves your bill for no loss. Results come back in arbitrary order, keyed by an ID you supply — so key by `unit_id`, never by position.

**Use prompt caching.** Every request repeats the same large prefix: codebook, schema, and few-shot examples (~7,500 tokens). Caching that prefix makes repeat reads cost about **10%** of normal input price, against a one-time write premium of 1.25×. For a run of thousands of units this is a large saving and it is a one-line change.

### 3.6 R or Python?

You have an `.Rproj` and R 4.6 with `jsonlite` installed — you are an R user, and the analysis will be in R.

**Recommendation: build the pipeline in R.** Anthropic does not publish an official R SDK, so the API calls go over plain HTTP using `httr2`, which is straightforward and well-documented. Packages needed: `httr2`, `jsonlite`, `pdftools`, `dplyr`/`readr`, `digest` (for the hashes in Amendment 5), `irr` or `icr` (for Krippendorff's α).

**One thing to know:** `python` on this machine is currently the Microsoft Store placeholder, not a real installation. If you would rather use Python (which has an official Anthropic SDK), you'll need to install it properly first. Either is fine; R keeps everything in one language and I'd default to it unless you prefer otherwise.

---

## Part 4: Benchmark set repairs

Two jobs here.

**Job 1 — fix what's there.** Re-score the 18 existing benchmarks under the amended codebook. Specifically: benchmark 11's `theme_3` should almost certainly be 2, not 0 (watermarking pilots); benchmarks 1, 2, 5, and 15 need `binding_status` added; benchmarks 6, 8, 13 need secondary themes recomputed. Bump the file to `v2` and keep `v1` in git history.

**Job 2 — fill the empty cells.** Priority order, driven by what's missing:

| Need | Where to find it |
|---|---|
| **T3 at 1, 2, 3** — highest priority, nothing exists | T3=2 candidates exist in `SING2` (watermarking) and `US1` (procurement neutrality, synthetic media). T3=3 needs a document with an actual takedown or labelling mandate — the EU AI Act, the UK Online Safety Act, or China's deep synthesis provisions. |
| **T1 at 1 and 3** | T1=1 and 2 candidates exist in `IND1` (smart cities), `GER1` (police deployment), `SING1` (automated surveillance monitoring). T1=3 needs a new document. |
| **T4 at 3** | EU AI Act or India's DPDP Act 2023 — both enacted, both with penalties. |
| **Non-US score-3, any theme** | Currently every 3 in the gold standard is American. This is the single biggest calibration weakness. |
| **T5 at 0** | Any unit that is purely about rights or surveillance with no economic content. Should be easy to find. |
| **T2 at 1** | "Streamlining government" rhetoric — common in most strategies. |

Target roughly 12 new benchmarks, 6–8 of which will need documents you don't have yet. Note that adding the EU AI Act or a Chinese regulation to the *benchmark* set does not require adding it to the *analysis* corpus — benchmarks are calibration material and can come from outside the sample.

---

## Part 5: Scaling to hundreds of documents

### 5.1 What it costs

Estimates assume ~7,500 cached prefix tokens, ~350 tokens of unit text, and ~800 output tokens per unit (including model reasoning), at current published rates.

**Per unit:**

| Model | Standard | Via Batch API (−50%) |
|---|---|---|
| Opus 5 | ~$0.026 | ~$0.013 |
| Sonnet 5 | ~$0.015 | ~$0.008 |
| Haiku 4.5 | ~$0.005 | ~$0.003 |

**Per corpus:**

| Corpus | Units | Opus 5 (batch) | Sonnet 5 (batch) | Haiku 4.5 (batch) |
|---|---|---|---|---|
| Current 5 documents | ~515 | **~$7** | ~$4 | ~$1 |
| 50 documents | ~6,000 | ~$78 | ~$46 | ~$16 |
| 300 documents | ~36,000 | **~$470** | ~$280 | ~$95 |

Add ~10% for the stability re-runs in Decision 7.

**The important takeaway: the pilot is essentially free.** Seven dollars to code all five documents with the best available model. There is no cost argument for cutting corners on the pilot — run it on Opus 5, look hard at the output, fix the codebook, and run it again. Do that three times and you have spent $21 and you have an instrument you can defend.

At 300 documents the model choice starts to matter, but even Opus 5 at ~$470 is small against the human coding time in Decision 7. **Do not optimise the model down before you have measured agreement.** Getting the codebook right saves far more than getting the model cheap.

These are estimates. Before committing to a large run I can call the token-counting endpoint on real units and replace them with measured numbers.

### 5.2 What changes at scale

| At 5 documents | At 300 documents |
|---|---|
| Read all output yourself | Read a sample; rely on the flag queue and reliability statistics |
| Codebook edits are cheap | Codebook edits mean re-running thousands of units — hence Amendment 5's version stamping |
| Metadata typed by hand | Metadata must come from a manifest joined to external sources |
| All English | Mostly not English — Decision 6c becomes load-bearing |
| Clean text layers | Some documents will be scanned and need OCR, some will be HTML-only |
| One run | Many partial runs; needs resumability so a failure at unit 20,000 doesn't restart from zero |
| Flag rate is a curiosity | Flag rate is a budget line |

Three things to build in from the start because retrofitting them is painful:

1. **Resumability.** Before coding a unit, check whether it already has output with the current codebook and prompt hash. If yes, skip. This makes every run resumable and makes partial re-runs after a codebook change automatic.
2. **Per-document outputs.** One `.jsonl` per document, not one giant file. Re-code one document without touching the rest.
3. **An append-only run log.** Every run writes its hashes, model, settings, unit count, cost, and failures to `logs/runs/`. This is your methods section.

### 5.3 One honest limitation to plan for

With four liberal or electoral jurisdictions, Themes 1 and 3 will show low variance no matter how well the instrument works. That is a real finding — but if the paper's contribution rests on variation in surveillance and information control, the sample needs cases that vary on it. Worth deciding now, because it changes the sampling frame in Decision 6a rather than something you discover at document 200.

---

## Part 6: How to work with me

Practical notes if you haven't used Claude Code much.

**What this terminal is good for.** Writing and debugging the R scripts. Testing prompts on individual units. Talking through boundary cases in the codebook. Building the manifest. Auditing output for problems. Anything where you want to look at something and decide.

**What it is not for.** Coding 36,000 units. That is what `03_code.R` and the Batch API are for. If you ever find yourself pasting policy text into this chat to be scored, something has gone wrong with the workflow — the scores would be unversioned and unreproducible.

**How to give me work.** Plain English is fine, and specific beats general. "Write `02_segment.R` implementing Amendment 3, and show me the units it produces for pages 8–12 of GER1 so I can check the boundaries" gets you something you can verify. "Build the pipeline" gets you something you have to audit from scratch.

**Permission prompts.** When I run a command or write a file, you may be asked to approve it. Approving is how work proceeds; I can't edit your files without it. If a prompt looks wrong, decline and say why — I'll adjust rather than retry the same thing.

**Running things yourself.** If you need to run something interactive — logging into a service, entering a key — type `!` followed by the command in this prompt and the output lands in our conversation.

**Two accounts, two bills.** Your Claude Code subscription and the Claude API are billed separately. The pipeline calls the API, which needs an **API key** from `console.anthropic.com` with billing set up. The Part 5 costs are API costs and are not covered by your Claude Code plan. Put the key in an environment variable (`ANTHROPIC_API_KEY`), never in a script, and make sure `.gitignore` covers `.Renviron`.

**Git.** Commit the codebook, prompts, scripts, manifest, and coded output. Right now nothing is committed except uploads — `.gitignore` covers only RStudio files. Before we start: decide whether the PDFs go in git (they're 40MB; usually better to keep them out and record hashes and URLs in the manifest instead).

**Keeping me consistent.** Once decisions are made, they go in `CLAUDE.md` so every future session starts from the same place. `CLAUDE.md` is also where the temperature rule currently lives, and it needs the Decision 5 fix.

---

## Part 7: What I need from you

Short version.

**Answer these seven** (yes / no / amend is enough — my recommendation is in brackets):

1. Draft-vs-enacted: split the variable, adding `binding_status`? [Option B]
2. Secondary-theme rule as drafted, computed in R from the breakdown? [yes]
3. Codeable-text rules as drafted, exec summaries coded but tagged? [yes]
4. Regime type from V-Dem Regimes of the World, at publication year, stored in the manifest? [yes]
5. Model: Opus 5 for the pilot; drop `temperature = 0.0` and report measured stability instead? [yes]
6. Corpus: what is the sampling frame, country or country-year, and what happens with non-English documents? [frame needed from you; English-official-else-original; `source_language` recorded]
7. Human validation: roughly how many hours of hand-coding can you commit? [need a number to set the flag threshold]

**Then three small things:**

- Rename `IND1 (1).pdf` → `IND1.pdf` (or let me).
- Confirm **R** for the pipeline (my recommendation) or Python.
- Get an Anthropic API key with billing at `console.anthropic.com`. Not needed until we run the pilot, but it has a lead time if it needs to go through the university.

**Then I can build, in this order:**

| Step | What | Rough effort |
|---|---|---|
| 1 | Amend the codebook to v2.0.0 with a changelog | 1 session |
| 2 | Repair the 18 benchmarks; draft ~12 new ones for the empty cells | 1–2 sessions |
| 3 | Build the manifest; write `01_extract.R` and `02_segment.R`; you check unit boundaries by eye | 1 session |
| 4 | Write the production prompt and JSON schema; test on the 18 benchmarks; measure agreement | 1–2 sessions |
| 5 | Pilot: code all 515 units (~$7); audit output; iterate on the codebook | 2–3 sessions |
| 6 | Reliability harness: stability re-run, human agreement, α | 1 session |
| 7 | Build the held-out gold set with you; validate | depends on your coding hours |
| 8 | Scale: batching, resumability, OCR fallback, language handling | 1–2 sessions |

Steps 1–2 do not need an API key and are the highest-value work. We can start on them as soon as you've answered Part 1.

---

*Everything in this document is a draft for your review. The empirical claims — page counts, word counts, benchmark cell counts, the internal contradictions, and the quoted passages — were verified against the files in this repository. The cost figures are estimates from published rates and should be re-measured against real units before any large run.*
