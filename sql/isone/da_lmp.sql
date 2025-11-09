

SELECT MIN(hour_beginning), MAX(hour_beginning), COUNT(*)
FROM da_lmp
WHERE ptid = 4000;

SELECT strftime(hour_beginning, '%Y-%m') AS yearmon, COUNT(*) AS rows
FROM da_lmp
WHERE ptid = 4000
GROUP BY yearmon
ORDER BY yearmon;

SELECT * 
FROM da_lmp 
WHERE ptid = 4000
AND hour_beginning >= '2025-07-01'
AND hour_beginning < '2025-07-2';

--- Get the hourly MCC prices in Json compact form for MCC surfer!


SELECT ptid, hour_beginning, mcc
FROM da_lmp
WHERE ptid in (4000, 4001)
AND hour_beginning >= '2025-07-01'
AND hour_beginning < '2025-07-03'
ORDER BY ptid, hour_beginning;

SELECT
  date(hour_beginning) AS date,
  ptid,
  list(mcc ORDER BY hour_beginning)::DECIMAL(9,4)[] AS values
FROM da_lmp
WHERE hour_beginning >= '2025-07-01'
  AND hour_beginning <  '2025-07-15'
  AND ptid IN (4000, 4001)
GROUP BY ptid, date
ORDER BY ptid, date;

--- Create a compact json string by hand:  
--- {"2025-07-01": {"4000":[...],"4001":[...]}, "2025-07-02":{...} ...}
SELECT '{' || string_agg('"' || date || '":' || map_json, ',') || '}' AS out
FROM (
    WITH per_ptid AS (
    SELECT
        strftime(hour_beginning, '%Y-%m-%d') AS date,
        ptid,
        list(mcc ORDER BY hour_beginning)::DECIMAL(9,4)[] AS prices
    FROM da_lmp
    WHERE hour_beginning >= '2025-07-01 00:00:00.000-04:00'
        AND hour_beginning <  '2025-07-15 00:00:00.000-04:00'
AND ptid in (4000, 4001) 
    GROUP BY date, ptid
    )
    SELECT 
        date,
        '{' || string_agg(ptid || ':' || to_json(prices), ',') || '}' AS map_json
    FROM per_ptid
    GROUP BY date
    ORDER BY date
);



--========================================================================
-- Pick only the 5x16 hours from the da_lmp table
ATTACH '~/Downloads/Archive/DuckDB/calendars/buckets.duckdb' AS buckets;

SELECT 
    da_lmp.*, 
    buckets.buckets.b5x16
FROM da_lmp 
JOIN buckets.buckets
    USING (hour_beginning)
WHERE ptid = 4000
AND hour_beginning >= '2025-07-01'
AND hour_beginning < '2025-07-02'
;

-- Calculate daily LMP for the 5x16 bucket
SELECT 
    date(hour_beginning) AS day,
    AVG(lmp)::DECIMAL(9,4) AS price
FROM da_lmp
JOIN buckets.buckets
    USING (hour_beginning)
WHERE ptid = 4000
AND hour_beginning >= '2025-07-01'
AND hour_beginning < '2025-07-31'
GROUP BY day, buckets.buckets."2x16h"
HAVING buckets.buckets."2x16h" = true
ORDER BY day;



-- Calculate monthly LMP for the 5x16 bucket
SELECT 
    date_trunc('month', hour_beginning) AS month_beginning,
    AVG(lmp) AS price
FROM da_lmp
JOIN buckets.buckets
    USING (hour_beginning)
WHERE ptid = 4000
AND hour_beginning >= '2020-01-01'
AND hour_beginning < '2025-10-01'
GROUP BY month_beginning, buckets.buckets."5x16"
HAVING buckets.buckets."5x16" = true
ORDER BY month_beginning;


-- Calculate LMP for one given term, say a couple of days, a couple of months, etc. 
-- and one ptid and bucket.
CREATE TEMPORARY TABLE terms (
    term VARCHAR NOT NULL,
    term_start TIMESTAMPTZ NOT NULL,
    term_end TIMESTAMPTZ NOT NULL
);
INSERT INTO terms VALUES
    ('Cal24', '2024-01-01', '2025-01-01'),
    ('Jul25', '2025-07-01', '2025-08-01'),
    ('Jul25-Aug25', '2025-08-01', '2025-09-01');

SELECT
  t.term,
  d.ptid,
  AVG(d.lmp)::DECIMAL(9,4) AS avg_price
FROM da_lmp d
JOIN terms t
  ON d.hour_beginning >= t.term_start
  AND d.hour_beginning < t.term_end
JOIN buckets.buckets b
  ON d.hour_beginning = b.hour_beginning
WHERE b."5x16" = true
  AND d.ptid IN (4000, 4001) -- add more ptids as needed
GROUP BY t.term, d.ptid
ORDER BY t.term, d.ptid;




--- Get hourly prices for several ptids in side by side columns
SELECT * FROM da_lmp
PIVOT (
    min(lmp),
    FOR ptid IN (4000, 4001)
    GROUP BY hour_beginning    
)
WHERE hour_beginning >= '2025-01-01'
AND hour_beginning < '2025-07-15'
ORDER BY hour_beginning;

--- same thing, using DuckDB PIVOT syntax
CREATE TEMPORARY TABLE tmp
AS (
    SELECT 
        hour_beginning,
        ptid,
        lmp,
    FROM da_lmp
    WHERE hour_beginning >= '2025-07-01'    
    AND hour_beginning < '2025-07-12'
    AND ptid IN (4000, 4001)
);
PIVOT tmp ON ptid USING min(lmp);




duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/isone/dalmp.duckdb' AS dalmp;
SELECT hour_beginning, lmp
FROM dalmp.da_lmp 
WHERE hour_beginning >= '2025-01-01'
AND hour_beginning < '2025-12-31'
AND ptid = 4000
ORDER BY hour_beginning;
" | qplot


curl 'http://localhost:8111/isone/dalmp/hourly/start/2025-07-01/end/2025-07-14?ptids=4000&components=lmp'




WITH unpivot_alias AS (
    UNPIVOT da_lmp
    ON lmp, mcc, mcl
    INTO 
        NAME component
        VALUE price
)
SELECT * FROM unpivot_alias
WHERE ptid = 4000
AND hour_beginning >= '2025-07-01'
AND hour_beginning < '2025-07-15'
ORDER BY component, ptid, hour_beginning; 

WITH unpivot_alias AS (
    UNPIVOT da_lmp
    ON lmp
    INTO
        NAME component
        VALUE price
)
SELECT 
    hour_beginning, 
    ptid,
    component,
    price
FROM unpivot_alias
WHERE hour_beginning >= '2025-07-01 00:00:00.000-04:00'
AND hour_beginning < '2025-07-15 00:00:00.000-04:00'
AND ptid in (4000) 
ORDER BY component, ptid, hour_beginning; 
    

---=========================================================================
--- Calculate daily average prices for a given ptid and component
---=========================================================================
WITH unpivot_alias AS (
    UNPIVOT da_lmp
    ON lmp
    INTO
        NAME component
        VALUE price
)
SELECT 
    component,
    ptid,
    hour_beginning::DATE AS day,
    'ATC' AS bucket,
    MEAN(price)::DECIMAL(9,4) AS price,
FROM unpivot_alias
WHERE hour_beginning >= '2025-07-01 00:00:00.000'
AND hour_beginning < '2025-07-15 00:00:00.000'
AND ptid in (4000) 
GROUP BY component, ptid, day
ORDER BY component, ptid, day; 


SELECT
    'lmp' AS component,
    ptid,
    hour_beginning::DATE AS day,
    'ATC' AS bucket,
    MEAN(lmp)::DECIMAL(9,4) AS price,
FROM da_lmp
WHERE hour_beginning >= '2025-07-01 00:00:00.000'
AND hour_beginning < '2025-07-15 00:00:00.000'
AND ptid in (4000) 
GROUP BY ptid, day
ORDER BY ptid, day;







---========================================================================
CREATE TABLE IF NOT EXISTS da_lmp (
    hour_beginning TIMESTAMPTZ NOT NULL,
    ptid UINTEGER NOT NULL,
    lmp DECIMAL(9,4) NOT NULL,
    mcc DECIMAL(9,4) NOT NULL,
    mcl DECIMAL(9,4) NOT NULL,
);

--- Some nodes have the same ptid but different names, see for example 2020-01-01 file for the 
--- node 321 and others.  Prices are the same, only the name is different!
--- That's why we do a DISTINCT to eliminate the multiple values. 
CREATE TEMPORARY TABLE tmp
AS
    SELECT 
        BeginDate::TIMESTAMPTZ AS hour_beginning,
        "@LocId"::UINTEGER AS ptid,
        LmpTotal::DECIMAL(9,4) AS "lmp",
        CongestionComponent::DECIMAL(9,4) AS "mcc",
        LossComponent::DECIMAL(9,4) AS "mcl" 
    FROM (
        SELECT DISTINCT BeginDate, "@LocId", LmpTotal, CongestionComponent, LossComponent FROM (
            SELECT unnest(HourlyLmps.HourlyLmp, recursive := true)
            FROM read_json('~/Downloads/Archive/IsoExpress/PricingReports/DaLmpHourly/Raw/2025/WW_DALMP_ISO_2025*.json.gz')
        )
    )
    ORDER BY hour_beginning, ptid
;

--SELECT * from tmp;

INSERT INTO da_lmp
(SELECT * FROM tmp 
WHERE NOT EXISTS (
    SELECT * FROM da_lmp d
    WHERE d.hour_beginning = tmp.hour_beginning
    AND d.ptid = tmp.ptid
    )
)
ORDER BY hour_beginning, ptid;



---==========================================================================
--- Try with a list of prices per day to see if you get any storage savings. 
--- There are some savings, but not that much!  
--- For example ingesting data for years 2020-2021 results in a 128 MB file 
--- on disk using the list approach and a 148 MB file on disk using the
--- standard hour_beginning approach. 
---==========================================================================
CREATE TABLE IF NOT EXISTS da_lmp (
    date DATE NOT NULL,
    ptid INT32 NOT NULL,
    lmp DECIMAL(9,4)[] NOT NULL,
    mcc DECIMAL(9,4)[] NOT NULL,
    mcl DECIMAL(9,4)[] NOT NULL,
);

--- Create a temporary table with hourly prices stored in lists
--- Some nodes have the same ptid but different names, see for example 2020-01-01 file for the 
--- node 321 and others.  Prices are the same, only the name is different!
--- That's why we do a DISTINCT to eliminate the multiple values. 
CREATE TEMPORARY TABLE tmp
AS
    SELECT 
        BeginDate[0:10]::DATE AS "date",
        "@LocId"::INTEGER AS ptid,
        list(LmpTotal ORDER BY BeginDate)::DECIMAL(9,4)[] AS "lmp",
        list(CongestionComponent ORDER BY BeginDate)::DECIMAL(9,4)[] AS "mcc",
        list(LossComponent ORDER BY BeginDate)::DECIMAL(9,4)[] AS "mcl" 
    FROM (
        SELECT DISTINCT BeginDate, "@LocId", LmpTotal, CongestionComponent, LossComponent FROM (
            SELECT unnest(HourlyLmps.HourlyLmp, recursive := true)
            FROM read_json('~/Downloads/Archive/IsoExpress/PricingReports/DaLmpHourly/Raw/2021/WW_DALMP_ISO_2021*.json.gz')
        )
    )
    GROUP BY "date", ptid
    ORDER BY "date", ptid
;
SELECT * from tmp;

--- Check that all the nodes have prices for all the hours.  Works for DST too because it 
--- does not check for a specific number, just that the count is the same for all dates. 
--- If the result of this query is not empty, it means that some nodes are missing prices 
--- for some hours.
SELECT * FROM (
    SELECT date, COUNT(*) == 1 AS all_hours 
    FROM (
        SELECT DISTINCT date, hours
        FROM (
            SELECT ptid, date, len(lmp) as hours
            FROM tmp
        )
        ORDER BY date
    )
    GROUP BY date
)
WHERE all_hours = false;




INSERT INTO da_lmp
(SELECT * FROM tmp 
WHERE NOT EXISTS (
    SELECT * FROM da_lmp d
    WHERE d.date = tmp.date
    AND d.ptid = tmp.ptid
    )
)
ORDER BY date, ptid;










---========================================================================

CREATE TABLE IF NOT EXISTS da_lmp (
    ptid UINTEGER NOT NULL,
    date DATE NOT NULL,
    hour UTINYINT NOT NULL,
    extraDstHour bool NOT NULL,
    lmp DECIMAL(9,4) NOT NULL,
    mcc DECIMAL(9,4) NOT NULL,
    mcl DECIMAL(9,4) NOT NULL,
);

--- Insert one year of data 
INSERT INTO da_lmp
FROM read_csv(
    '/home/adrian/Downloads/Archive/IsoExpress/PricingReports/DaLmpHourly/month/da_lmp_2023-*.csv.gz', 
    header = true, 
    dateformat = '%Y-%m-%d');

--- As of 9/1/2024 I've ingested years 2022-2023.  21M rows.
SELECT DISTINCT strftime(date, '%Y-%m') as month
FROM da_lmp
ORDER BY month;

SELECT COUNT(*) FROM rt_lmp;

--- 
CREATE TABLE nerc_holidays (
    date DATE NOT NULL,
);
INSERT INTO nerc_holidays
FROM read_csv(
    '/home/adrian/Downloads/Archive/Calendars/nerc_holidays.csv', 
    header = true, 
    dateformat = '%Y-%m-%d');

--- Calculate ATC prices
SELECT ptid, strftime(date, '%Y-%m') as YEARMON,  ROUND(AVG(lmp), 4) as lmp
FROM da_lmp
-- WHERE ptid = 4000
GROUP BY ptid, YEARMON
ORDER BY ptid, YEARMON
LIMIT 5;

--- Calculate 5x16 prices by stacking together two groups of rows:
--- 1) All weekdays with hours between 7-22 that are not nerc holidays
SELECT ptid, strftime(date, '%Y-%m') as YEARMON, COUNT(*) as hours_5x16, ROUND(AVG(lmp), 4) as lmp  
FROM da_lmp
-- WHERE ptid = 4000
WHERE date NOT IN (SELECT date FROM nerc_holidays)
AND dayofweek(da_lmp.date) in (1, 2, 3, 4, 5) 
AND hour BETWEEN 7 and 22
GROUP BY ptid, YEARMON
ORDER BY ptid, YEARMON
LIMIT 5;


--- Calculate 2x16H prices by stacking together two groups of rows:
--- 1) All weekends with hours between 7-22
--- 2) All nerc_holidays that are not on the weekend, with hours 7-22
SELECT ptid, strftime(date, '%Y-%m') as YEARMON, COUNT(*) as hours_2x16H, ROUND(AVG(lmp), 4) as lmp  
FROM (
    (SELECT * 
        FROM da_lmp
        WHERE ptid = 4000
        AND dayofweek(date) in (0, 6) 
        AND hour BETWEEN 7 AND 22
    )
        UNION
    (SELECT da_lmp.* 
        FROM da_lmp
        JOIN nerc_holidays
            ON da_lmp.date = nerc_holidays.date
        WHERE ptid = 4000
        AND dayofweek(da_lmp.date) in (1, 2, 3, 4, 5) 
        AND hour BETWEEN 7 AND 22
    )
)
GROUP BY ptid, YEARMON
ORDER BY ptid, YEARMON;

--- Calculate 7x8 prices 
--- 1) All days with hours between 0-6 and 23
SELECT ptid, strftime(date, '%Y-%m') as YEARMON, COUNT(*) as hours_7x8, ROUND(AVG(lmp), 4) as lmp  
FROM da_lmp
WHERE ptid = 4000
AND (hour < 7 OR hour = 23)
GROUP BY ptid, YEARMON
ORDER BY ptid, YEARMON;


SELECT ptid, date, hour, extraDstHour, lmp
FROM da_lmp
WHERE date >= '2022-01-01'
AND date <= '2022-01-31'
AND ptid in ('4000', '4001')
ORDER BY ptid, date, hour, extraDstHour;
