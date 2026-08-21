# Reliability Report

Codebook 2.0.0 | generated 2026-08-21 18:43 UTC

Units in the main run: **389**  
Scoring routes present: interactive_session  
Models present: claude-opus-5 (Claude Code session; not an API call)


> **Warning.** Some or all units carry `scoring_route: "interactive_session"`. Those scores were produced inside a Claude Code session, not by a versioned API call, so they are not reproducible and the stability statistic below cannot be computed for them. They are a first-pass audit artefact and must be superseded by an `api_batch` run before anything is reported.


## 1. Run-to-run stability

Not yet measured. Produce a second independent run over a random >=10% sample:

```
# copy data/coded aside, then re-score the sample into data/coded_rerun/
Rscript R/03_evaluate.R --limit 40
Rscript R/05_reliability.R --stability-run data/coded_rerun
```

**This statistic replaces the `temperature = 0.0` determinism claim (codebook §1.1) and the paper cannot make a reproducibility claim without it.**


## 2. Agreement with the gold standard (30 benchmarks)

Benchmark units scored: **6**  
Whole-vector exact agreement: **100%**


| comparison | n | exact | within1 | kappa_quad | alpha_ord |
|---|---|---|---|---|---|
| T1_surveillance | 6 | 1 | 1 | 1 | 1 |
| T2_executive | 6 | 1 | 1 | 1 | 1 |
| T3_infocontrol | 6 | 1 | 1 | 1 | 1 |
| T4_civilrights | 6 | 1 | 1 | 1 | 1 |
| T5_economic | 6 | 1 | 1 | 1 | 1 |
| T6_geopolitical | 6 | 1 | 1 | 1 | 1 |


## 3. Agreement with human coding

**Not yet available.** Create `data/benchmarks/human_coded_sample.csv` with columns

`unit_id, T1_surveillance, T2_executive, T3_infocontrol, T4_civilrights, T5_economic, T6_geopolitical, coder_id`

coded blind on a random sample of units drawn from `output/coded_units.csv`, *before* seeing model output. 100-150 units is the usual minimum. Until this exists the pipeline is unvalidated and its output is not publishable (CODING_READINESS.md Decision 7).


## 4. Diagnostics

Flag rate: **21.6%**  

Confidence distribution: High 335 | Moderate 54


Score distribution across the corpus:

| theme | s0 | s1 | s2 | s3 |
|---|---|---|---|---|
| T1_surveillance | 358 |  17 |  14 | 0 |
| T2_executive | 343 |  25 |  17 | 4 |
| T3_infocontrol | 362 |  22 |   4 | 1 |
| T4_civilrights | 249 | 103 |  33 | 4 |
| T5_economic |  18 | 137 | 234 | 0 |
| T6_geopolitical | 205 | 147 |  33 | 4 |

