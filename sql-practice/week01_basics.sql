-- Short names for the source files (views are stored queries that behave like tables)
CREATE OR REPLACE VIEW telemetry AS SELECT * FROM 'data/raw/PdM_telemetry.csv';
CREATE OR REPLACE VIEW machines  AS SELECT * FROM 'data/raw/PdM_machines.csv';
CREATE OR REPLACE VIEW failures  AS SELECT * FROM 'data/raw/PdM_failures.csv';
CREATE OR REPLACE VIEW errors    AS SELECT * FROM 'data/raw/PdM_errors.csv';
CREATE OR REPLACE VIEW maint     AS SELECT * FROM 'data/raw/PdM_maint.csv';


-- =========================================================
-- Task 1: All measurements of machine 17 in June 2015, sorted by time
-- =========================================================
-- Expected: 720 rows (30 days x 24 hours; half-open interval excludes 2015-07-01 00:00)
-- Result: 720 rows, first 2015-06-01 00:00, last 2015-06-30 23:00
SELECT * FROM telemetry WHERE datetime >= '2015-06-01' AND datetime < '2015-07-01' AND machineID = 17 ORDER BY datetime;

-- Cross-check: row count via COUNT(*)
-- Result: 720 entries
SELECT COUNT(*) FROM telemetry WHERE datetime >= '2015-06-01' AND datetime < '2015-07-01' AND machineID = 17;

-- =========================================================
-- Task 2: All measurements with machineID and dates for the 10 highest vibration values
-- =========================================================

-- Expected: Maximum value for vibration data form the data profiling (76.79)
-- Result: max 76.79 (machine 19), matches the data profile.
--         8 of 10 from different machines; machine 45 appears twice on 2015-01-02
SELECT datetime, machineID, vibration FROM telemetry ORDER BY vibration DESC LIMIT 10;

-- =========================================================
-- Task 3: Number of failures per component, descending
-- =========================================================

-- Expected: 4 rows (components); sum of counts = 761 (total failures)
-- Result: comp2 259, comp1 192, comp4 179, comp3 131; sum = 761
SELECT failure, COUNT(*) AS n_failures  FROM failures GROUP BY failure ORDER BY count;

-- Cross-check: total number of failures
-- Result: 761
SELECT COUNT(*) FROM failures;


-- =========================================================
-- Task 4: Pro Maschinenmodell: Anzahl der Maschinen und Durchschnittsalter, sortiert nach Modell
-- =========================================================

-- Expected: 4 rows; counts from data profile (model1 16, model2 17, model3 35, model4 32); sum = 100
-- Result: as expected. avg age: model1 12.3, model2 12.8, model3 12.0, model4 9.3
-- Cross-check: weighted average (16*12.25 + 17*12.76 + 35*12.03 + 32*9.34) / 100 = 11.3
--              = overall average from data profile. A simple average of the four would give 11.6 (wrong).
SELECT model, COUNT(*) AS n_machines, AVG(age) AS avg_age FROM machines GROUP BY model ORDER BY model;