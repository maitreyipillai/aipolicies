# Comprehensive AI Policy Content Analysis Codebook

## 1. Unit of Analysis & Evaluation Protocol
- **Unit of Analysis:** Discrete policy paragraph or self-contained sub-clause (150–300 words).
- **Core Task:** Classify each text unit across 6 thematic dimensions and assign an ordinal intensity score (0 to 3) along with qualitative justification.
- **Deterministic Standard:** Temperature is fixed at 0.0 with greedy decoding.

---

## 2. Universal Scoring Anchor Definitions (0–3 Scale)

| Score | Level | Definition & Operational Thresholds |
| :--- | :--- | :--- |
| **0** | **Absent** | The thematic concept is completely unmentioned, irrelevant, or explicitly disclaimed. |
| **1** | **Aspirational / Rhetorical** | High-level normative framing, non-binding guiding principles, abstract vision statements, or study group mandates lacking dedicated budget, statutory enforcement, or administrative apparatus. |
| **2** | **Substantive / Funded / Institutional** | Specific, operational state programs: committed financial investments/grants, active regulatory sandboxes, pilot implementations, standing inter-agency task forces, or published draft legislative frameworks. |
| **3** | **Hard Mandate / State Coercion / Emergency Action** | Legally binding statutory commands, punitive sanction/fine regimes, executive emergency bypasses (suspension of statutory reviews), mandatory compliance audits, or coercive state security deployments. |

---

## 3. Thematic Dimensions & Coding Criteria

### Theme 1: State Surveillance & Domestic Control
- **Scope:** State monitoring, biometric profiling, mass surveillance grids, intelligence data-sharing, and predictive policing.
- **Look-For Indicators:** Facial recognition grids, automated border screening, CCTV sensor fusion, law enforcement analytics, predictive crime detection.
- **Negative Boundary:** Automated monitoring of physical infrastructure (e.g., smart power grids, freight tracking, agricultural soil sensors) belongs under **Theme 5**, NOT Theme 1.
- **Scoring Anchors:**
  - `0`: No state surveillance mechanisms mentioned.
  - `1`: Aspirational statements on using AI to support public safety or national security without concrete technical/institutional deployment.
  - `2`: Funded municipal surveillance pilots, integrated police database trials, automated port/border biometric screening programs.
  - `3`: Binding legal mandates requiring ISP/telecom data forwarding to state security, warrantless algorithmic monitoring, or nationwide biometric surveillance grids.

### Theme 2: Executive Power & Emergency Bypass
- **Scope:** Centralization of presidential/prime ministerial authority, fast-track permitting, emergency deregulation, and suspension of normal statutory oversight.
- **Look-For Indicators:** Fast-track permitting (e.g., FAST-41), NEPA categorical exclusions, national security procurement waivers, unilateral executive task forces overriding legislative procedures.
- **Scoring Anchors:**
  - `0`: No executive bypass or regulatory fast-tracking.
  - `1`: High-level statements calling for "speeding up bureaucracy" or "streamlining government."
  - `2`: Inter-agency advisory bodies established by executive order to propose regulatory exemptions.
  - `3`: Enacted executive directives overriding statutory environmental, labor, or procurement reviews; invocation of national defense production acts for AI compute.

### Theme 3: Information Control & Content Curation
- **Scope:** Algorithmic content moderation, online speech filtering, automated censorship, synthetic media watermarking, and state narrative curation.
- **Look-For Indicators:** Deepfake detection/removal mandates, automated platform liability, real-time social media filtering, mandatory content verification pipelines.
- **Scoring Anchors:**
  - `0`: No speech, media, or content filtering mentioned.
  - `1`: Voluntary guidelines or educational campaigns on synthetic media and digital literacy.
  - `2`: State-funded research into deepfake watermarking tools or voluntary platform-government consultative forums.
  - `3`: Statutory mandates compelling online platforms to remove algorithmic content within defined timelines under threat of administrative/criminal penalties.

### Theme 4: Civil Rights, Privacy & Judicial Guardrails
- **Scope:** Statutory data protection, algorithmic transparency/explainability, anti-bias audits, independent oversight, worker co-determination, and judicial review rights.
- **Look-For Indicators:** Statutory privacy rights (GDPR-style), algorithmic impact assessments, mandatory red-teaming, right to explanation, workforce co-determination laws, independent audit bodies.
- **Negative Boundary:** High-level corporate marketing slogans (e.g., "we support ethical AI") without independent enforcement or legal liability score only `1`.
- **Scoring Anchors:**
  - `0`: No civil rights, privacy, or judicial guardrails discussed.
  - `1`: Non-binding ethical principles, voluntary "responsible AI" pledges, high-level awareness campaigns.
  - `2`: Institutional testing toolkits (e.g., AI Verify), regulatory sandbox compliance programs, draft privacy commission recommendations, dedicated workforce data protection studies.
  - `3`: Enacted statutory data privacy laws with binding financial penalties, legally enforceable private rights of action, mandatory pre-deployment algorithmic discrimination bans.

### Theme 5: Economic & Industrial Strategy
- **Scope:** Domestic baseline capacity building: research grants, SME adoption, STEM education/workforce training, digital infrastructure (data centers, compute clusters), and industrial automation (Industrie 4.0).
- **Look-For Indicators:** National compute clusters, university R&D funding, teacher/workforce upskilling, smart agriculture, public-private research partnerships, broadband/gigabit expansion.
- **Scoring Anchors:**
  - `0`: No economic or domestic capacity mechanisms.
  - `1`: Broad economic vision statements (e.g., "AI will transform our economy by 2030").
  - `2`: Committed state R&D grants, sector-specific deployment programs (agriculture, healthcare, education), SME digital adoption centers, funded supercomputing access programs.
  - `3`: Statutory state-directed industrial mandates, sovereign wealth capital allocations directly tied to mandatory production quotas.

### Theme 6: International Competitiveness & Geopolitical Control
- **Scope:** Cross-border strategic competition, export controls, sovereign supply chain security, foreign adversary exclusions, and multilateral alliance building.
- **Look-For Indicators:** Semiconductor export restrictions, foreign adversary ICTS prohibitions, bilateral/multilateral R&D clusters (e.g., EUREKA, Franco-German pacts), international standard-setting leadership.
- **Scoring Anchors:**
  - `0`: No international or cross-border dimension.
  - `1`: General rhetoric about "maintaining national leadership" or "collaborating with global partners."
  - `2`: Formalized cross-border R&D funding clusters, bilateral data-sharing frameworks, participation in international standard-setting bodies.
  - `3`: Legally binding technology export bans, mandatory supply chain exclusions barring foreign adversary hardware/software from critical infrastructure.

---

## 4. Priority Hierarchy & Disambiguation Rules

1. **Operative Action Over Preamble Rhetoric:** When a paragraph contains aspirational framing (Theme 4) alongside concrete infrastructure spending (Theme 5), code the concrete mechanism as the Primary Theme.
2. **Dual-Coding Rule:** If a unit contains two distinct substantive mechanisms (both scoring $\ge 2$), assign the dominant mechanism to `primary_theme` and the supporting mechanism to `secondary_theme`.
3. **Surveillance Target Constraint:** Theme 1 applies exclusively to surveillance of *human individuals or populations*. Tracking physical freight, crops, or municipal grids is coded under Theme 5.
4. **Draft vs. Enacted Distinction:** Policy recommendations, draft white papers, and multi-year vision documents are capped at Score `2`. Reserve Score `3` strictly for enacted statutory mandates, binding executive orders, or active coercive enforcement.
