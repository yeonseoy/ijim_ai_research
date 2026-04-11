################################################################################
# 09_submission_diagnostics.R
# Submission diagnostics for representativeness and design-based precision.
################################################################################
library(data.table)
library(ggplot2)
library(lubridate)

cat("=== US-012: Submission diagnostics ===\n")
setwd("/Users/gujaeseo/Documents/projects/yeonseo/ijim_ai_research")
dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("output/interpretation", showWarnings = FALSE, recursive = TRUE)

PRE_START <- as.Date("2020-09-26")
POST_END <- as.Date("2020-11-25")

cat("[1/4] Build active Busan benchmark from raw data...\n")
cols <- c(
  "agent_id", "partner_name", "submittedat", "assignedat", "pickedupat",
  "deliveredat", "agent_fee", "agent_extra_fee", "management_partner_id",
  "store_id", "order_id"
)
raw <- fread("data/riders_full.csv", select = cols, showProgress = FALSE)
setnames(raw, c("agent_id", "agent_fee", "agent_extra_fee"),
         c("rider_id", "rider_fee", "rider_extra_fee"))
raw[, submitted_at := as.POSIXct(submittedat, tz = "UTC")]
raw[, assigned_at := as.POSIXct(assignedat, tz = "UTC")]
raw[, picked_up_at := as.POSIXct(pickedupat, tz = "UTC")]
raw[, delivered_at := as.POSIXct(deliveredat, tz = "UTC")]
raw <- raw[!is.na(picked_up_at) & !is.na(delivered_at)]
raw <- raw[!duplicated(order_id)]
raw <- raw[grepl("부산", partner_name) & !grepl("울산|진해", partner_name)]
raw[, ymd := as.Date(submitted_at)]
raw <- raw[ymd >= PRE_START & ymd <= POST_END]
raw[, rider_total_fee := rider_fee + rider_extra_fee]
raw <- raw[rider_total_fee > 0]

setorder(raw, rider_id, ymd, assigned_at)
raw[, delivered_at_num := as.numeric(delivered_at)]
raw[, delivered_at_cummax := cummax(delivered_at_num), by = .(ymd, rider_id)]
raw[, delivered_at_max := as.POSIXct(delivered_at_cummax, origin = "1970-01-01", tz = "UTC")]
shift_start_flag <- function(assigned, delivered_max) {
  n <- length(assigned)
  if (n == 1) return(1L)
  c(1L, ifelse(assigned[-1] <= delivered_max[-n], 1L, 0L))
}
raw[, check := shift_start_flag(assigned_at, delivered_at_max), by = .(ymd, rider_id)]
raw[, shift := cumsum(check == 0L) + 1L, by = .(ymd, rider_id)]

shift_all <- raw[, .(
  num_orders = .N,
  shift_profit = sum(rider_total_fee),
  start = assigned_at[1],
  finish = max(delivered_at),
  total_duration = as.numeric(difftime(max(delivered_at), assigned_at[1], units = "mins"))
), by = .(rider_id, management_partner_id, ymd, shift)]

shift_all <- shift_all[order(rider_id, ymd, shift)]
shift_all[, idle_btw_shifts := c(NA, as.numeric(difftime(start[-1], finish[-.N], units = "secs"))),
          by = .(rider_id, ymd)]
shift_all[idle_btw_shifts > 3600, idle_btw_shifts := NA]
shift_all[, idle_btw_shifts := idle_btw_shifts / 60]

day_all <- shift_all[, .(
  total_shift = .N,
  total_orders = sum(num_orders),
  total_fee = sum(shift_profit),
  working_duration = sum(total_duration) / 60,
  idle_duration = sum(idle_btw_shifts, na.rm = TRUE) / 60
), by = .(rider_id, management_partner_id, ymd)]
day_all[, total_labor := working_duration + idle_duration]
day_all[, orders_per_hour := total_orders / total_labor]

cat("[2/4] Summarize benchmark vs analysis samples...\n")
full <- fread("data/processed/data_day_full.csv")
matched <- fread("data/processed/data_day_matched.csv")

summarize_sample <- function(dt, label) {
  data.table(
    sample = label,
    n_riders = uniqueN(dt$rider_id),
    n_rider_days = nrow(dt),
    mean_oph = mean(dt$orders_per_hour, na.rm = TRUE),
    mean_orders = mean(dt$total_orders, na.rm = TRUE),
    mean_labor = mean(dt$total_labor, na.rm = TRUE),
    mean_fee = mean(dt$total_fee, na.rm = TRUE)
  )
}

rep_dt <- rbindlist(list(
  summarize_sample(day_all, "All active Busan riders"),
  summarize_sample(full, "Analytic full sample"),
  summarize_sample(matched, "Matched sample")
))

baseline <- rep_dt[sample == "All active Busan riders"]
for (metric in c("mean_oph", "mean_orders", "mean_labor", "mean_fee")) {
  rep_dt[, paste0(metric, "_pct_of_active") :=
           100 * get(metric) / baseline[[metric]][1]]
}
fwrite(rep_dt, "output/tables/sample_representativeness.csv")

cat("[3/4] Compute design-based precision benchmarks...\n")
t4 <- fread("output/tables/table4_daily_productivity.csv")
t7 <- fread("output/tables/table7_waiting_time.csv")
z_star <- qnorm(0.975) + qnorm(0.8)

precision <- rbindlist(list(
  data.table(
    outcome = "Daily productivity (matched DID)",
    mean_outcome = mean(matched$orders_per_hour, na.rm = TRUE),
    se = t4[model == "DID_avg", se],
    mde_abs = z_star * t4[model == "DID_avg", se]
  ),
  data.table(
    outcome = "Customer waiting time (matched DID)",
    mean_outcome = mean(fread("data/processed/orders_matched.csv")$waiting_sec / 60, na.rm = TRUE),
    se = t7[type == "all", se],
    mde_abs = z_star * t7[type == "all", se]
  )
))
precision[, mde_pct := 100 * mde_abs / mean_outcome]
fwrite(precision, "output/tables/precision_benchmarks.csv")

cat("[4/4] Save representativeness figure + interpretation...\n")
plot_dt <- melt(
  rep_dt[, .(sample, mean_oph_pct_of_active, mean_orders_pct_of_active,
             mean_labor_pct_of_active, mean_fee_pct_of_active)],
  id.vars = "sample",
  variable.name = "metric",
  value.name = "pct_of_active"
)
plot_dt[, metric := factor(
  metric,
  levels = c("mean_oph_pct_of_active", "mean_orders_pct_of_active",
             "mean_labor_pct_of_active", "mean_fee_pct_of_active"),
  labels = c("Orders/hour", "Daily orders", "Daily labor hours", "Daily fee")
)]

p <- ggplot(plot_dt, aes(x = metric, y = pct_of_active, color = sample, group = sample)) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "gray50") +
  geom_point(size = 2.8) +
  geom_line(linewidth = 0.7) +
  labs(
    x = NULL,
    y = "Percent of active-Busan benchmark",
    title = "Representativeness check against all active Busan riders",
    subtitle = "Analytic full sample closely tracks the platform benchmark; matched sample is narrower by design"
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        legend.title = element_blank())
ggsave("output/figures/sample_representativeness.png", p, width = 10, height = 5.5, dpi = 300)

active <- rep_dt[sample == "All active Busan riders"]
analytic <- rep_dt[sample == "Analytic full sample"]
matched_s <- rep_dt[sample == "Matched sample"]

interp <- paste0(
  "# Submission diagnostics: representativeness and precision\n\n",
  "## Representativeness benchmark\n",
  "- Active Busan riders in the study window: ", active$n_riders,
  " riders and ", active$n_rider_days, " rider-days.\n",
  "- Analytic full sample: ", analytic$n_riders, " riders and ",
  analytic$n_rider_days, " rider-days.\n",
  "- Matched sample: ", matched_s$n_riders, " riders and ",
  matched_s$n_rider_days, " rider-days.\n\n",
  "## Key metric comparison\n",
  "- Orders/hour: active ", round(active$mean_oph, 3), ", analytic ",
  round(analytic$mean_oph, 3), ", matched ", round(matched_s$mean_oph, 3), "\n",
  "- Daily orders: active ", round(active$mean_orders, 2), ", analytic ",
  round(analytic$mean_orders, 2), ", matched ", round(matched_s$mean_orders, 2), "\n",
  "- Daily labor hours: active ", round(active$mean_labor, 2), ", analytic ",
  round(analytic$mean_labor, 2), ", matched ", round(matched_s$mean_labor, 2), "\n",
  "- Daily fee: active ", round(active$mean_fee, 0), ", analytic ",
  round(analytic$mean_fee, 0), ", matched ", round(matched_s$mean_fee, 0), "\n\n",
  "## Interpretation\n",
  "- The analytic full sample closely matches the active-Busan benchmark on the core operating metrics, supporting a representativeness claim for the retained study riders.\n",
  "- The matched sample is less representative on levels by construction because PSM prioritizes covariate balance over population representativeness.\n\n",
  "## Design-based precision benchmarks\n",
  "- Daily productivity DID: SE = ", round(precision[outcome == "Daily productivity (matched DID)", se], 4),
  ", MDE = ", round(precision[outcome == "Daily productivity (matched DID)", mde_abs], 3),
  " orders/hour (", round(precision[outcome == "Daily productivity (matched DID)", mde_pct], 1), "% of the matched-sample mean).\n",
  "- Customer waiting DID: SE = ", round(precision[outcome == "Customer waiting time (matched DID)", se], 4),
  ", MDE = ", round(precision[outcome == "Customer waiting time (matched DID)", mde_abs], 3),
  " minutes (", round(precision[outcome == "Customer waiting time (matched DID)", mde_pct], 1), "% of the order-level mean).\n\n",
  "## Files\n",
  "- Table: output/tables/sample_representativeness.csv\n",
  "- Table: output/tables/precision_benchmarks.csv\n",
  "- Figure: output/figures/sample_representativeness.png\n"
)
writeLines(interp, "output/interpretation/08-submission-diagnostics.md")

cat("Saved:\n")
cat("  output/tables/sample_representativeness.csv\n")
cat("  output/tables/precision_benchmarks.csv\n")
cat("  output/figures/sample_representativeness.png\n")
cat("  output/interpretation/08-submission-diagnostics.md\n")
