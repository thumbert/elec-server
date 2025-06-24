SELECT * FROM ttc_limits;

SELECT hour_beginning, hq_phase2_import
FROM ttc_limits 
WHERE hour_beginning >= '2024-01-01'
AND hour_beginning < '2024-01-05'
ORDER BY hour_beginning;


duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/isone/ttc.duckdb' AS ttc;
SELECT hour_beginning, hq_phase2_import
FROM ttc.ttc_limits 
WHERE hour_beginning >= '2024-01-01'
AND hour_beginning < '2024-01-05'
ORDER BY hour_beginning;
" | qplot






---========================================================================

CREATE TABLE IF NOT EXISTS ttc_limits (
    hour_beginning TIMESTAMPTZ NOT NULL,
    ny_north_import int64 NOT NULL,
    ny_north_export int64 NOT NULL,
    ny_northport_import int64 NOT NULL,
    ny_northport_export int64 NOT NULL,
    ny_csc_import int64 NOT NULL,
    ny_csc_export int64 NOT NULL,
    nb_import int64 NOT NULL,
    nb_export int64 NOT NULL,
    hq_highgate_import int64 NOT NULL,
    hq_highgate_export int64 NOT NULL,
    hq_phase2_import int64 NOT NULL,
    hq_phase2_export int64 NOT NULL,
);


CREATE TEMPORARY TABLE tmp1 
AS 
SELECT column01 AS Day,
    column03 AS ny_north_import,
    column04 AS	ny_north_export,
    column05 AS	ny_northport_import,
    column06 AS ny_northport_export,
    column07 AS	ny_csc_import,
    column08 AS	ny_csc_export,
    column09 AS	nb_import,
    column10 AS	nb_export,
    column11 AS	hq_highgate_import,
    column12 AS	hq_highgate_export,
    column13 AS	hq_phase2_import,
    column14 AS	hq_phase2_export,
FROM read_csv('/home/adrian/Downloads/Archive/IsoExpress/Ttc/Raw/2024/ttc_202401*.csv.gz', 
    header = false, 
    skip = 6,
    ignore_errors = true,
    strict_mode = false,
    dateformat = '%m/%d/%Y');


CREATE TEMPORARY TABLE tmp AS
(SELECT day + INTERVAL (idx) HOUR AS hour_beginning, 
    * EXCLUDE (day, idx)
FROM (
    SELECT         
        row_number() OVER (PARTITION BY day) - 1 AS idx, -- 0 to 23 for each day
        *
    FROM tmp1
    )
ORDER BY hour_beginning    
);


INSERT INTO ttc_limits
(SELECT * FROM tmp t
WHERE NOT EXISTS (
    SELECT * FROM ttc_limits b
    WHERE
        b.hour_beginning = t.hour_beginning 
    )    
)
ORDER BY hour_beginning;
