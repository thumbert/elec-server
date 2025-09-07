-- Note, the correct timezone for IESO is America/Cancun! 
-- Wikipedia recommends using America/Cancun as the timezone that respects -05:00 
-- offset year long.
SET TimeZone = 'America/Cancun';



SELECT DISTINCT location_type, location_name
FROM da_lmp
ORDER BY location_type, location_name;

SELECT location_type, COUNT(DISTINCT location_name) AS count
FROM da_lmp
GROUP BY location_type;
-- ┌─────────────────────────────┬───────┐
-- │        location_type        │ count │
-- │ enum('area', 'hub', 'node') │ int64 │
-- ├─────────────────────────────┼───────┤
-- │ AREA                        │     1 │
-- │ NODE                        │  1025 │
-- │ HUB                         │     9 │
-- └─────────────────────────────┴───────┘


--- this is the entire Ontario area price
SELECT * 
FROM da_lmp
WHERE location_name = 'ONTARIO_ZONAL_PRICE_REF'
AND hour_beginning >= '2025-08-31 00:00:00.000-05:00'
AND hour_beginning < '2025-09-01 00:00:00.000-05:00'
;


-- note the fixed timezone offset 
SELECT * 
FROM da_lmp
WHERE location_name = 'TORONTO'
AND hour_beginning >= '2025-08-31 00:00:00.000-05:00'
AND hour_beginning < '2025-09-01 00:00:00.000-05:00'
;

SELECT * 
FROM da_lmp
WHERE location_name = 'GREENFIELD-LT.G1'
AND hour_beginning >= '2025-08-31 00:00:00.000-05:00'
AND hour_beginning < '2025-09-01 00:00:00.000-05:00'
;


duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/ieso/da_lmp.duckdb' AS dalmp;
SELECT hour_beginning, lmp
FROM dalmp.da_lmp 
WHERE hour_beginning >= '2025-06-01'
AND hour_beginning < '2025-12-31'
AND location_name = 'GREENFIELD-LT.G1'
ORDER BY hour_beginning;
" | qplot


------------------------------------------------------------------------
-- get daily prices  
------------------------------------------------------------------------
SET TimeZone = 'America/Cancun';
SELECT 
    location_name, 
    hour_beginning::DATE AS day, 
    'ATC' AS bucket,
    MEAN(lmp) AS lmp 
FROM da_lmp
WHERE location_name = 'TORONTO'
AND hour_beginning >= '2025-08-31 00:00:00.000-05:00'
AND hour_beginning < '2025-09-01 00:00:00.000-05:00'
GROUP BY location_name, day
ORDER BY location_name, day;



WITH unpivot_alias AS (
    UNPIVOT da_lmp
    ON lmp
    INTO
        NAME component
        VALUE price
)
SELECT 
    component,
    location_name,
    hour_beginning::DATE AS day,
    'ATC' AS bucket,
    MEAN(price)::DECIMAL(9,4) AS price
FROM unpivot_alias
WHERE hour_beginning >= '2025-08-31 00:00:00.000-05:00'
AND hour_beginning < '2025-09-04 00:00:00.000-05:00'
AND location_name in ('TORONTO') 
GROUP BY component, location_name, day
ORDER BY component, location_name, day; 
    


------------------------------------------------------------------------
-- get prices in wide format, one row for all hours of the day 
------------------------------------------------------------------------
SET TimeZone = 'America/Cancun';
SELECT 
    location_name, 
    hour_beginning::DATE AS day, 
    list(lmp ORDER BY hour_beginning) AS lmp 
FROM da_lmp
WHERE location_name = 'TORONTO'
AND hour_beginning >= '2025-09-01 00:00:00.000-05:00'
AND hour_beginning < '2025-09-03 00:00:00.000-05:00'
GROUP BY location_name, day
ORDER BY location_name, day;






---==================================================================================================
--- For the zonal prices 
CREATE TABLE IF NOT EXISTS da_lmp (
    location_type ENUM('AREA', 'HUB', 'NODE') NOT NULL,
    location_name VARCHAR NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    lmp DECIMAL(9,4) NOT NULL,
    mcc DECIMAL(9,4) NOT NULL,
    mcl DECIMAL(9,4) NOT NULL,
);

CREATE TEMPORARY TABLE tmp_z
AS
    SELECT location_type, location_name, hour_beginning, lmp, mcc, mcl
    FROM read_csv('/home/adrian/Downloads/Archive/Ieso/DaLmp/Zone/month/zonal_da_prices_2025-06.csv.gz', 
    columns = {
        'location_type': "ENUM('HUB', 'NODE') NOT NULL",
        'location_name': "VARCHAR NOT NULL",
        'hour_beginning': "TIMESTAMPTZ NOT NULL",
        'lmp': "DECIMAL(9,4) NOT NULL",
        'mcc': "DECIMAL(9,4) NOT NULL",
        'mcl': "DECIMAL(9,4) NOT NULL"
        }
    )
;

INSERT INTO da_lmp
(SELECT * FROM tmp_z 
WHERE NOT EXISTS (
    SELECT * FROM da_lmp d
    WHERE d.hour_beginning = tmp_z.hour_beginning
    AND d.location_name = tmp_z.location_name
    )
)
ORDER BY hour_beginning, location_name;

---==================================================================================================
--- For the nodal prices 
CREATE TEMPORARY TABLE tmp_n
AS
    SELECT 
        'NODE' AS location_type,
        "Pricing Location" AS location_name,
        ('2025-06-01 ' ||  hour-1 || ':00:00.000-05:00')::TIMESTAMPTZ AS hour_beginning,
        "LMP" AS lmp,
        "Energy Loss Price" as mcl,
        "Energy Congestion Price" as mcc
    FROM read_csv('/home/adrian/Downloads/Archive/Ieso/DaLmp/Node/Raw/2025/PUB_DAHourlyEnergyLMP_20250601.csv.gz', 
    skip = 1,
    columns = {
        'hour': "UINT8 NOT NULL",
        'Pricing Location': "VARCHAR NOT NULL",
        'LMP': "DECIMAL(9,4) NOT NULL",
        'Energy Loss Price': "DECIMAL(9,4) NOT NULL",
        'Energy Congestion Price': "DECIMAL(9,4) NOT NULL"
        }
    )
;

---==================================================================================================
--- For the area prices 
CREATE TEMPORARY TABLE tmp_z
AS
    SELECT 
        'AREA' AS location_type,
        'ONTARIO' AS location_name,
        hour_beginning, lmp, mcc, mcl
    FROM read_csv('/home/adrian/Downloads/Archive/Ieso/DaLmp/Area/month/area_da_prices_2025-06.csv.gz', 
    columns = {
        'hour_beginning': "TIMESTAMPTZ NOT NULL",
        'lmp': "DECIMAL(9,4) NOT NULL",
        'mcc': "DECIMAL(9,4) NOT NULL",
        'mcl': "DECIMAL(9,4) NOT NULL"
        }
    )
;

INSERT INTO da_lmp BY NAME
(SELECT * FROM tmp_z 
WHERE NOT EXISTS (
    SELECT * FROM da_lmp d
    WHERE d.hour_beginning = tmp_z.hour_beginning
    AND d.location_name = tmp_z.location_name
    )
)
ORDER BY hour_beginning, location_name;





--- How to add another variant to the location_type ENUM?
CREATE TYPE location_enum AS ENUM ('AREA','HUB', 'NODE');
ALTER TABLE da_lmp ADD COLUMN location_type_new location_enum;
UPDATE da_lmp SET location_type_new = location_type::VARCHAR::location_enum;
ALTER TABLE da_lmp DROP COLUMN location_type;
ALTER TABLE da_lmp RENAME COLUMN location_type_new TO location_type;




