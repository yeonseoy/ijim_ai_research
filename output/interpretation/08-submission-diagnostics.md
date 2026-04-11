# Submission diagnostics: representativeness and precision

## Representativeness benchmark
- Active Busan riders in the study window: 1085 riders and 35410 rider-days.
- Analytic full sample: 936 riders and 33896 rider-days.
- Matched sample: 372 riders and 10121 rider-days.

## Key metric comparison
- Orders/hour: active 4.586, analytic 4.62, matched 4.888
- Daily orders: active 30.63, analytic 30.81, matched 26.73
- Daily labor hours: active 6.77, analytic 6.76, matched 5.6
- Daily fee: active 91736, analytic 92296, matched 79685

## Interpretation
- The analytic full sample closely matches the active-Busan benchmark on the core operating metrics, supporting a representativeness claim for the retained study riders.
- The matched sample is less representative on levels by construction because PSM prioritizes covariate balance over population representativeness.

## Design-based precision benchmarks
- Daily productivity DID: SE = 0.0757, MDE = 0.212 orders/hour (4.3% of the matched-sample mean).
- Customer waiting DID: SE = 0.1646, MDE = 0.461 minutes (2.6% of the order-level mean).

## Files
- Table: output/tables/sample_representativeness.csv
- Table: output/tables/precision_benchmarks.csv
- Figure: output/figures/sample_representativeness.png

