# IJIM Revision Workspace Guide

This file is the Codex-facing project guide for the IJIM revision repository.

## Repository State

- The manuscript `.docx` is the **original, unrevised version**.
- Revision evidence and planning live in `docs/`, `output/`, and `manuscript/response-letter.md`.
- `data/processed/` is generated locally and must not be committed.

## Priority Files

### Read first
1. `README.md`
2. `docs/21-submission-readiness-check.md`
3. `docs/20-revision-guide.md`
4. `manuscript/response-letter.md`
5. `docs/22-reference-audit.md`

### Core analysis outputs
- `output/interpretation/01-event-study.md`
- `output/interpretation/02-oster-bounds.md`
- `output/interpretation/05-inequality.md`
- `output/interpretation/07-worker-customer-linkage.md`
- `output/interpretation/08-submission-diagnostics.md`

## Do Not Modify

- `code/data preparation_231001.r`
- `code/data analysis_231001.r`
- `manuscript/Algorithmic task assignment_manuscript_final.docx`
- `manuscript/review.docx`
- raw source data files in `data/`

## Data Processing

Default rebuild path:

```bash
Rscript code/00_data_preparation.R
```

This regenerates the local analysis inputs in `data/processed/`.

Use `code/00_data_preparation_v2.R` only when you explicitly need the alternate preprocessing path.

## Analysis Run Order

```bash
Rscript code/00_data_preparation.R
Rscript code/01_reproduce_results.R
Rscript code/02_event_study.R
Rscript code/03_oster_bounds.R
Rscript code/04_dose_response.R
Rscript code/05_stable_workers.R
Rscript code/06_inequality.R
Rscript code/07_learning_dynamics.R
Rscript code/08_worker_customer_linkage.R
Rscript code/09_submission_diagnostics.R
```

Run `02_event_study_extended.R` only when the long-window data assumptions are appropriate.

## Output Rules

- Save tables to `output/tables/`
- Save figures to `output/figures/`
- Save short interpretation notes to `output/interpretation/`
- Prefer English figure labels and stable filenames

## Current Evidentiary Baseline

- Event-study supports parallel trends
- Oster bounds support robustness
- Productivity distribution compresses after adoption
- Medium-proficiency riders show the clearest gains
- Average customer waiting-time DID is null
- Worker-side productivity is negatively associated with customer waiting time
- Sample representativeness is acceptable for the analytic full sample

## Writing Rules For The Revision

### Safe claims
- `skill -> proficiency`
- AI vs conventional dispatch distinction
- conditional customer-side language
- worker-customer linkage without formal mediation
- short-term evidence framing
- inequality compression

### Avoid
- formal mediation
- customer FE / weather controls unless actually implemented
- platform-wide welfare claims
- overclaiming single-order improvement
- “AI promotes social equality”
- unsupported long-run adaptation claims

## Reference Checks

- Remove duplicate `Chen et al. (2024a/b)`
- Use correct version of `Allon et al. (2023)`
- Clean `Brynjolfsson et al. (2025)` title formatting
- Do not misuse `Knight et al.` for terminology support
- Add “inside the frontier” qualification for `Dell'Acqua et al.`

## Practical Note

If updating revision documents, keep `docs/20-revision-guide.md`, `docs/21-submission-readiness-check.md`, `docs/22-reference-audit.md`, and `manuscript/response-letter.md` aligned.
