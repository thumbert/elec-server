
SELECT min(hour_beginning), max(hour_beginning) FROM dalmp;

SELECT COUNT(DISTINCT(ptid)) FROM dalmp WHERE day = '2020-01-01'; -- 574 nodes 

SELECT *
FROM dalmp
WHERE hour_beginning >= '2025-10-08'
AND hour_beginning < '2025-10-09'
AND ptid IN (61754, 23575)
ORDER BY hour_beginning;

--- Check DST. The first 3 LMP values should be [29.27, 27.32, 27.14]
SELECT * FROM g
WHERE hour_beginning >= '2024-11-03'
AND hour_beginning < '2024-11-04'
AND ptid = 61752
ORDER BY hour_beginning;


--- Create a compact json string by hand:  
--- {"2025-07-01": {"4000":[...],"4001":[...]}, "2025-07-02":{...} ...}
SELECT '{' || string_agg('"' || date || '":' || map_json, ',') || '}' AS out
FROM (
    WITH per_ptid AS (
    SELECT
        strftime(hour_beginning, '%Y-%m-%d') AS date,
        ptid,
        list(mcc ORDER BY hour_beginning)::DECIMAL(9,4)[] AS prices
    FROM dalmp
    WHERE hour_beginning >= '2025-07-01 00:00:00.000-04:00'
        AND hour_beginning <  '2025-07-15 00:00:00.000-04:00'
AND ptid in (61754, 23575) 
    GROUP BY date, ptid
    )
    SELECT 
        date,
        '{' || string_agg(ptid || ':' || to_json(prices), ',') || '}' AS map_json
    FROM per_ptid
    GROUP BY date
    ORDER BY date
);



SELECT 
    '2024-11-03 00:00:00-04:00'::TIMESTAMPTZ AS H0, 
    '2024-11-03 00:00:00-04:00'::TIMESTAMPTZ  + INTERVAL(1) HOUR AS H1, 
    '2024-11-03 00:00:00-04:00'::TIMESTAMPTZ  + INTERVAL(2) HOUR AS H2, 
    '2024-11-03 00:00:00-04:00'::TIMESTAMPTZ  + INTERVAL(3) HOUR AS H3, 
;


--- =========================================================================================
--- Create and update the table (version 2) -- Active
--- Data from 2020-01 to 2025-05 was 935 MB on disk
--- =========================================================================================
DROP TABLE IF EXISTS dalmp;
CREATE TABLE IF NOT EXISTS dalmp (
    hour_beginning TIMESTAMPTZ NOT NULL,
    ptid INTEGER NOT NULL,
    lmp DECIMAL(9,2) NOT NULL,
    mlc DECIMAL(9,2) NOT NULL,
    mcc DECIMAL(9,2) NOT NULL,
);

LOAD zipfs;    
CREATE TEMPORARY TABLE tmp1 AS SELECT * FROM 'zip:///home/adrian/Downloads/Archive/Nyiso/DaLmpHourly/Raw/20241101damlbmp_zone_csv.zip/*.csv';
CREATE TEMPORARY TABLE tmp2 AS SELECT * FROM 'zip:///home/adrian/Downloads/Archive/Nyiso/DaLmpHourly/Raw/20241101damlbmp_gen_csv.zip/*.csv';

--- NOTE: this messes up the ordering on the fall DST days. The two hour 1:00 AMs will be in the wrong order! 
DROP TABLE IF EXISTS tmp;
CREATE TEMPORARY TABLE tmp AS
(SELECT 
    strptime("Time Stamp" || ' America/New_York' , '%m/%d/%Y %H:%M %Z')::TIMESTAMPTZ AS "hour_beginning",
    ptid::INTEGER AS ptid,
    "LBMP ($/MWHr)"::DECIMAL(9,2) AS "lmp",
    "Marginal Cost Losses ($/MWHr)"::DECIMAL(9,2) AS "mlc",
    "Marginal Cost Congestion ($/MWHr)"::DECIMAL(9,2) AS "mcc"
FROM tmp1
)
UNION 
(
SELECT day + INTERVAL (idx) HOUR AS hour_beginning, ptid, lmp, mlc, mcc
FROM (
    SELECT 
        strptime("Time Stamp"[0:10], '%m/%d/%Y')::TIMESTAMPTZ AS "day",
        ptid::INTEGER AS ptid,
        row_number() OVER (
            PARTITION BY ptid, strptime("Time Stamp"[0:10], '%m/%d/%Y')
            ORDER BY strptime("Time Stamp", '%m/%d/%Y %H:%M')) - 1 AS idx, -- 0 to 23 for each day
        "LBMP ($/MWHr)"::DECIMAL(9,2) AS "lmp",
        "Marginal Cost Losses ($/MWHr)"::DECIMAL(9,2) AS "mlc",
        "Marginal Cost Congestion ($/MWHr)"::DECIMAL(9,2) AS "mcc"
    FROM tmp2
    )
)
ORDER BY hour_beginning, ptid;


DROP TABLE IF EXISTS g;
CREATE TEMPORARY TABLE g AS
(
SELECT day + INTERVAL (idx) HOUR AS hour_beginning, ptid, lmp, mlc, mcc
FROM (
    SELECT 
        strptime("Time Stamp"[0:10], '%m/%d/%Y')::TIMESTAMPTZ AS "day",
        ptid::INTEGER AS ptid,
        row_number() OVER (
            PARTITION BY ptid, strptime("Time Stamp"[0:10], '%m/%d/%Y')
            ORDER BY strptime("Time Stamp", '%m/%d/%Y %H:%M')) - 1 AS idx, -- 0 to 23 for each day
        "LBMP ($/MWHr)"::DECIMAL(9,2) AS "lmp",
        "Marginal Cost Losses ($/MWHr)"::DECIMAL(9,2) AS "mlc",
        "Marginal Cost Congestion ($/MWHr)"::DECIMAL(9,2) AS "mcc"
    FROM tmp1
    )
)
ORDER BY hour_beginning, ptid;

SELECT *
FROM g
WHERE hour_beginning >= '2025-10-08'
AND hour_beginning < '2025-10-09'
AND ptid IN (61754, 23575)
ORDER BY hour_beginning;




INSERT INTO dalmp
(SELECT hour_beginning, ptid, lmp, mlc, mcc FROM tmp
WHERE NOT EXISTS (
    SELECT * FROM dalmp d
    WHERE d.hour_beginning = tmp.hour_beginning
    AND d.ptid = tmp.ptid
))
ORDER BY hour_beginning, ptid;


SELECT * FROM dalmp 
WHERE ptid = 61752
AND hour_beginning >= '2024-11-03 00:00:00' 
AND hour_beginning < '2024-11-04 00:00:00' 
ORDER BY hour_beginning;




SELECT *
FROM dalmp 
WHERE ptid = 61752
AND hour_beginning >= '2024-11-03' 
AND hour_beginning < '2024-11-04' 
ORDER BY hour_beginning;





--- =========================================================================================
--- Create and update the table (version 1) -- Abandoned because Rust/Dart can't read arrays
--- Data from 2020-01 to 2025-05 was 187 MB on disk
--- =========================================================================================
CREATE TABLE IF NOT EXISTS dalmp (
    day DATE NOT NULL,
    ptid INTEGER NOT NULL,
    lmp DECIMAL(9,2)[] NOT NULL,
    mcc DECIMAL(9,2)[] NOT NULL,
    mcl DECIMAL(9,2)[] NOT NULL,
);


LOAD zipfs;    
CREATE TEMPORARY TABLE tmp1 AS SELECT * FROM 'zip:///home/adrian/Downloads/Archive/Nyiso/DaLmpHourly/Raw/20200101damlbmp_zone_csv.zip/*.csv';
CREATE TEMPORARY TABLE tmp2 AS SELECT * FROM 'zip:///home/adrian/Downloads/Archive/Nyiso/DaLmpHourly/Raw/20200101damlbmp_gen_csv.zip/*.csv';

--- Transpose the data
CREATE TEMPORARY TABLE tmp_w AS
(SELECT 
    strptime("Time Stamp"[0:10], '%m/%d/%Y')::DATE AS "day",
    ptid::INTEGER AS ptid,
    list("LBMP ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "lmp",
    list("Marginal Cost Losses ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "mlc",
    list("Marginal Cost Congestion ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "mcc",
FROM tmp1
GROUP BY day, ptid
ORDER BY day, ptid)
UNION
(SELECT 
    strptime("Time Stamp"[0:10], '%m/%d/%Y')::DATE AS "day",
    ptid::INTEGER AS ptid,
    list("LBMP ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "lmp",
    list("Marginal Cost Losses ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "mlc",
    list("Marginal Cost Congestion ($/MWHr)" ORDER BY "Time Stamp")::DECIMAL(9,2)[] AS "mcc",
FROM tmp2
GROUP BY day, ptid
ORDER BY day, ptid)
;    
-- SELECT Day, Ptid, LMP FROM tmp_w WHERE ptid = 61757;
-- SELECT day, ptid, lmp FROM tmp_w WHERE day = '2020-01-01' ORDER BY ptid;

INSERT INTO dalmp
SELECT day, ptid, lmp, mlc, mcc FROM tmp_w
EXCEPT 
    SELECT * FROM dalmp;            
        


