SELECT * FROM flows;

WITH unpivot_alias AS (
    UNPIVOT flows
    ON net, purchase, sale
    INTO
        NAME component
        VALUE "value"
)
SELECT 
    hour_beginning, 
    ptid,
    component,
    "value"
FROM unpivot_alias
WHERE hour_beginning >= '2025-07-01 00:00:00.000-04:00'
AND hour_beginning < '2025-07-15 00:00:00.000-04:00'
AND ptid in (4010)
ORDER BY component, ptid, hour_beginning; 



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

CREATE TABLE IF NOT EXISTS flows (
    hour_beginning TIMESTAMPTZ NOT NULL,
    ptid UINTEGER NOT NULL,
    Net DECIMAL(9,2) NOT NULL,
    Purchase DECIMAL(9,2) NOT NULL,
    Sale DECIMAL(9,2) NOT NULL,
);


CREATE TEMPORARY TABLE tmp AS
    SELECT 
        BeginDate::TIMESTAMPTZ AS hour_beginning,
        "@LocId"::UINTEGER AS ptid,
        ActInterchange::DECIMAL(9,2) AS Net,
        Purchase::DECIMAL(9,2) AS Purchase,
        Sale::DECIMAL(9,2) AS Sale
    FROM (
        SELECT unnest(ActualInterchanges.ActualInterchange, recursive := true)
        FROM read_json('~/Downloads/Archive/IsoExpress/ActualInterchange/Raw/2025/act_interchange_2025*.json.gz')
    )
ORDER BY hour_beginning, ptid
;
-- SELECT * from tmp;

INSERT INTO flows
(SELECT * FROM tmp 
WHERE NOT EXISTS (
    SELECT * FROM flows d
    WHERE d.hour_beginning = tmp.hour_beginning
    AND d.ptid = tmp.ptid
    )
)
ORDER BY hour_beginning, ptid;


