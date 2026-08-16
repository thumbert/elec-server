SELECT * FROM ttc_limits;

SELECT hour_beginning, mw
FROM ttc_limits 
WHERE interface_name = 'HydroQuebec Phase II'
AND flow_direction = 'import'
AND hour_beginning >= '2024-01-01'
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
    interface_name VARCHAR NOT NULL,
    flow_direction ENUM('import', 'export') NOT NULL,
    mw int64 NOT NULL,
    PRIMARY KEY (hour_beginning, interface_name, flow_direction)
);

CREATE TEMPORARY TABLE tmp AS
WITH source AS (
    SELECT
        *,
        row_number() OVER (PARTITION BY Day) - 1 AS hour_index
    FROM read_csv(
        '/home/adrian/Downloads/Archive/IsoExpress/Ttc/Raw/2026/ttc_2026*.csv.gz',
        header = true,
        skip = 4,
        delim = ',',
        quote = '"',
        escape = '"',
        ignore_errors = true,
        all_varchar = true
    )
    WHERE H = 'D'
), long_limits AS (
    UNPIVOT source
    ON COLUMNS(* EXCLUDE (H, Day, "Hour Ending", hour_index))
    INTO NAME limit_name VALUE mw
)
SELECT
    (strptime(Day, '%m/%d/%Y') AT TIME ZONE 'America/New_York')
        + hour_index * INTERVAL '1 hour'
        AS hour_beginning,
    trim(regexp_replace(limit_name, '\s+(Import|Export) Limit MW\s*$', ''))
        AS interface_name,
    lower(regexp_extract(limit_name, '(Import|Export) Limit MW\s*$', 1))
        AS flow_direction,
    CAST(mw AS BIGINT) AS mw
FROM long_limits;

--- tmp values overwrite existing values in ttc_limits table (upsert)
INSERT INTO ttc_limits
SELECT t.*
FROM tmp t
ORDER BY hour_beginning, interface_name, flow_direction
ON CONFLICT (hour_beginning, interface_name, flow_direction)
DO UPDATE SET mw = EXCLUDED.mw;
