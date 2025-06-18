
SELECT min(hour_beginning), max(hour_beginning) FROM dalmp;

SELECT COUNT(DISTINCT(ptid)) FROM dalmp WHERE day = '2020-01-01'; -- 574 nodes 

SELECT *
FROM dalmp
WHERE hour_beginning >= '2025-06-17'
AND hour_beginning < '2025-06-18'
AND ptid = 61757
ORDER BY hour_beginning;




--- =========================================================================================
--- Create and update the table (version 2) -- Active
--- Data from 2020-01 to 2025-05 was 935 MB on disk
--- =========================================================================================
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

CREATE TEMPORARY TABLE tmp AS
(SELECT day + INTERVAL (idx) HOUR AS hour_beginning, ptid, lmp, mlc, mcc
FROM (
    SELECT 
    strptime("Time Stamp"[0:10], '%m/%d/%Y')::TIMESTAMPTZ AS "day",
    ptid::INTEGER AS ptid,
    row_number() OVER (PARTITION BY ptid, strptime("Time Stamp"[0:10], '%m/%d/%Y')) - 1 AS idx, -- 0 to 23 for each day
    "LBMP ($/MWHr)"::DECIMAL(9,2) AS "lmp",
    "Marginal Cost Losses ($/MWHr)"::DECIMAL(9,2) AS "mlc",
    "Marginal Cost Congestion ($/MWHr)"::DECIMAL(9,2) AS "mcc"
FROM tmp1))
UNION
(SELECT day + INTERVAL (idx) HOUR AS hour_beginning, ptid, lmp, mlc, mcc
FROM (SELECT 
    strptime("Time Stamp"[0:10], '%m/%d/%Y')::TIMESTAMPTZ AS "day",
    ptid::INTEGER AS ptid,
    row_number() OVER (PARTITION BY ptid, strptime("Time Stamp"[0:10], '%m/%d/%Y')) - 1 AS idx, -- 0 to 23 for each day
    "LBMP ($/MWHr)"::DECIMAL(9,2) AS "lmp",
    "Marginal Cost Losses ($/MWHr)"::DECIMAL(9,2) AS "mlc",
    "Marginal Cost Congestion ($/MWHr)"::DECIMAL(9,2) AS "mcc"
FROM tmp2));


INSERT INTO dalmp
SELECT hour_beginning, ptid, lmp, mlc, mcc FROM tmp
EXCEPT 
    SELECT * FROM dalmp            
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



    SELECT ptid, day, idx, lmp
    FROM dalmp 
    WHERE day >= '2024-11-03'
    AND day <= '2024-11-04'
    AND ptid in (61752)
    ORDER BY ptid, day, idx;

CREATE TEMPORARY TABLE tmp1 AS SELECT * FROM 'zip:///home/adrian/Downloads/Archive/Nyiso/DaLmpHourly/Raw/20241101damlbmp_zone_csv.zip/*.csv';
SELECT * from tmp1
WHERE ptid = 61752
and "Time Stamp" like '11/03/2024 %';

--- FIRE !!! ---
SELECT day + INTERVAL (idx) HOUR AS hour_beginning, ptid, lmp, mlc, mcc
FROM (
    SELECT 
        strptime("Time Stamp"[0:10], '%m/%d/%Y')::TIMESTAMPTZ AS "day",
        ptid::INTEGER AS ptid,
        row_number() OVER (PARTITION BY ptid, strptime("Time Stamp"[0:10], '%m/%d/%Y')) - 1 AS idx, -- 0 to 23 for each day
        "LBMP ($/MWHr)"::DECIMAL(9,2) AS "lmp",
        "Marginal Cost Losses ($/MWHr)"::DECIMAL(9,2) AS "mlc",
        "Marginal Cost Congestion ($/MWHr)"::DECIMAL(9,2) AS "mcc"
    FROM tmp1
    WHERE ptid = 61752
    AND day = '2024-11-03'
);



SELECT * from tmp
WHERE ptid = 61752
AND day = '2024-11-03';

SELECT *, dt + INTERVAL 1 HOUR AS dt2, dt + INTERVAL 2 HOUR AS dt3
FROM (
    SELECT '2024-11-03'::TIMESTAMPTZ as dt
);



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
        


