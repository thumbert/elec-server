SELECT * FROM gen_by_fuel
WHERE fuel_type = 'NUCLEAR';


--- Pivot the monthly usage by fuel type
WITH tmp AS (
    SELECT 
        strftime(hour_beginning, '%Y-%m') AS month, 
        fuel_type,
        ROUND(MEAN(mw),1) AS avg_mw
    FROM gen_by_fuel
    GROUP BY month, fuel_type
)
PIVOT tmp 
ON fuel_type
USING SUM(avg_mw)
ORDER BY month;



duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/ieso/generation_output_by_fuel.duckdb' AS g;
SELECT hour_beginning, mw
FROM g.gen_by_fuel
WHERE fuel_type = 'HYDRO'
ORDER BY hour_beginning;
" | qplot


duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/ieso/generation_output_by_fuel.duckdb' AS g;
WITH tmp AS (
    SELECT 
        strftime(hour_beginning, '%Y-%m') AS month, 
        fuel_type,
        ROUND(MEAN(mw),1) AS avg_mw
    FROM g.gen_by_fuel
    GROUP BY month, fuel_type
)
PIVOT tmp 
ON fuel_type
USING SUM(avg_mw)
ORDER BY month;
" | qplot




---=============================================================================================
-- Not using a timezone anymore because America/Cancun does not work before 2015.
-- DuckDB does not support time zones with a fixed offset as of 9/2025.
--
CREATE TABLE IF NOT EXISTS gen_by_fuel (
    hour_beginning TIMESTAMP NOT NULL,    
    fuel_type ENUM('NUCLEAR', 'GAS', 'HYDRO', 'WIND', 'SOLAR', 'BIOFUEL', 'OTHER') NOT NULL,
    output_quality INT1 NOT NULL,
    mw UINT16,
);

CREATE TEMPORARY TABLE tmp
AS
    SELECT 
        hour_beginning, fuel_type, output_quality, mw
    FROM read_csv('/home/adrian/Downloads/Archive/Ieso/GenerationOutputByFuel/year/PUB_GenOutputbyFuelHourly_2015.csv.gz', 
    columns = {
        'hour_beginning': "TIMESTAMP NOT NULL",
        'fuel_type': "VARCHAR NOT NULL",
        'output_quality': "INT1 NOT NULL",
        'mw': "UINT16"
        }
    )
;

SELECT * FROM tmp WHERE fuel_type = 'NUCLEAR';

INSERT INTO gen_by_fuel BY NAME
(SELECT * FROM tmp 
WHERE NOT EXISTS (
    SELECT * FROM gen_by_fuel d
    WHERE d.hour_beginning = tmp.hour_beginning
    AND d.fuel_type = tmp.fuel_type
    )
)
ORDER BY hour_beginning, fuel_type;


