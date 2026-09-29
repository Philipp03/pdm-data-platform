# Data profile: Azure Predictive Maintenance dataset

Profiled on 2026-09-26 with DuckDB 1.5.5.
All queries and results: `sql-practice/week01_profiling.sql`

## Overview

| File | Rows | Time range | Unique key | Type |
|---|---|---|---|---|
| PdM_telemetry.csv | 876,100 | 2015-01-01 06:00 – 2016-01-01 06:00 | (machineID, datetime), checked | hourly measurements |
| PdM_machines.csv | 100 | – | machineID, checked | master data |
| PdM_failures.csv | 761 | 2015-01-02 03:00 – 2015-12-31 06:00 | not checked | events |
| PdM_errors.csv | 3,919 | 2015-01-01 06:00 – 2016-01-01 05:00 | not checked | events |
| PdM_maint.csv | 3,286 | 2014-06-01 06:00 – 2016-01-01 06:00 | not checked | events |

## Key findings

- **Types:** All columns were detected as expected; in particular, `datetime` is a TIMESTAMP in every file
- **Completeness:** No NULL values in any column of any file
- **Telemetry row count:** 876,100 rows instead of the expected 876,000, because both endpoints
  of the time range are included: 8,761 hourly timestamps per machine × 100 machines
- **Uniqueness:** `(machineID, datetime)` is unique in telemetry; `machineID` is unique in the master data
- **Value ranges:** All measurements are plausible: no values ≤ 0, and the maximum is at most
  1.9 times the average. `rotate` shows the strongest downward deviation (minimum = 0.31 × average)
- **Time ranges:** All failure and error timestamps fall within the telemetry range
  Maintenance records start in June 2014, about seven months before telemetry begins
- **Referential integrity:** Every machine referenced in failures, errors and maintenance exists
  in the master data.
- **Master data:** Four machine models, unevenly distributed (model3: 35, model4: 32
  model2: 17, model1: 16); machine age ranges from 0 to 20 years (average 11.3)
- **Identifiers:** `errorID` is text (e.g. `error1`), not a number
- **Maintenace records in 2014:** The 2014 records are not a full maintenance log, but the last replacement per component before telemetry starts, i.e. the starting point for features such as "time since last replacement".


## Assumptions and open questions

- **Time zone:** Timestamps carry no time zone. Assumed: one consistent local plant time
- **Units:** Units of the measurements are not documented. Assumed: validation limits are
  derived from observed ranges, not from technical specifications
- **Machine age:** No reference date is given for `age`. Assumed: age as of the start of the
  telemetry period
- **Distribution:** Only minimum and maximum were checked, not the distribution of the
  measurements (e.g. how many outliers exist)
- **Event uniqueness:** Not checked for failures, errors and maintenance (e.g. several
  failures of one machine at the same timestamp)


## Implications for the pipeline

- **Explicit schema:** Types were detected correctly, but the pipeline must not rely on
  auto-detection. Define column types explicitly when loading, so that a type change in
  the source (e.g. text in `volt`) fails loudly instead of silently changing the column type
- **Business key:** `(machineID, datetime)` is unique in telemetry → use it as the key for
  the upsert (week 4). Duplicates in future loads must be detected, not loaded twice
- **Row validation and quarantine:** No NULLs and plausible value ranges today. Future rows
  with missing or out-of-range values go to a quarantine table with a reason; the load
  continues. Alert if the quarantine share exceeds a threshold. Since the dataset contains
  no bad rows, tests use hand-written fixtures with deliberately broken rows
- **Completeness check for telemetry only:** Telemetry is a regular series (24 rows per
  machine and day), so missing hours are an error. Failures, errors and maintenance are
  events: gaps are normal and must not be reported
- **Referential integrity:** Events for unknown machines are not dropped and no master data
  is invented. They go to quarantine (or an explicitly flagged "unknown" placeholder)
  until the master data arrives
- **Keep historical maintenance records:** Maintenance data starts in June 2014, before
  telemetry. These records cannot be joined to sensor readings, but they are required to
  compute features such as "time since last component replacement" at the start of 2015.
  → Do not filter maintenance to the telemetry range; joins with telemetry must tolerate
  records without matching sensor data
