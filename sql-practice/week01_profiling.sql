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
-- Result: 2015-01-01 06:00 to 2016-01-01 06:00 (both endpoints included
-- -> 8,761 timestamps per machine x 100 = 876,100, explains the row count)
SELECT MIN(datetime), MAX(datetime) FROM 'data/raw/PdM_telemetry.csv';

-- Duplicate check on (machineID, datetime). Expected: no rows
-- Result: 0 rows -> (machineID, datetime) is unique
SELECT t.machineID, t.datetime, COUNT(*) AS n
FROM 'data/raw/PdM_telemetry.csv' AS t
GROUP BY t.machineID, t.datetime
HAVING COUNT(*) > 1;


-- Count of NULL values per column. Expected: 0 for all columns
SELECT
    COUNT(*) - COUNT(datetime)  AS null_datetime,
    COUNT(*) - COUNT(machineID) AS null_machineID,
    COUNT(*) - COUNT(volt)      AS null_volt,
    COUNT(*) - COUNT(rotate)    AS null_rotate,
    COUNT(*) - COUNT(pressure)  AS null_pressure,
    COUNT(*) - COUNT(vibration) AS null_vibration
FROM 'data/raw/PdM_telemetry.csv';

-- Min, max, and average values for numeric columns
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