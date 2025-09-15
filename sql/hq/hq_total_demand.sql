SELECT * from total_demand_final
WHERE hour_beginning >= '2019-01-31'
LIMIT 40;



SELECT * from total_demand_prelim
ORDER BY zoned;


---==================================================================================
---  HQ Total Demand
---==================================================================================
CREATE TABLE IF NOT EXISTS total_demand (
    zoned TIMESTAMPTZ NOT NULL,
    value DECIMAL(9,2) NOT NULL,
);

CREATE TEMPORARY TABLE tmp
AS
    SELECT 
       date::TIMESTAMPTZ AS zoned,
       valeurs_demandetotal::DECIMAL(9,2) AS value
    FROM (
        SELECT unnest(results, recursive := true)
        FROM read_json('~/Downloads/Archive/HQ/TotalDemand/Raw/2025/total_demand_2025-09-15.json.gz')
    )
    WHERE value IS NOT NULL
    ORDER BY zoned
;


INSERT INTO total_demand
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM total_demand d
        WHERE
            d.zoned = t.zoned AND
            d.value = t.value
    )
) ORDER BY zoned; 

