# Worker-customer linkage analysis

## Purpose
- Provide direct evidence on whether worker-side efficiency covaries with customer waiting times.
- This is not a formal mediation design; it is an operational linkage analysis using matched rider-day and order data.

## Specification
- Outcome: rider-day average customer waiting time (all orders / single-order days / stacked-order days)
- Key regressor: rider-day productivity (orders_per_hour)
- Fixed effects: rider FE, station-date FE
- Controls: average rider-day delivery distance
- Clustered SE: rider level

## Main results
- All orders: beta = -0.0205 (SE = 0.0042, p = 0)
- Single-order days: beta = -0.0181 (SE = 0.0045, p = 1e-04)
- Stacked-order days: beta = -0.0719 (SE = 0.0072, p = 0)
- Share of single orders: beta = 4e-04 (SE = 4e-04, p = 0.3662)

## Interpretation
- More productive rider-days are associated with shorter customer waits, indicating that worker-side efficiency and customer experience are operationally linked.
- However, productivity is not associated with a higher share of single-order deliveries, suggesting that pass-through is not driven by simple order-type reallocation.
- This supports a cautious worker-to-customer linkage claim, but not a formal mediation claim.

## Files
- Table: output/tables/worker_customer_linkage.csv
- Figure: output/figures/worker_customer_linkage.png

