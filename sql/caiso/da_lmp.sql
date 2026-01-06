LOAD icu;SET TimeZone = 'America/Los_Angeles';
SELECT MIN(hour_beginning), MAX(hour_beginning), COUNT(*) FROM lmp;

SELECT DISTINCT strftime(hour_beginning, '%Y-%m') AS month 
FROM lmp 
WHERE node_id = 'TH_NP15_GEN-APND'
ORDER BY month;

SELECT * from lmp
SELECT * FROM read_vortex('lmp.vortex')
WHERE node_id = 'TH_NP15_GEN_ONPEAK-APND'
AND hour_beginning >= '2025-12-01T00:00:00-08:00'
ORDER BY hour_beginning;

-- WHERE node_id = 'TH_NP15_GEN-APND';

-- TH:  transmission holder
-- APND: Aggregated price node 
SELECT DISTINCT node_id 
FROM lmp
--WHERE node_id LIKE 'TH_%-APND'
WHERE hour_beginning = '2025-12-01T00:00:00-08:00'
ORDER BY node_id;

SELECT 
    hour_beginning::DATE AS day,
    AVG(lmp) AS avg_lmp
FROM lmp
WHERE node_id = 'TH_NP15_GEN_ONPEAK-APND'
GROUP BY day
ORDER BY day;

-- Get top 10 nodes by average daily LMP for each day
SELECT day, node_id, avg_price
FROM (
  SELECT
    strftime(hour_beginning, '%Y-%m-%d') AS day,
    node_id,
    ROUND(AVG(lmp), 2) AS avg_price,
    ROW_NUMBER() OVER (PARTITION BY strftime(hour_beginning, '%Y-%m-%d') ORDER BY AVG(lmp) DESC) AS rn
  FROM lmp
  GROUP BY day, node_id
)
WHERE rn <= 10
ORDER BY day, avg_price DESC;


duckdb -csv -c "
ATTACH 'C:/Data/DuckDB/caiso/dalmp.duckdb' AS dalmp;
LOAD icu;
SET TimeZone = 'America/Los_Angeles';
SELECT hour_beginning, lmp
FROM dalmp.lmp 
WHERE node_id = 'DUMBARTN_1_N001'
ORDER BY hour_beginning;
" | qplot


--- Get peak bucket prices
LOAD icu;SET TimeZone = 'America/Los_Angeles';
ATTACH '~/Downloads/Archive/DuckDB/calendars/buckets.duckdb' AS buckets;

SELECT
    node_id,
    hour_beginning::DATE AS day,
    mean(lmp)::DECIMAL(9,4) AS price,
FROM lmp
JOIN buckets.buckets 
    USING (hour_beginning)
WHERE hour_beginning >= '2025-12-01 00:00:00.000-08:00'
AND hour_beginning < '2025-12-05 00:00:00.000-08:00'
AND node_id in ('TH_NP15_GEN-APND','TH_SP15_GEN-APND') 
GROUP BY node_id, day, buckets.buckets."caiso_6x16"
HAVING buckets.buckets."caiso_6x16" = TRUE
ORDER BY node_id, day;


LOAD icu; SET TimeZone = 'America/Los_Angeles';

SELECT * FROM lmp LIMIT 10;

SELECT MIN(hour_beginning), MAX(hour_beginning), COUNT(*) FROM lmp;

SELECT DISTINCT node_id FROM lmp 
-- WHERE hour_beginning == '2025-12-06 00:00:00-08:00'
ORDER BY node_id;


-- https://oasis.caiso.com/oasisapi/SingleZip?resultformat=6&queryname=PRC_LMP&version=12&startdatetime=20251206T08:00-0000&enddatetime=20251207T08:00-0000&market_run_id=DAM&grp_type=ALL


---========================================================================
LOAD icu;
SET TimeZone = 'America/Los_Angeles';

CREATE TABLE IF NOT EXISTS lmp (
    node_id VARCHAR NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    lmp DECIMAL(18,5) NOT NULL,
    mcc DECIMAL(18,5) NOT NULL,
    mcl DECIMAL(18,5) NOT NULL,
);
CREATE INDEX IF NOT EXISTS idx_lmp_node_id ON lmp(node_id);

CREATE TEMPORARY TABLE tmp_lmp 
AS 
    SELECT 
        "NODE_ID"::STRING AS node_id,
        "INTERVALSTARTTIME_GMT"::STRING AS hour_beginning,
        "MW"::DECIMAL(18,5) as lmp
    FROM read_csv(
            '/home/adrian/Downloads/Archive/Caiso/DaLmp/Raw/2025/20251201_20251201_PRC_LMP_DAM_LMP_v12.csv.gz',
            header = true
    )
    ORDER BY node_id, hour_beginning 
;

CREATE TEMPORARY TABLE tmp_mcc 
AS 
    SELECT 
        "NODE_ID"::STRING AS node_id,
        "INTERVALSTARTTIME_GMT"::STRING AS hour_beginning,
        "MW"::DECIMAL(18,5) as mcc
    FROM read_csv(
            '/home/adrian/Downloads/Archive/Caiso/DaLmp/Raw/2025/20251201_20251201_PRC_LMP_DAM_MCC_v12.csv.gz',
            header = true
    )
    ORDER BY node_id, hour_beginning 
;

CREATE TEMPORARY TABLE tmp_mcl 
AS 
    SELECT 
        "NODE_ID"::STRING AS node_id,
        "INTERVALSTARTTIME_GMT"::STRING AS hour_beginning,
        "MW"::DECIMAL(18,5) as mcl
    FROM read_csv(
            '/home/adrian/Downloads/Archive/Caiso/DaLmp/Raw/2025/20251201_20251201_PRC_LMP_DAM_MCL_v12.csv.gz',
            header = true
    )
    ORDER BY node_id, hour_beginning 
;

CREATE TEMPORARY TABLE tmp 
AS
    SELECT 
        l.node_id,
        l.hour_beginning,
        l.lmp,
        m.mcc,
        c.mcl
    FROM tmp_lmp l
    JOIN tmp_mcc m
        ON l.node_id = m.node_id
        AND l.hour_beginning = m.hour_beginning
    JOIN tmp_mcl c
        ON l.node_id = c.node_id
        AND l.hour_beginning = c.hour_beginning
    ORDER BY l.node_id, l.hour_beginning;


INSERT INTO lmp
(
    SELECT * FROM tmp
    WHERE NOT EXISTS 
    (
        SELECT 1 FROM lmp 
        WHERE lmp.node_id = tmp.node_id 
        AND lmp.hour_beginning = tmp.hour_beginning
    )
);


---==========================================================================
--- Try with a list of prices per day to see if you get any storage savings. 
--- There are significant savings almost a factor of 5 smaller file on disk. 
---==========================================================================

ATTACH '~/Downloads/Archive/DuckDB/caiso/dalmp.duckdb' AS dalmp;
SELECT * FROM dalmp.lmp LIMIT 10;

CREATE TABLE IF NOT EXISTS lmp (
    date DATE NOT NULL,
    node_id VARCHAR NOT NULL,
    lmp DECIMAL(18,5)[] NOT NULL,
    mcc DECIMAL(18,5)[] NOT NULL,
    mcl DECIMAL(18,5)[] NOT NULL,
);

CREATE TEMPORARY TABLE tmp AS (
    SELECT 
        hour_beginning::DATE AS date,
        node_id,
        ARRAY_AGG(lmp ORDER BY hour_beginning) AS lmp,
        ARRAY_AGG(mcc ORDER BY hour_beginning) AS mcc,
        ARRAY_AGG(mcl ORDER BY hour_beginning) AS mcl
    FROM dalmp.lmp
    WHERE hour_beginning >= '2025-01-01T00:00:00-08:00'
    AND hour_beginning < '2026-01-01T00:00:00-08:00'
    GROUP BY node_id, date
    ORDER BY node_id, date
);

INSERT INTO lmp (
    SELECT * FROM tmp 
    WHERE NOT EXISTS (
        SELECT * FROM lmp d
        WHERE d.date = tmp.date
        AND d.node_id = tmp.node_id
        )
)
ORDER BY date, node_id;


LOAD vortex;
COPY (SELECT * FROM dalmp.lmp) TO './lmp.vortex' (FORMAT vortex);
