
SELECT MIN(start_15min), MAX(start_15min), COUNT(*)
FROM total_demand;

SELECT *
FROM total_demand
WHERE start_15min >= '2026-01-01T00:00:00'
    AND start_15min <  '2026-01-02T00:00:00'
ORDER BY start_15min;

SELECT *
FROM total_demand_prelim
WHERE zoned >= '2026-01-01T00:00:00'
    AND zoned <  '2026-01-02T00:00:00'
ORDER BY zoned;



SELECT
    td.start_15min,
    td.value       AS demand_final,
    tdp.value      AS demand_prelim,
    (td.value - tdp.value) AS diff
FROM total_demand td
JOIN total_demand_prelim tdp
    ON td.start_15min = tdp.zoned
WHERE td.start_15min >= '2026-01-01T00:00:00'
    AND td.start_15min <  '2026-01-02T00:00:00'
ORDER BY td.start_15min;





SELECT
    td.date,
    td.value AS total_demand,
    tdp.value AS total_demand_prelim
FROM
    total_demand td
JOIN
    total_demand_prelim tdp
SELECT
    td.start_15min,
    td.value AS demand_final,
    tdp.value AS demand_prelim
FROM
    total_demand td
JOIN
    total_demand_prelim tdp
ON
    td.date = tdp.date;



duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/hq/total_demand.duckdb' AS g;
SELECT start_15min, value
FROM g.total_demand
ORDER BY start_15min;
" | qplot




SELECT * FROM total_demand_prelim
ORDER BY zoned;

SELECT MAX(value) as max_demand
FROM total_demand_prelim
WHERE zoned >= CURRENT_TIMESTAMP::TIMESTAMPTZ - INTERVAL '1 days';


duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/hq/total_demand.duckdb' AS g;
SELECT zoned, value
FROM g.total_demand_prelim
ORDER BY zoned;
" | qplot




---==================================================================================
---  HQ Total Demand
---==================================================================================


CREATE TABLE IF NOT EXISTS total_demand (
    start_15min TIMESTAMPTZ NOT NULL,
    value DECIMAL(9,2) NOT NULL,
);

CREATE TEMPORARY TABLE tmp
AS
    SELECT 
       time::TIMESTAMPTZ AS start_15min,
       demand::DECIMAL(9,2) AS value
    FROM (
        SELECT time, demand
        FROM read_json('~/Downloads/Archive/HQ/TotalDemand/Raw/2024/demand_2024-03.json.gz')
    )
    WHERE value IS NOT NULL
    ORDER BY start_15min
;


INSERT INTO total_demand
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM total_demand d
        WHERE
            d.start_15min = t.start_15min AND
            d.value = t.value
    )
) ORDER BY start_15min; 

