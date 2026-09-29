-- Short names for the source files (views are stored queries that behave like tables)
CREATE OR REPLACE VIEW telemetry AS
SELECT * FROM read_csv('data/raw/PdM_telemetry.csv');
CREATE OR REPLACE VIEW machines AS
SELECT * FROM read_csv('data/raw/PdM_machines.csv');
CREATE OR REPLACE VIEW failures AS
SELECT * FROM read_csv('data/raw/PdM_failures.csv');
CREATE OR REPLACE VIEW errors AS
SELECT * FROM read_csv('data/raw/PdM_errors.csv');
CREATE OR REPLACE VIEW maint AS
SELECT * FROM read_csv('data/raw/PdM_maint.csv');


-- =========================================================
-- Task 1: All measurements of machine 17 in June 2015, sorted by time
-- =========================================================
-- Expected: 720 rows (30 days x 24 hours; half-open interval excludes 2015-07-01 00:00)
-- Result: 720 rows, first 2015-06-01 00:00, last 2015-06-30 23:00
SELECT *
FROM telemetry
WHERE datetime >= '2015-06-01' AND datetime < '2015-07-01' AND machineid = 17
ORDER BY datetime;

-- Cross-check: row count via COUNT(*)
-- Result: 720 entries
SELECT count(*)
FROM telemetry
WHERE datetime >= '2015-06-01' AND datetime < '2015-07-01' AND machineid = 17;

-- =========================================================
-- Task 2: All measurements with machineID and dates for the 10 highest vibration values
-- =========================================================

-- Expected: Maximum value for vibration data form the data profiling (76.79)
-- Result: max 76.79 (machine 19), matches the data profile.
--         8 of 10 from different machines; machine 45 appears twice on 2015-01-02
SELECT
    datetime,
    machineid,
    vibration
FROM telemetry
ORDER BY vibration DESC
LIMIT 10;

-- =========================================================
-- Task 3: Number of failures per component, descending
-- =========================================================

-- Expected: 4 rows (components); sum of counts = 761 (total failures)
-- Result: comp2 259, comp1 192, comp4 179, comp3 131; sum = 761
SELECT
    failure,
    count(*) AS n_failures
FROM failures
GROUP BY failure
ORDER BY n_failures;

-- Cross-check: total number of failures
-- Result: 761
SELECT count(*) FROM failures;


-- =========================================================
-- Task 4: Number of machines and average age per machine model sorted by machine model
-- =========================================================

-- Expected: 4 rows; counts from data profile (model1 16, model2 17, model3 35, model4 32); sum = 100
-- Result: as expected. avg age: model1 12.3, model2 12.8, model3 12.0, model4 9.3
-- Cross-check: weighted average (16*12.25 + 17*12.76 + 35*12.03 + 32*9.34) / 100 = 11.3
--              = overall average from data profile. A simple average of the four would give 11.6 (wrong).
SELECT
    model,
    count(*) AS n_machines,
    avg(age) AS avg_age
FROM machines
GROUP BY model
ORDER BY model;


-- =========================================================
-- Task 5: Average vibration per machine, having a value greater than 41 
-- =========================================================

-- Cross Check
SELECT
    machineid,
    round(avg(vibration), 2) AS avg_vibration
FROM telemetry
GROUP BY machineid
ORDER BY avg_vibration DESC
LIMIT 5;

-- Expected: 0 machines with an average vibration greater than 41, as 5 maximum averages are already below 41
-- Result: 0 machines
SELECT
    machineid,
    round(avg(vibration)) AS avg_vibration
FROM telemetry
GROUP BY machineid
HAVING avg_vibration > 41;


-- =========================================================
-- Task 6: How many machines never had a failure in the given data?
-- =========================================================

-- Expected: Number must be between 0 and 100; there are 761 failures given 100 machines meaning on average 7-8 failures per machine --> machines without failure almost not exisitng
-- Result: 2 machines without failures
SELECT count(failures.machineid)
FROM machines
LEFT JOIN failures ON machines.machineid = failures.machineid
WHERE failures.machineid IS NULL;

-- Cross-Check: Alternative to get machines without failures (leads to the same result)
SELECT count(*)
FROM machines AS m
WHERE NOT EXISTS (
    SELECT 1 FROM failures AS f
    WHERE f.machineid = m.machineid
);


-- =========================================================
-- Task 7: Number of error message per month in 2015, sorted by date
-- =========================================================

-- Cross Check:
-- Result: 3917 (vs. 3919 for whole table)
SELECT count(*)
FROM errors
WHERE datetime >= '2015-01-01' AND datetime < '2016-01-01';

-- Expected: Number must of rows must be between 0 and 12; there are 3919 errors in the data meaning on average 326,58 a month --> months without failure should be 0
-- Result: for all months available not, always around the average, use date-trunc to avoid values from 2016-01-01 instead of month(datetime)
SELECT
    date_trunc('month', datetime) AS month_start,
    monthname(datetime) AS month_name,
    count(*) AS n_errors
FROM errors
WHERE datetime >= '2015-01-01' AND datetime < '2016-01-01'
GROUP BY month_start, month_name
ORDER BY month_start;

-- =========================================================
-- Task 8: Maintenance records before telemetry start
-- =========================================================
-- Expected: ~1,200 if evenly distributed (3,286 over ~19 months = ~173/month x 7 months)
-- Result: 400, far below expectation
SELECT count(*) AS n_maint
FROM maint
WHERE maint.datetime < (SELECT min(telemetry.datetime) FROM telemetry);

-- Hypothesis: 400 = 100 machines x 4 components, i.e. exactly one record per machine and component.
-- Check: no machine/component combination appears more than once. Expected: 0 rows
-- Result: 0 rows -> 400 distinct combinations out of 400 possible -> hypothesis confirmed
SELECT
    maint.machineid,
    maint.comp,
    count(*) AS n_maint
FROM maint
WHERE maint.datetime < (SELECT min(telemetry.datetime) FROM telemetry)
GROUP BY maint.machineid, maint.comp
HAVING count(*) > 1;

-- Interpretation: the 2014 records are not a full maintenance log, but the last
-- replacement per component before telemetry starts, i.e. the starting point for
-- features such as "time since last replacement"

-- =========================================================
-- Task 9: First failure (date), last failure (date) and number of failures for each machine
-- =========================================================

-- Expected: 100 machines, 2 without failures --> 98 rows expected. Given 761 failures expected value per machine 7-8 failures. Date must be in range of 2015-01-02 03:00:00 to 2015-12-31 06:00:00
-- Result: 98 machines with failures, maximal failures per machine 19, minimum failures per machine 2
SELECT
    machineID,
    min(datetime) AS date_first_failure,
    max(datetime) AS date_last_failure,
    count(machineID) AS n_failures
FROM failures
GROUP BY machineID
ORDER BY n_failures DESC;

-- Cross Check: check if 2 machines from before are in the table
SELECT *
FROM (
    SELECT
        machineID,
        min(datetime) AS date_first_failure,
        max(datetime) AS date_last_failure,
        count(machineID) AS n_failures
    FROM failures
    GROUP BY machineID
    ORDER BY n_failures DESC
) AS per_machine
WHERE machineID IN (6, 77);


-- Cross Check: Dates
SELECT
    min(date_first_failure) AS overall_first_failure,
    max(date_last_failure) AS overall_last_failure
FROM
    (SELECT
        machineID,
        min(datetime) AS date_first_failure,
        max(datetime) AS date_last_failure,
        count(machineID) AS n_failures
    FROM failures
    GROUP BY machineID
    ORDER BY n_failures DESC) AS per_machine;

-- =========================================================
-- Task 10: Why is the filter in task 5 in HAVING and not in WHERE?
-- =========================================================

-- WHERE is used to filter rows before aggregation, works well with individual rows and is applied before GROUP BY
-- HAVING is used to filter after aggregation, work with grouped data and is applied after GROUP BY

-- In task 5, WHERE vibration > 41 would keep only the individual measurements above 41
-- and average those. The average of values above 41 is always above 41, so nearly every
-- machine would pass the filter. The query runs without error, but answers a different
-- question - the result is silently wrong.

-- =========================================================
-- Bonus: Does the earliest failure (2015-01-02 03:00) belong to machine 45, and which component failed?
-- =========================================================

SELECT * FROM failures
WHERE datetime = '2015-01-02 03:00:00' AND machineID = 45;

-- Result: yes. Machine 45, comp1 failed at 03:00 - one hour after its vibration peak
--         of 73.9 at 02:00 (second-highest value of the year, see task 2).
--         Supports the hypothesis that vibration rises before a failure (single case only).
