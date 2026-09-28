-- =========================================================
-- PdM_telemetry.csv
-- =========================================================

-- Detected columns and types (check: datetime must be TIMESTAMP, not VARCHAR)
-- Result: datetime TIMESTAMP, machineID BIGINT, volt/rotate/pressure/vibration DOUBLE
DESCRIBE SELECT * FROM 'data/raw/PdM_telemetry.csv';

-- Row count. Expected: 876,000 (100 machines x 24 h x 365 days)
-- Result: 876,100 -> see time range below
SELECT COUNT(*) FROM 'data/raw/PdM_telemetry.csv';

-- Number of distinct machines. Expected: 100
-- Result: 100
SELECT COUNT(DISTINCT machineID) FROM 'data/raw/PdM_telemetry.csv';

-- Time range of measurements
-- Result: 2015-01-01 06:00 to 2016-01-01 06:00 
-- -> 8,761 timestamps per machine x 100 = 876,100, explains the row count)
SELECT MIN(datetime), MAX(datetime) FROM 'data/raw/PdM_telemetry.csv';

-- Duplicate check on (machineID, datetime). Expected: no rows
-- Result: 0 rows -> (machineID, datetime) is unique
SELECT t.machineID, t.datetime, COUNT(*) AS n
FROM 'data/raw/PdM_telemetry.csv' AS t
GROUP BY t.machineID, t.datetime
HAVING COUNT(*) > 1;


-- Count of NULL values per column. Expected: 0 for all columns
-- Result: 0 for all columns
SELECT
    COUNT(*) - COUNT(datetime)  AS null_datetime,
    COUNT(*) - COUNT(machineID) AS null_machineID,
    COUNT(*) - COUNT(volt)      AS null_volt,
    COUNT(*) - COUNT(rotate)    AS null_rotate,
    COUNT(*) - COUNT(pressure)  AS null_pressure,
    COUNT(*) - COUNT(vibration) AS null_vibration
FROM 'data/raw/PdM_telemetry.csv';

-- Min, max, and average values for numeric columns
-- Expected: no values <= 0; no max above 3x the average
-- Result: confirmed. All values > 0; max/avg ratio 1.5-1.9.
--         vibration and pressure show the widest upward spread,
--         rotate the strongest downward spread (min = 0.31 x avg) 
.mode line
SELECT
    MIN(volt)             AS min_volt,
    MAX(volt)             AS max_volt,
    ROUND(AVG(volt), 1)   AS avg_volt,
    MIN(rotate)           AS min_rotate,
    MAX(rotate)           AS max_rotate,
    ROUND(AVG(rotate), 1) AS avg_rotate,
    MIN(pressure)         AS min_pressure,
    MAX(pressure)         AS max_pressure,
    ROUND(AVG(pressure), 1) AS avg_pressure,
    MIN(vibration)        AS min_vibration,
    MAX(vibration)        AS max_vibration,
    ROUND(AVG(vibration), 1) AS avg_vibration
FROM 'data/raw/PdM_telemetry.csv';
.mode duckbox

-- =========================================================
-- PdM_machines.csv
-- =========================================================

-- Detected columns and types 
-- Result: machineID BIGINT, model VARCHAR, age bigint
DESCRIBE SELECT * FROM 'data/raw/PdM_machines.csv';

-- Row count
-- Expected: 100
-- Result: 100
SELECT COUNT(*) FROM 'data/raw/PdM_machines.csv';

-- Number of distinct machines
-- Expected: 100
-- Result: 100
SELECT COUNT(DISTINCT machineID) FROM 'data/raw/PdM_machines.csv';

-- Duplicate check on machineID
-- Expected: no rows
-- Result: 0 rows -> machineID is unique
SELECT t.machineID, COUNT(*) AS n
FROM 'data/raw/PdM_machines.csv' AS t
GROUP BY t.machineID
HAVING COUNT(*) > 1;

-- Count of NULL values per column
-- Expected: 0 for all columns
-- Result: 0 for all columns
SELECT
    COUNT(*) - COUNT(machineID)    AS null_machineID,
    COUNT(*) - COUNT(model)        AS null_model,
    COUNT(*) - COUNT(age)          AS null_age
FROM 'data/raw/PdM_machines.csv';

-- Min, max, and average values for age column
-- Result: min=0, max=20, avg=11.3
SELECT
    MIN(age) AS min_age,
    MAX(age) AS max_age,
    ROUND(AVG(age), 1) AS avg_age
FROM 'data/raw/PdM_machines.csv';

-- Count of machines per model
-- Result: 4 models with different counts (model 1: 16, model 2: 17, model 3: 35, model 4: 32)
SELECT model, COUNT(*) AS n
FROM 'data/raw/PdM_machines.csv'
GROUP BY model
ORDER BY n DESC;

-- =========================================================
-- PdM_failures.csv
-- =========================================================

-- Detected columns and types 
-- Result: machineID BIGINT, datetime timestamp, failure VARCHAR
DESCRIBE SELECT * FROM 'data/raw/PdM_failures.csv';

-- Row count
-- Result: 761
SELECT COUNT(*) FROM 'data/raw/PdM_failures.csv';

-- range of failure dates
-- Expected: 2015-01-01 to 2016-01-01 (within the telemetry range)
-- Result: 2015-01-02 03:00:00 to 2015-12-31 06:00:00 (in telemetry range, but plausible as there could have been no failures)
SELECT MIN(datetime), MAX(datetime) FROM 'data/raw/PdM_failures.csv';

-- Search machines with failures but no machine data. Expected: 0 rows
-- Result: 0 rows
SELECT f.machineID
FROM 'data/raw/PdM_failures.csv' AS f
LEFT JOIN 'data/raw/PdM_machines.csv' AS t
    ON f.machineID = t.machineID
WHERE t.machineID IS NULL;

-- count of Null values per column
-- Expected: 0 for all columns
-- Result: 0 for all columns
SELECT
    COUNT(*) - COUNT(machineID)    AS null_machineID,
    COUNT(*) - COUNT(datetime)  AS null_datetime,
    COUNT(*) - COUNT(failure)  AS null_failure
FROM 'data/raw/PdM_failures.csv';

-- =========================================================
-- PdM_errors.csv
-- =========================================================

-- Detected columns and types 
-- Result: machineID BIGINT, datetime timestamp, errorID VARCHAR
DESCRIBE SELECT * FROM 'data/raw/PdM_errors.csv';

-- count rows
-- Result: 3919
SELECT COUNT(*) FROM 'data/raw/PdM_errors.csv';

-- count of NULL Values per column
-- Expected: 0 for all columns
-- Result: 0 for all columns
SELECT
    COUNT(*) - COUNT(machineID)    AS null_machineID,
    COUNT(*) - COUNT(datetime)    AS null_datetime,
    COUNT(*) - COUNT(errorID)    AS null_errorID
FROM 'data/raw/PdM_errors.csv';

-- Range of error dates
-- Expected: 2015-01-01 to 2016-01-01 (within the telemetry range)
-- Result: 2015-01-01 06:00:00 to 2016-01-01 05:00:00 (in telemetry range, but plausible as there could have been no errors)
SELECT MIN(datetime), MAX(datetime) FROM 'data/raw/PdM_errors.csv';

-- Search machines with errors but no machine data. Expected: 0 rows
-- Result: 0 rows
SELECT f.machineID
FROM 'data/raw/PdM_errors.csv' AS f
LEFT JOIN 'data/raw/PdM_machines.csv' AS t
    ON f.machineID = t.machineID
WHERE t.machineID IS NULL;

-- =========================================================
-- PdM_maint.csv
-- =========================================================

-- Detected columns and types 
-- Result: machineID BIGINT, datetime timestamp, comp VARCHAR
DESCRIBE SELECT * FROM 'data/raw/PdM_maint.csv';

-- count rows
-- Result: 3286
SELECT COUNT(*) FROM 'data/raw/PdM_maint.csv';

-- Range of maintenance dates
-- Expected: 2015-01-01 to 2016-01-01 (within the telemetry range)
-- Result: 2014-06-01 06:00:00 to 2016-01-01 06:00:00 (not in telemetry range, maintenance data also recorded in 2014)
SELECT MIN(datetime), MAX(datetime) FROM 'data/raw/PdM_maint.csv';

-- Search machines with maintenance records but no machine data. Expected: 0 rows
-- Result: 0 rows
SELECT f.machineID
FROM 'data/raw/PdM_maint.csv' AS f
LEFT JOIN 'data/raw/PdM_machines.csv' AS t
    ON f.machineID = t.machineID
WHERE t.machineID IS NULL;

-- Count of NULL values per column
-- Expected: 0 for all columns
-- Result: 0 for all columns
SELECT
    COUNT(*) - COUNT(machineID)    AS null_machineID,
    COUNT(*) - COUNT(datetime)    AS null_datetime,
    COUNT(*) - COUNT(comp)    AS null_comp
FROM 'data/raw/PdM_maint.csv';