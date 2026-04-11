# IJIM Revision Project

Claude working notes for the IJIM major revision workspace.

## Status

- `manuscript/Algorithmic task assignment_manuscript_final.docx` is still the **original manuscript**.
- The live revision package is in:
  - `manuscript/response-letter.md`
  - `docs/20-revision-guide.md`
  - `docs/21-submission-readiness-check.md`
  - `docs/22-reference-audit.md`
  - `output/`
- `data/processed/` is a **local generated artifact** and is intentionally gitignored.

## Key Files

### Manuscript / review
- `manuscript/Algorithmic task assignment_manuscript_final.docx`
- `manuscript/review.docx`
- `manuscript/response-letter.md`

### Core revision docs
- `docs/20-revision-guide.md`
- `docs/21-submission-readiness-check.md`
- `docs/22-reference-audit.md`
- `docs/11-fact-check.md`
- `docs/12-new-references.md`

### Core evidence outputs
- `output/interpretation/01-event-study.md`
- `output/interpretation/02-oster-bounds.md`
- `output/interpretation/03-dose-response.md`
- `output/interpretation/04-stable-workers.md`
- `output/interpretation/05-inequality.md`
- `output/interpretation/06-learning-dynamics.md`
- `output/interpretation/07-worker-customer-linkage.md`
- `output/interpretation/08-submission-diagnostics.md`

### Key figures
- `output/figures/event_study_productivity.png`
- `output/figures/dose_response.png`
- `output/figures/inequality_density.png`
- `output/figures/worker_customer_linkage.png`
- `output/figures/sample_representativeness.png`

## Data Rules

### Source data
- `data/riders_full.csv`
- `data/new_data.csv`
- `data/rider_info.csv`

### Generated data
- `data/processed/`
- Regenerate with:

```bash
Rscript code/00_data_preparation.R
```

Use `code/00_data_preparation_v2.R` only if you explicitly want the alternate preprocessing path.

## Code Rules

### Do not modify
- `code/data preparation_231001.r`
- `code/data analysis_231001.r`
- original manuscript `.docx`
- original review `.docx`

### Main scripts
- `00_data_preparation.R`
- `01_reproduce_results.R`
- `02_event_study.R`
- `02_event_study_extended.R`
- `03_oster_bounds.R`
- `04_dose_response.R`
- `05_stable_workers.R`
- `06_inequality.R`
- `07_learning_dynamics.R`
- `08_worker_customer_linkage.R`
- `09_submission_diagnostics.R`

### Output conventions
- Tables -> `output/tables/`
- Figures -> `output/figures/`
- Short interpretation notes -> `output/interpretation/`
- Prefer English labels in figures

## Current Findings To Treat As Ground Truth

- Event-study pre-trends supported: `F = 1.41`, `p = 0.229`
- Oster: `delta* = -1.249`
- Inequality compresses: `Gini 0.181 -> 0.152`, `Theil 0.128 -> 0.055`
- Strongest gains appear among medium-proficiency riders
- Average waiting-time DID is not statistically significant
- Worker-customer linkage exists, but formal mediation is not identified
- Analytic full sample is broadly representative of active Busan riders

## Claims To Avoid

- formal mediation
- customer fixed effects unless actually added
- weather controls unless actually added
- platform-wide consumer welfare claims
- “single-order waiting time improved” as a headline result
- “AI promotes social equality”
- “low-proficiency workers benefited the most” as a blanket claim

## Reference Audit Reminders

- Remove duplicate `Chen et al. (2024a/b)` entries
- Prefer `Allon et al. (2023)` final version over old SSRN placeholder
- Remove trailing `*` from `Brynjolfsson et al. (2025)` title in bibliography
- Do not use `Knight et al.` as evidence that prior work avoided the term `skill`
- When citing `Dell'Acqua et al. (2023)`, mention the “inside the frontier” condition

## Recommended Read Order

1. `README.md`
2. `docs/21-submission-readiness-check.md`
3. `docs/20-revision-guide.md`
4. `manuscript/response-letter.md`
5. `docs/22-reference-audit.md`
