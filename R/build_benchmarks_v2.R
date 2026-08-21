# =============================================================================
# build_benchmarks_v2.R  --  gold standard v1 (18) -> v2 (30)
#
# Codebook v2.0.0 | DECISIONS.md §6
#
# Produces data/benchmarks/gold_standard_v2_30_benchmarks.json:
#   * the 18 v1 units, re-keyed to the six-theme vector and re-scored under v2
#     (statutory cap removed, Score-3 Evidence Test applied, binding_status
#     added, primary/secondary removed -- they are derived in 04_assemble.R)
#   * 12 new units filling the empty cells of the 6 themes x 4 tiers matrix
#
# The v1 text excerpts are carried over verbatim from the v1 file. The five new
# corpus benchmarks carry verbatim text pulled from data/units/ by unit_id, so
# they cannot drift from what the segmenter actually produces. The seven
# external benchmarks are marked source_type = "synthetic_exemplar": they are
# written in the register of the instruments they represent (EU AI Act, a
# deep-synthesis takedown regime, a comprehensive data protection statute, a
# localisation mandate, an export licence regime, an emergency powers decree)
# but they are NOT quotations, because this repository does not hold those
# documents and inventing quotations from them would be fabrication. They are
# calibration anchors only and must never be reported as corpus evidence.
#
# Re-run this script after any codebook change that alters benchmark scores.
# =============================================================================

suppressPackageStartupMessages({ library(jsonlite) })

ROOT <- getwd()
V1   <- file.path(ROOT, "data", "benchmarks", "gold_standard_18_benchmarks.json")
OUT  <- file.path(ROOT, "data", "benchmarks", "gold_standard_v2_30_benchmarks.json")

v1 <- fromJSON(V1, simplifyVector = FALSE)
units <- do.call(rbind, lapply(list.files(file.path(ROOT, "data", "units"), full.names = TRUE),
                               function(f) stream_in(file(f), verbose = FALSE)))

sv <- function(t1, t2, t3, t4, t5, t6) list(
  T1_surveillance = t1, T2_executive = t2, T3_infocontrol = t3,
  T4_civilrights  = t4, T5_economic  = t5, T6_geopolitical = t6)

ev <- function(scores, binding, conf, flag, reason, just,
               instrument = NULL, addressee = NULL, consequence = NULL) list(
  scores_full_breakdown = scores,
  binding_status = binding,
  score3_evidence = list(instrument = instrument, addressee = addressee, consequence = consequence),
  confidence_level = conf, flag_human_review = flag, flag_reason = reason,
  justification = just)

# -----------------------------------------------------------------------------
# A. The 18 v1 units, re-scored under codebook v2.0.0
# -----------------------------------------------------------------------------
rescored <- list(
  `1` = ev(sv(0,3,0,0,2,3), "directed", "High", "YES", "Polysemic Uncertainty",
    paste("Directs agencies to 'Establish new Categorical Exclusions under NEPA', an explicit override of an otherwise-applicable statutory environmental review (T2=3: instrument, addressee, consequence all present).",
          "Separately requires that AI infrastructure 'is free from foreign adversary information and communications technology and services', a mandatory supply-chain exclusion (T6=3).",
          "Domestic compute buildout is the funded baseline (T5=2). Flagged because T2 and T6 tie for primary at 3; under codebook v2 the two mechanisms are preserved independently rather than ranked."),
    instrument = "Establish new Categorical Exclusions under NEPA; foreign adversary ICTS exclusion",
    addressee = "Federal permitting agencies; suppliers to the domestic AI computing stack",
    consequence = "Suspension of NEPA review for covered actions; exclusion of adversary hardware and software"),

  `2` = ev(sv(0,0,0,0,1,3), "directed", "High", "NO", "None",
    paste("The operative directive is 'develop new export controls on semiconductor manufacturing sub-systems', led by DOC, 'coupled with enhanced enforcement' (T6=3: a licensing instrument, exporters as addressee, prohibition and enforcement as consequence).",
          "Research leadership in semiconductor manufacturing appears as framing with no funded programme in this unit (T5=1).",
          "Document genre does not cap the score: under codebook v2 §2.1 an executive action plan is eligible for 3, with legal force recorded as binding_status 'directed'."),
    instrument = "New export controls on semiconductor manufacturing sub-systems",
    addressee = "Exporters of semiconductor manufacturing sub-systems and their component suppliers",
    consequence = "Export prohibition plus enhanced enforcement"),

  `3` = ev(sv(0,0,0,1,2,1), "directed", "High", "NO", "None",
    paste("The operative mechanisms are funded: secure compute environments within NSF and DOE, a DARPA-led interpretability programme, and data-quality standards (T5=2).",
          "'Maintaining respect for individual rights and ensuring civil liberties, privacy, and confidentiality protections' is preamble framing with no enforcement body or cause of action (T4=1 -- rhetoric is 1, not 0, per §4.1 rule 2).",
          "Framing about national leadership carries no export or exclusion mechanism (T6=1).")),

  `4` = ev(sv(0,0,0,1,2,0), "directed", "High", "NO", "None",
    paste("NIST guidelines, DOE/NSF testbed investment, and the NIST AI Consortium are funded institutional programmes (T5=2).",
          "Evaluation 'for compliance with existing law' is voluntary guidance for agencies, not an enforceable audit obligation on developers (T4=1).",
          "No cross-border, content, or surveillance dimension in this unit.")),

  `5` = ev(sv(0,2,0,0,2,1), "directed", "High", "YES", "Conflicting Statutory Mandates",
    paste("Agreements with cloud providers 'to codify priority access to computing resources in the event of a national emergency' supply an instrument and an addressee, but the obligation arises by agreement rather than by penalty or override -- two of the three Score-3 conditions, so T2 is capped at 2 and flagged (§2.2).",
          "The AI & Autonomous Systems Virtual Proving Ground and Senior Military College hubs are funded institutional capacity (T5=2).",
          "CORRECTION TO v1: v1 scored T6=3 on 'maintain its global military preeminence'. That clause names no instrument, addressee, or consequence and is rhetoric under the Evidence Test, so T6 is 1. This removes one of the four unearned US score-3 observations identified in CODING_READINESS.md Part 4."),
    instrument = "DOD-led agreements codifying priority access to computing resources during a national emergency",
    addressee = "Cloud service providers and operators of computing infrastructure",
    consequence = NULL),

  `6` = ev(sv(0,0,0,0,2,1), "directed", "High", "NO", "None",
    paste("Piloting and deploying AI for truck routing, job pooling, and a common data exchange platform is funded sectoral deployment (T5=2).",
          "The objects of observation are freight vehicles and cargo flows, not persons: the Human Target Constraint (§3, Theme 1 boundary) routes this to T5 and leaves T1 at 0.",
          "Business competitiveness framing carries no cross-border mechanism (T6=1).")),

  `7` = ev(sv(2,0,0,0,1,0), "directed", "High", "YES", "Polysemic Uncertainty",
    paste("The operative mechanism is automated immigration clearance plus AI-assisted evaluation of 'the risk profile of travellers before they arrive', built on aggregated arrival-card and advance passenger data -- automated risk-scoring of individuals at a named national programme scale (T1=2).",
          "Traveller throughput and manpower framing is the supporting baseline (T5=1).",
          "Flagged under the mandatory trigger: every T1 score >= 2 is human-confirmed (§8.2).")),

  `8` = ev(sv(0,0,0,0,2,1), "directed", "High", "NO", "None",
    paste("Funded talent pipelines -- conversion programmes, corporate AI academies, AIAP, TeSA -- are institutional capacity building (T5=2).",
          "'Track the supply and demand of AI talent and manpower' is labour-market statistics about an aggregate, not monitoring of identified individuals, so T1 stays 0 (§3 Theme 1 scope).",
          "Attracting global talent is competitiveness framing (T6=1).")),

  `9` = ev(sv(0,0,0,1,2,1), "directed", "High", "NO", "None",
    paste("Consolidating data assets, the Trusted Data Sharing Framework, and public-private data pipelines are funded institutional infrastructure (T5=2).",
          "'Safeguard our citizens' data privacy' is stated as a governance aspiration with no independent enforcement body or penalty in this unit (T4=1).",
          "Note the near boundary: 'put in place the necessary data sharing frameworks and legislation' names legislation but does not describe its obligations, so it does not lift T4.")),

  `10` = ev(sv(0,0,1,1,1,0), "aspirational", "Moderate", "NO", "None",
    paste("Governance and security frameworks are promised but explicitly 'differentiated... ranging from regulatory moves to voluntary guidelines', with no instrument named (T4=1).",
          "CORRECTION TO v1: v1 scored T3=0. The unit states that model output must not be 'biased, inaccurate, or erroneous' and should be 'aligned with the appropriate set of human and cultural values' -- a statement of concern about the informational character of AI output with no mechanism attached, which is the T3=1 anchor under the v2 expanded anchors.",
          "Innovation framing supplies the economic baseline (T5=1). Confidence is Moderate because the unit describes a posture rather than a mechanism.")),

  `11` = ev(sv(0,2,2,1,2,1), "directed", "Moderate", "YES", "Polysemic Uncertainty",
    paste("CORRECTION TO v1: v1 scored T3=0 despite 'pilots for solutions such as watermarking and model cards', which is almost verbatim the T3=2 anchor ('State-funded watermarking, provenance, or synthetic-media detection pilots'). T3=2.",
          "'Regulatory sandboxes' suspend specified requirements for enrolled participants, which is the T2=2 anchor. AI Verify and the domestic TIC sector are funded institutional capacity (T5=2); the 11 ethics principles are a voluntary toolkit, not an enforceable audit (T4=1).",
          "Flagged on two triggers: T3 >= 2, and T2/T3/T5 tie for primary at 2.")),

  `12` = ev(sv(0,0,0,1,1,2), "directed", "High", "NO", "None",
    paste("Anchoring bilateral relationships, participating in multilateral fora, and building FOSS capacity initiatives are formalised international engagement programmes (T6=2), not export controls or exclusions, so the Evidence Test is not reached.",
          "AI Verify is referenced as an existing asset rather than funded here (T5=1); governance framing is rhetorical (T4=1).")),

  `13` = ev(sv(0,0,0,0,2,1), "enacted", "High", "NO", "None",
    paste("The NITI Aayog-IBM crop yield model is 'implemented in 10 Aspirational Districts', an operating programme, so T5=2 with binding_status 'enacted'.",
          "Soil, crop, and market telemetry observes land, produce, and prices -- things, not persons -- so T1 remains 0 under the Human Target Constraint.",
          "Global productivity comparisons are framing (T6=1).")),

  `14` = ev(sv(0,0,0,0,2,0), "enacted", "High", "NO", "None",
    paste("Adaptive learning tools, intelligent tutoring, dropout prediction and automated teacher rationalisation are funded sectoral deployment in education (T5=2), evidenced as operating by 'a recent preliminary experiment conducted in Andhra Pradesh'.",
          "The dropout model does score identified individuals -- 'AI applications processed data on all students based on parameters such as gender, socio-economic factors, academic performance' -- but its stated purpose is 'helping the government identify students likely to drop out' so that pre-emptive support can reach them.",
          "Under the Theme 1 purpose test (codebook v2.0.1 §3), individual-level prediction whose purpose is delivering a benefit to the person scored is Theme 5, not Theme 1. This unit is the reason that test was written down: without it, every personalised public service scores as surveillance.")),

  `15` = ev(sv(0,0,0,3,1,1), "proposed", "Moderate", "NO", "None",
    paste("The Srikrishna framework's seven enumerated principles include 'deterrent penalties and structured enforcement' and are addressed to data controllers -- instrument, addressee, and consequence are all identifiable, so T4=3 under the permissive reading of Evidence Test condition 1 (§2.2).",
          "The v1 cap at 2 rested on the document-class ceiling, which codebook v2 removes; the fact that the regime is not yet law is now carried by binding_status 'proposed' rather than by suppressing the score.",
          "Confidence is Moderate because the strict-versus-permissive reading of condition 1 is an open PI item (CHANGELOG Open items 2); under the strict reading this unit scores 2."),
    instrument = "Srikrishna Committee data protection framework: seven core principles",
    addressee = "Data controllers",
    consequence = "Deterrent penalties and structured enforcement"),

  `16` = ev(sv(0,0,0,1,2,1), "aspirational", "High", "NO", "None",
    paste("Goals of becoming a leading AI centre and building on Industrie 4.0 are backed by a stated intention to broaden the scientific base, which is programmatic but not itemised or funded in this unit (T5=2).",
          "'Strictly observing data security and people's right to control their personal data' and 'examine whether the regulatory framework needs to be further developed' are non-binding commitments to study (T4=1).",
          "'Globally recognised quality mark' is competitiveness rhetoric (T6=1).")),

  `17` = ev(sv(0,0,0,1,2,2), "directed", "High", "YES", "Polysemic Uncertainty",
    paste("Forming 'a European innovation cluster providing funding for cooperative research projects over the next five years' as part of a EUREKA cluster is a formalised cross-border R&D funding programme (T6=2).",
          "The same commitment funds domestic research capacity and shared high-performance computing (T5=2). 'Shared values and a joint regulatory framework' is rhetorical (T4=1).",
          "Flagged because T5 and T6 tie for primary at 2.")),

  `18` = ev(sv(0,0,0,2,1,0), "proposed", "Moderate", "YES", "Missing Operational Context",
    paste("Safeguarding the right to co-determination where AI is introduced engages an existing statutory works-council regime, and a 'dedicated Workforce Data Protection Act' is named as a specific instrument under consideration (T4=2: a published framework under study, short of the enumerated obligations the Evidence Test requires for 3).",
          "Introduction of AI applications in companies is the incidental economic context (T5=1).",
          "Flagged on the mandatory word-count trigger: the unit is 50 words, far below the 100-word floor, and 'look into the question of whether' leaves the obligation undescribed."))
)

# -----------------------------------------------------------------------------
# B. Twelve new benchmarks
# -----------------------------------------------------------------------------
corpus_new <- list(
  list(unit_id = "USA_AIAP_2025_PILLARIA_ENSURE_P03_04",
       jurisdiction = "United States", doc_id = "USA_AIAP_2025", year = 2025,
       fills = "T3=3 (first exemplar at any level), T2=3, T5=0",
       e = ev(sv(0,3,3,1,0,1), "directed", "High", "YES", "Polysemic Uncertainty",
         paste("'Update Federal procurement guidelines to ensure that the government only contracts with frontier large language model (LLM) developers who ensure that their systems are objective and free from top-down ideological bias' satisfies all three Score-3 conditions for Theme 3: a procurement instrument, frontier model developers as addressee, and loss of federal contracts as consequence. Conditioning state purchasing on the viewpoint character of a model is state curation of the information environment (§3 Theme 3 expanded indicators).",
               "'Revise the NIST AI Risk Management Framework to eliminate references to misinformation, Diversity, Equity, and Inclusion, and climate' is official revision of a state risk framework's content categories, reinforcing T3.",
               "Directing FCC to evaluate whether state AI regulations 'interfere' and directing review to 'modify or set-aside' FTC final orders that 'unduly burden AI innovation' is an override of otherwise-applicable regulatory decisions (T2=3).",
               "No funding, compute, or workforce mechanism appears, so T5=0. Evaluating PRC models 'for alignment with Chinese Communist Party talking points' is framing without an export or exclusion instrument (T6=1)."),
         instrument = "Updated Federal procurement guidelines; revision of the NIST AI Risk Management Framework; set-aside of FTC final orders",
         addressee = "Frontier large language model developers contracting with the Federal government; FTC; FCC",
         consequence = "Disqualification from Federal contracts; set-aside of existing final orders, consent decrees and injunctions")),

  list(unit_id = "USA_AIAP_2025_PILLARIA_COMBAT_P12_13",
       jurisdiction = "United States", doc_id = "USA_AIAP_2025", year = 2025,
       fills = "T3=2",
       e = ev(sv(0,0,2,1,0,0), "directed", "High", "YES", "Polysemic Uncertainty",
         paste("Developing NIST's 'Guardians of Forensic Evidence deepfake evaluation program into a formal guideline and a companion voluntary' standard, and DOJ guidance to 'explore adopting a deepfake standard', are state-funded synthetic-media detection and provenance work with no enforcement consequence attached -- the T3=2 anchor exactly.",
               "The enacted TAKE IT DOWN Act is cited but its obligations are not described in the unit, so it cannot lift the score; it is why binding_status is 'directed' rather than 'proposed' for the actions that are directed here.",
               "Giving courts and law enforcement evidentiary tools engages judicial process safeguards rhetorically (T4=1). Flagged on the mandatory T3 >= 2 trigger."))),

  list(unit_id = "IND_NAIS_2018_SMARTCIT_P40_40_2",
       jurisdiction = "India", doc_id = "IND_NAIS_2018", year = 2018,
       fills = "T1=2 from corpus (the cell CODING_READINESS.md identified as a coding blind spot)",
       e = ev(sv(2,0,1,0,1,0), "enacted", "High", "YES", "Polysemic Uncertainty",
         paste("'Smart command centres with sophisticated surveillance systems that could keep checks on people's movement, potential crime incidents' places individuals and populations under observation, and 'in the city of Surat, the crime rate has declined by 27% after the implementation of AI powered safety systems' establishes that the programme is operating, not proposed (T1=2, binding_status 'enacted').",
               "This is the passage the Theme 1 boundary clarification exists to catch: the programme is framed as smart-city infrastructure, but the object of observation is people, so it is Theme 1 and not Theme 5.",
               "'Social media intelligence platforms... gathering information from social media and predicting potential activities that could disrupt public peace' is state monitoring of the public information space without a removal or labelling obligation (T3=1).",
               "Cyber-attack detection protects infrastructure integrity and is Theme 5 baseline, not Theme 3 (T5=1)."))),

  list(unit_id = "IND_NAIS_2018_SMARTCIT_P39_39_2",
       jurisdiction = "India", doc_id = "IND_NAIS_2018", year = 2018,
       fills = "T1=2 / T5=2 dual-code, demonstrating the Human Target Constraint splitting one passage",
       e = ev(sv(2,0,0,0,2,0), "enacted", "Moderate", "YES", "Polysemic Uncertainty",
         paste("The unit contains both kinds of monitoring and is dual-coded accordingly. Smart electricity and water meters, leakage detection, and waste management observe utilities and physical distribution networks -- things (T5=2, and 'smart cities being developed are trying to solve' marks operating programmes).",
               "'Surat has built a network of more than 600 surveillance cameras which will be expanded to all major locations in the city' and 'surveillance analytics' observe people, so the same unit scores T1=2 independently.",
               "Under codebook v1 the 'smart municipal grids belong to Theme 5' boundary would have routed the camera network to Theme 5 and scored T1=0; §3's boundary clarification reverses that. Flagged on the mandatory T1 >= 2 trigger."))),

  list(unit_id = "DEU_AISTRAT_2018_3FIELDSO_37USIN_P31_31_3",
       jurisdiction = "Germany", doc_id = "DEU_AISTRAT_2018", year = 2018,
       fills = "T1=1, T3=1",
       e = ev(sv(1,0,1,1,0,1), "aspirational", "High", "NO", "None",
         paste("AI is named for 'the recognition of persons through big data analysis', 'coordinating the deployment of police forces', 'predictive policing', and 'social media forensics for profiling', but the Federal Government only 'seeks to identify suitable areas' -- no programme, budget, procurement, or named implementing body, which is precisely the T1=1 anchor.",
               "'Combatting and prosecuting the dissemination of footage depicting abuse' engages the public information space without a platform obligation or penalty (T3=1).",
               "'In accordance with the Basic Law', 'safeguarding personal rights', and retention of human decision-making by authority staff are stated safeguards without an enforcement mechanism in this unit (T4=1). Digital sovereignty framing is rhetorical (T6=1)."))),

  list(unit_id = "DEU_AISTRAT_2018_3FIELDSO_WEWILL_P19_19_2",
       jurisdiction = "Germany", doc_id = "DEU_AISTRAT_2018", year = 2018,
       fills = "T2=1 (no exemplar existed at this level)",
       e = ev(sv(0,1,0,1,2,0), "directed", "High", "NO", "None",
         paste("'We will streamline the framework for research funding as much as possible' and 'fully use the margin of discretion available under funding and state-aid rules to render research funding schemes more efficient' is administrative streamlining rhetoric: no exemption is created, no statutory review is suspended, no addressee is placed under obligation. That is the T2=1 anchor, and it is the level v1 had no exemplar for.",
               "Reviewing and tailoring funding mechanisms and developing novel funding schemes for start-ups and SMEs is funded institutional capacity (T5=2).",
               "Involving licensing authorities early to protect consumers' interests is a process commitment without enforceable rights (T4=1)."))
))

external_new <- list(
  list(bid = 25, label = "EXT_T1_3_BIOMETRIC_MANDATE", fills = "T1=3",
       jurisdiction = "Synthetic exemplar (register of an enacted national digital identity and lawful-intercept decree)",
       text = paste("The competent authority shall establish and operate a unified national biometric identification register.",
         "All residents above the age of five shall be enrolled, providing facial images, all ten fingerprints, and iris scans;",
         "enrolment shall be a precondition for the issue or renewal of identity documents and for access to subsidised public services.",
         "Providers of public telecommunications networks and services shall, within one hundred and eighty days of the entry into force of this instrument,",
         "install and maintain interfaces enabling the competent security authorities to obtain subscriber, traffic and content data in real time,",
         "and shall retain such data for a period of twenty-four months. Automated facial recognition matching against the register shall be deployed",
         "at all designated public transport hubs and border crossings. Failure by a provider to install or maintain the required interface,",
         "or to comply with a data production order within the prescribed period, shall attract an administrative fine of up to two per cent of annual turnover",
         "and may result in suspension of the operating licence."),
       e = ev(sv(3,1,0,0,0,0), "enacted", "High", "YES", "Polysemic Uncertainty",
         paste("All three Score-3 conditions are present for Theme 1: an operative instrument (a unified national biometric register plus a lawful-intercept mandate), specified addressees (residents; providers of public telecommunications networks), and a consequence (administrative fines up to two per cent of turnover and licence suspension; denial of identity documents and subsidised services for non-enrolment).",
               "Compulsory registration of individuals in a state-operated identification system and mandatory data forwarding to security authorities are both named in the T1=3 anchor.",
               "SYNTHETIC EXEMPLAR: written in the register of such instruments to anchor the top of Theme 1, which no document in the pilot corpus reaches. Not a quotation and not corpus evidence."))),

  list(bid = 26, label = "EXT_T3_3_TAKEDOWN_MANDATE", fills = "T3=3 (external, non-US)",
       jurisdiction = "Synthetic exemplar (register of an enacted deep-synthesis / online safety provision)",
       text = paste("Providers of information services that generate or disseminate synthetic audio, image, video or text content shall apply",
         "a conspicuous label and an embedded, machine-readable provenance marker to all such content.",
         "Providers shall establish a reporting channel and, on receipt of a notice from the regulator or a substantiated user complaint,",
         "shall remove or restrict access to non-compliant content within twenty-four hours.",
         "Providers shall verify the real identity of users of generative services, retain logs for six months, and submit quarterly transparency reports to the regulator.",
         "The regulator may order rectification within a specified period; failure to comply attracts a fine of up to five per cent of domestic turnover,",
         "suspension of new user registration, or removal of the service from application distribution platforms."),
       e = ev(sv(2,0,3,0,0,0), "enacted", "High", "YES", "Polysemic Uncertainty",
         paste("Theme 3 reaches 3 on all three conditions: the instrument is a labelling, provenance and takedown obligation; the addressees are providers of information services; the consequence is fines up to five per cent of turnover, suspension of registration, and removal from distribution platforms.",
               "Mandatory real-identity verification of users and six-month log retention places identified individuals under state-mandated observation, so Theme 1 is dual-coded at 2 (an operating obligation short of a state-run identification or monitoring system).",
               "SYNTHETIC EXEMPLAR. Not a quotation and not corpus evidence."))),

  list(bid = 27, label = "EXT_T4_3_DATA_PROTECTION_ACT", fills = "T4=3 enacted (v1 had no T4=3 at all)",
       jurisdiction = "Synthetic exemplar (register of an enacted comprehensive data protection statute)",
       text = paste("A data fiduciary shall process personal data only for a lawful purpose for which the data principal has given consent,",
         "and shall implement appropriate technical and organisational measures to give effect to the obligations under this Act.",
         "A data principal shall have the right to obtain confirmation of processing, a summary of the personal data processed,",
         "the correction and erasure of personal data, and the nomination of a representative; and shall have the right to an effective remedy before the Board.",
         "Where a data fiduciary deploys an automated decision-making system that produces legal effects concerning a data principal,",
         "it shall conduct and retain a data protection impact assessment and shall provide, on request, meaningful information about the logic involved.",
         "The Board may, after an inquiry, impose a monetary penalty not exceeding two hundred and fifty crore rupees for failure to observe these obligations,",
         "and orders of the Board shall be enforceable as a decree of a civil court."),
       e = ev(sv(0,0,0,3,0,0), "enacted", "High", "NO", "None",
         paste("Theme 4 reaches 3: the instrument is an enacted statute imposing processing, impact-assessment and explanation obligations; the addressees are data fiduciaries; the consequence is a monetary penalty enforceable as a decree of a civil court, alongside an effective remedy for the data principal.",
               "This is the anchor that distinguishes an enforceable rights regime from the voluntary toolkits and ethics councils that score 2, and from 'responsible AI' pledges that score 1.",
               "SYNTHETIC EXEMPLAR. Not a quotation and not corpus evidence."))),

  list(bid = 28, label = "EXT_T5_3_LOCALISATION_QUOTA", fills = "T5=3 (v1 had no T5=3)",
       jurisdiction = "Synthetic exemplar (register of a statutory industrial localisation mandate)",
       text = paste("Operators of public cloud and artificial intelligence computing facilities serving critical sectors shall ensure that",
         "not less than sixty per cent of installed accelerator capacity is procured from domestically manufactured sources by the end of the third year",
         "following commencement, rising to eighty per cent by the end of the fifth year.",
         "Designated undertakings shall submit annual production and procurement returns to the Ministry, which shall publish compliance tables.",
         "The sovereign investment fund shall allocate capital to designated undertakings against binding annual output targets set by the Ministry;",
         "an undertaking that fails to meet its output target in two consecutive years shall repay disbursed capital with interest and shall be removed from the designated list,",
         "and a facility operator that fails to meet the localisation threshold shall be ineligible for public procurement and for connection to the national compute grid."),
       e = ev(sv(0,0,0,0,3,2), "enacted", "High", "NO", "None",
         paste("Theme 5 reaches 3: the instrument is a statutory localisation threshold coupled with sovereign capital tied to binding output targets; the addressees are facility operators and designated undertakings; the consequence is repayment with interest, delisting, and ineligibility for public procurement and grid connection. This is state-directed industrial policy enforced by penalty, not a grant programme.",
               "Requiring domestically manufactured accelerators excludes foreign supply from critical-sector infrastructure, which is a supply-chain mechanism but is framed as a capacity threshold rather than an adversary exclusion or export prohibition (T6=2).",
               "SYNTHETIC EXEMPLAR. Not a quotation and not corpus evidence."))),

  list(bid = 29, label = "EXT_T6_3_EXPORT_LICENCE_NONUS", fills = "T6=3 from a non-US jurisdiction (every v1 score-3 was American)",
       jurisdiction = "Synthetic exemplar (register of a non-US dual-use export control and investment screening instrument)",
       text = paste("The items listed in Annex I, including advanced computing integrated circuits above the specified performance density,",
         "lithography and metrology equipment, and the associated technology and software, shall not be exported, transferred, brokered or made available",
         "to any person in a destination listed in Annex II without a licence issued by the competent national authority.",
         "Licences shall be refused where there is a risk that the items would contribute to military modernisation or to internal repression.",
         "Operators of critical infrastructure shall not procure or continue to operate network equipment supplied by an undertaking designated as high-risk under Article 12,",
         "and shall complete removal of such equipment within thirty-six months.",
         "Acquisitions by foreign undertakings of holdings exceeding ten per cent in domestic entities active in the Annex I technologies shall be notified and may be prohibited.",
         "Contravention shall be punishable by fine or imprisonment and by forfeiture of the items concerned."),
       e = ev(sv(0,0,0,0,0,3), "enacted", "High", "NO", "None",
         paste("Theme 6 reaches 3 on all three conditions: an export licence regime plus a mandatory rip-and-replace obligation and investment screening; addressees are exporters, critical infrastructure operators, and foreign acquirers; consequences are licence refusal, criminal penalty, forfeiture, and prohibition of transactions.",
               "This benchmark exists to break the v1 pattern in which every score-3 observation came from a single jurisdiction, which CODING_READINESS.md identified as the gold standard's single biggest calibration weakness.",
               "SYNTHETIC EXEMPLAR. Not a quotation and not corpus evidence."))),

  list(bid = 30, label = "EXT_T2_3_EMERGENCY_POWERS_NONUS", fills = "T2=3 from a non-US jurisdiction",
       jurisdiction = "Synthetic exemplar (register of an emergency powers / accelerated authorisation decree)",
       text = paste("For the period of validity of this Decree, projects designated as of overriding national interest for artificial intelligence computing capacity",
         "shall be authorised under the accelerated procedure. In respect of such projects the requirement to carry out a strategic environmental assessment is suspended,",
         "the public consultation period is reduced to fifteen days, and the competent authority shall decide within sixty days;",
         "on the expiry of that period the authorisation shall be deemed granted.",
         "Appeals against an authorisation granted under this Decree shall not have suspensive effect.",
         "The Minister may requisition electricity network capacity and, where necessary, direct grid operators to give priority of connection to designated projects,",
         "notwithstanding the ordinary queue. Non-compliance by an operator with a direction issued under this Article shall attract a daily penalty payment."),
       e = ev(sv(0,3,0,0,2,0), "enacted", "High", "YES", "Polysemic Uncertainty",
         paste("Theme 2 reaches 3: the instrument is a decree creating an accelerated authorisation procedure; the addressees are competent authorities, grid operators, and objectors; the consequences are the explicit suspension of strategic environmental assessment, deemed authorisation on expiry, removal of suspensive effect from appeals, and daily penalty payments for non-compliance with a direction. This is an override of otherwise-applicable legal requirements, which is the definition of the T2=3 anchor.",
               "Requisitioning network capacity and directing priority grid connection builds compute infrastructure through coercion (T5=2).",
               "SYNTHETIC EXEMPLAR. Not a quotation and not corpus evidence."))))

# -----------------------------------------------------------------------------
out <- list()

for (x in v1) {
  bid <- as.character(x$benchmark_id)
  md <- x$document_metadata
  md$regime_type <- "PENDING (see codebook/CHANGELOG.md Open items 4)"
  out[[length(out) + 1]] <- list(
    benchmark_id = x$benchmark_id,
    codebook_version = "2.0.1",
    source_type = "verbatim_v1_excerpt",
    fills_cell = "carried over from v1",
    unit_id = x$unit_id,
    document_metadata = md,
    text_excerpt = x$text_excerpt,
    evaluation_output = rescored[[bid]]
  )
}

bid <- 18L
for (n in corpus_new) {
  bid <- bid + 1L
  r <- units[units$unit_id == n$unit_id, ]
  if (!nrow(r)) stop("benchmark unit not found in data/units: ", n$unit_id)
  out[[length(out) + 1]] <- list(
    benchmark_id = bid,
    codebook_version = "2.0.1",
    source_type = "verbatim_corpus_unit",
    fills_cell = n$fills,
    unit_id = n$unit_id,
    document_metadata = list(
      jurisdiction = n$jurisdiction, doc_id = n$doc_id, year = n$year,
      regime_type = "PENDING (see codebook/CHANGELOG.md Open items 4)",
      structural_location = r$section_path[1],
      page_start = r$page_start[1], page_end = r$page_end[1],
      word_count = r$word_count[1]),
    text_excerpt = r$text[1],
    evaluation_output = n$e
  )
}

for (n in external_new) {
  out[[length(out) + 1]] <- list(
    benchmark_id = n$bid,
    codebook_version = "2.0.1",
    source_type = "synthetic_exemplar",
    fills_cell = n$fills,
    unit_id = n$label,
    document_metadata = list(
      jurisdiction = n$jurisdiction, doc_id = "EXTERNAL", year = NA,
      regime_type = "n/a",
      structural_location = "Calibration anchor -- not drawn from the analysis corpus",
      warning = "Synthetic exemplar written in the register of the instrument class it represents. NOT a quotation from any real document. Use for few-shot calibration only; never cite as corpus evidence."),
    text_excerpt = n$text,
    evaluation_output = n$e
  )
}

write(toJSON(out, auto_unbox = TRUE, pretty = TRUE, null = "null", na = "null"), OUT)
message("wrote ", OUT, " with ", length(out), " benchmarks")

# ---- coverage matrix -------------------------------------------------------
themes <- c("T1_surveillance","T2_executive","T3_infocontrol","T4_civilrights","T5_economic","T6_geopolitical")
m <- matrix(0L, 6, 4, dimnames = list(themes, paste0("s", 0:3)))
for (o in out) for (k in themes) {
  s <- o$evaluation_output$scores_full_breakdown[[k]]
  m[k, s + 1L] <- m[k, s + 1L] + 1L
}
message("\nBenchmark coverage, 6 themes x 4 tiers:")
print(m)
empty <- which(m == 0L, arr.ind = TRUE)
if (nrow(empty)) {
  message("\nEMPTY CELLS REMAIN:")
  print(data.frame(theme = rownames(m)[empty[, 1]], score = empty[, 2] - 1L))
} else {
  message("\nAll 24 cells populated.")
}
