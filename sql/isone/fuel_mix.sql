SELECT * FROM fuel_mix LIMIT 3;

SELECT COUNT(*) FROM fuel_mix;



SELECT DISTINCT fuel_category_rollup, fuel_category
FROM fuel_mix
ORDER BY fuel_category_rollup, fuel_category;

SELECT timestamp, mw 
FROM fuel_mix
WHERE fuel_category = 'Oil';

SELECT MIN(timestamp), MAX(timestamp)
FROM fuel_mix;

--- Aggregate to hourly level
SELECT date_trunc('hour', timestamp) AS hour, 
    MIN(mw) AS min_mw,
    MAX(mw) AS max_mw,
    AVG(mw) AS avg_mw
FROM fuel_mix
WHERE fuel_category = 'Oil'
GROUP BY hour
ORDER BY hour;


duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/isone/fuelmix.duckdb' AS fm;
SELECT timestamp, mw
FROM fm.fuel_mix 
WHERE timestamp >= '2025-01-01'
AND timestamp < '2025-12-31'
AND fuel_category = 'Oil'
ORDER BY timestamp;
" | qplot



---========================================================================
CREATE TABLE IF NOT EXISTS fuel_mix (
    timestamp TIMESTAMPTZ,
    mw INT32,
    fuel_category_rollup ENUM('Batteries', 'Coal', 'Hydro', 'Natural Gas', 'Nuclear', 'Oil',  'Other', 'Renewables'),
    fuel_category ENUM('Batteries', 'Coal', 'Hydro', 'Landfill Gas', 'Natural Gas', 'Nuclear', 'Oil', 'Other', 'Refuse', 'Solar', 'Wind', 'Wood'),
    marginal_flag BOOL
);

CREATE TEMPORARY TABLE tmp
AS
    SELECT 
        BeginDate::TIMESTAMPTZ as timestamp, 
        GenMw:: INT32 as mw, 
        FuelCategoryRollup:: VARCHAR AS fuel_category_rollup, 
        FuelCategory::VARCHAR AS fuel_category,
        CASE MarginalFlag 
            WHEN 'Y' THEN TRUE
            WHEN 'N' THEN FALSE
            ELSE NULL
        END AS marginal_flag
        FROM (
            SELECT unnest(GenFuelMixes.GenFuelMix, recursive := true)
            FROM read_json('~/Downloads/Archive/IsoExpress/GridReports/FuelMix/Raw/2026/genfuelmix_20260514.json.gz',
              timestampformat := '%Y-%m-%dT%H:%M:%S%z')
    )
    ORDER BY timestamp, fuel_category
;

INSERT INTO fuel_mix
(SELECT * FROM tmp 
WHERE NOT EXISTS (
    SELECT * FROM fuel_mix d
    WHERE d.timestamp = tmp.timestamp
    AND d.fuel_category = tmp.fuel_category
    AND d.mw = tmp.mw
    )
)
ORDER BY timestamp, fuel_category;


-- DROP TYPE fuel_category_rollup;
ALTER TABLE fuel_mix ALTER COLUMN fuel_category_rollup TYPE VARCHAR;
CREATE TYPE fuel_category_rollup AS ENUM ('Batteries', 'Coal', 'Hydro', 'Natural Gas', 'Nuclear', 'Oil', 'Other', 'Renewables'); 
ALTER TABLE fuel_mix ALTER COLUMN fuel_category_rollup TYPE fuel_category_rollup;


ALTER TABLE fuel_mix ALTER COLUMN fuel_category TYPE VARCHAR;
CREATE TYPE fuel_category AS ENUM ('Batteries', 'Coal', 'Hydro', 'Landfill Gas', 'Natural Gas', 'Nuclear', 'Oil', 'Other', 'Refuse', 'Solar', 'Wind', 'Wood'); 
ALTER TABLE fuel_mix ALTER COLUMN fuel_category TYPE fuel_category;