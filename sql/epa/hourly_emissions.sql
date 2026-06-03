
SUMMARIZE emissions; 

SHOW emissions;

.mode line
SELECT * FROM emissions LIMIT 2;
.mode duckbox

--- Get all facility names
SELECT DISTINCT "Facility Name"
FROM emissions
-- WHERE "Facility Name" LIKE 'I%'
ORDER BY "Facility Name";

--- Get the total generation by "Facility Name" 
SELECT Date, Hour, unit_id, gross_load
FROM emissions
WHERE facility_name = 'Independence'
;

LOAD ICU;
SELECT Date, Hour, CAST(date + Hour * INTERVAL '1 hour' AS TIMESTAMPTZ) AS hour_beginning, 
    unit_id, gross_load
FROM emissions
WHERE facility_name = 'Fore River Energy Center'
AND date = '2025-11-02'
-- AND date < '2025-03-10'
AND unit_id = '11'
ORDER BY date, hour, unit_id;

SELECT 
    CAST(TIMESTAMPTZ '2025-03-09' + INTERVAL '1 hour' AS TIMESTAMPTZ) AS t1, 
    CAST(TIMESTAMPTZ '2025-03-09' + INTERVAL '2 hour' AS TIMESTAMPTZ) AS t2,
    CAST(TIMESTAMPTZ '2025-03-09' + INTERVAL '3 hour' AS TIMESTAMPTZ) AS t3,
    CAST(TIMESTAMPTZ '2025-03-09' + INTERVAL '23 hour' AS TIMESTAMPTZ) AS t23;


duckdb -csv -c "
LOAD quack; ATTACH 'quack:localhost' AS remote_db (TOKEN getenv('DUCKDB_QUACK_TOKEN'));
FROM remote_db.query(\"
    SELECT 
        CAST(Date AS TIMESTAMP) + Hour * INTERVAL '1 hour' AS hour_beginning,
        gross_load as mw,
        concat('unit ', unit_id) as id
    FROM emissions_hourly_ny.emissions
    WHERE facility_name = 'Independence'
    AND Date >= '2025-12-01'
    ORDER BY unit_id, hour_beginning;
\");
" | qplot --group --config='{"height": 800}'




--- Calculate the CO2 produced by facility
LOAD ggsql;


SELECT 
    facility_name,
    strftime('%Y', date) as year,
    sum(co2_mass)::DOUBLE as co2_mass
FROM emissions
WHERE facility_name in ('Independence', 'Astoria Energy', 'Northport', 'East River', 'Valley Energy Center')
--WHERE year = 2024
GROUP BY facility_name, year
-- ORDER BY year, co2_mass DESC
VISUALIZE year AS x, co2_mass AS y, facility_name as color
SCALE ORDINAL color
DRAW line;

--- Server
CALL quack_serve('quack:localhost', token = getenv('DUCKDB_QUACK_TOKEN'));
ATTACH '~/Downloads/Archive/DuckDB/epa/emissions_hourly_ny.duckdb' (READ_ONLY);
DETACH 'emissions_hourly_ny.duckdb'; 
CALL quack_stop('quack:localhost');


--- Client 
LOAD quack;
ATTACH 'quack:localhost' AS remote_db (TOKEN getenv('DUCKDB_QUACK_TOKEN'));

FROM remote_db.query('SHOW DATABASES') AS dbs;
FROM remote_db.query('USE emissions_hourly_ny');
FROM remote_db.query('SHOW TABLES') AS tables; 
FROM remote_db.emissions LIMIT 3;





SELECT * FROM TABLES;





FROM quack_query(
    'quack:localhost',
    token = '7B6AD2FD9E7D1580D4F554E27158BA45',
    query = 'SELECT 42'
    -- query = 'SELECT DISTINCT facility_name FROM emissions ORDER BY facility_name'
);




SELECT 
    Date  AS hb,
    gross_load as mw
FROM emissions
WHERE facility_name = 'Independence'
AND unit_id = 1
AND date >= '2025-10-01'
VISUALIZE hb AS x, mw AS y
DRAW line
;



GROUP BY hb
ORDER BY hb





SELECT strftime('%Y-%m', date) as month, round(mean(gross_load)) as gross_load
FROM emissions
WHERE facility_name = 'Independence'
GROUP BY strftime('%Y-%m', date)
ORDER BY month
VISUALIZE month AS x, gross_load AS y
DRAW line
DRAW point;



SELECT strftime('%Y-%m', date) as month, round(sum(co2_mass)) as co2_mass
FROM emissions
WHERE facility_name = 'Independence'
GROUP BY strftime('%Y-%m', date)
ORDER BY month
VISUALIZE month AS x, co2_mass AS y
DRAW line
DRAW point;



SELECT
    "Facility Name", "Unit ID", Date, Hour, "Gross Load (MW)", "Heat Input (mmBtu)"
FROM emissions
WHERE Date >= '2023-01-01'
AND Date <= '2023-03-01'
AND "Gross Load (MW)" IS NOT NULL
AND "Facility Name" in ('Mystic') 
-- AND "Facility Name" in ('Independence') 
ORDER BY "Facility Name", "Unit ID", "Date", "Hour";


---=====================================================================
--- See https://campd.epa.gov/help-support/faqs
--- https://campd.epa.gov/data/bulk-data-files


CREATE TABLE IF NOT EXISTS emissions (
    state VARCHAR(2) NOT NULL,
    facility_name VARCHAR NOT NULL,
    facility_id UINTEGER NOT NULL,
    unit_id VARCHAR,
    associated_stacks VARCHAR,
    date DATE NOT NULL,
    hour UTINYINT NOT NULL,
    -- Fraction of the hour that the unit was operating, from 0 to 1.
    operating_time DECIMAL(3, 2),
    gross_load USMALLINT,
    steam_load FLOAT,
    so2_mass DECIMAL(9, 4),
    so2_mass_measure_indicator ENUM(
        'Calculated',
        'Measured',
        'Substitute',
        'Measured and Substitute',
        'LME', 
        'Other'
    ),
    so2_rate DECIMAL(9, 4),
    so2_rate_measure_indicator ENUM('Calculated'),
    co2_mass DECIMAL(9, 5),
    co2_mass_measure_indicator ENUM(
        'Calculated',
        'Measured',
        'Substitute',
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    co2_rate DECIMAL(9, 6),
    co2_rate_measure_indicator ENUM('Calculated'),
    nox_mass DECIMAL(9, 4),
    nox_mass_measure_indicator ENUM(
        'Calculated', 
        'Measured', 
        'Substitute', 
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    nox_rate DECIMAL(9, 6),
    nox_rate_measure_indicator ENUM(
        'Measured',
        'Substitute',
        'Calculated',
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    heat_input DECIMAL(9, 4),
    heat_input_measure_indicator ENUM(
        'Measured',
        'Substitute',
        'Calculated',
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    primary_fuel_type VARCHAR,
    secondary_fuel_type VARCHAR,
    unit_type ENUM(
        'Arch-fired boiler',
        'Bubbling fluidized bed boiler',
        'Cyclone boiler',
        'Cell burner boiler',
        'Combined cycle',
        'Circulating fluidized bed boiler',
        'Combustion turbine',
        'Dry bottom wall-fired boiler',
        'Dry bottom turbo-fired boiler',
        'Dry bottom vertically-fired boiler',
        'Internal combustion engine',
        'Integrated gasification combined cycle',
        'Cement Kiln',
        'Other boiler',
        'Other turbine',
        'Pressurized fluidized bed boiler',
        'Process Heater',
        'Stoker',
        'Tangentially-fired',
        'Wet bottom wall-fired boiler',
        'Wet bottom turbo-fired boiler',
        'Wet bottom vertically-fired boiler',
    ),
    so2_controls VARCHAR,
    nox_controls VARCHAR,
    pm_controls VARCHAR,
    hg_controls VARCHAR,
    program_code VARCHAR,
);

CREATE TEMPORARY TABLE tmp AS
SELECT * EXCLUDE(
    so2_mass_measure_indicator, 
    so2_rate_measure_indicator,
    co2_mass_measure_indicator, 
    co2_rate_measure_indicator,
    nox_mass_measure_indicator, 
    nox_rate_measure_indicator,
    heat_input_measure_indicator,
    unit_type
    ),  
    CAST( case when so2_mass_measure_indicator = 'CALC' then 'Calculated' 
        when so2_mass_measure_indicator = 'MEASURE' then 'Measured' 
        else so2_mass_measure_indicator end AS ENUM(
        'Calculated',
        'Measured',
        'Substitute',
        'Measured and Substitute',
        'LME',
        'Other'
    )) as so2_mass_measure_indicator,
    CAST( case when so2_rate_measure_indicator = 'CALC' then 'Calculated' 
        else so2_rate_measure_indicator end AS ENUM(
        'Calculated',
    )) as so2_rate_measure_indicator,
    CAST( case when co2_mass_measure_indicator = 'CALC' then 'Calculated' 
        when co2_mass_measure_indicator = 'MEASURE' then 'Measured' 
        else co2_mass_measure_indicator end AS ENUM(
        'Calculated',
        'Measured', 
        'Substitute', 
        'Measured and Substitute',
        'LME',
        'Other'
    )) as co2_mass_measure_indicator,
    CAST( case when co2_rate_measure_indicator = 'CALC' then 'Calculated' 
        else co2_rate_measure_indicator end AS ENUM(
        'Calculated',
    )) as co2_rate_measure_indicator,
    CAST( case when nox_mass_measure_indicator = 'SUB' then 'Substitute' 
        when nox_mass_measure_indicator = 'MEASURE' then 'Measured' 
        when nox_mass_measure_indicator = 'MEASSUB' then 'Measured and Substitute' 
        else nox_mass_measure_indicator end AS ENUM(
        'Calculated', 
        'Measured', 
        'Substitute', 
        'Measured and Substitute',
        'LME',
        'Other'
    )) as nox_mass_measure_indicator, 
    CAST( case when nox_rate_measure_indicator = 'SUB' then 'Substitute' 
        when nox_rate_measure_indicator = 'MEASURE' then 'Measured' 
        else nox_rate_measure_indicator end AS ENUM(
        'Calculated', 
        'Measured', 
        'Substitute', 
        'Measured and Substitute',
        'LME',
        'Other'
    )) as nox_rate_measure_indicator, 
    CAST( case when heat_input_measure_indicator = 'MEASURE' then 'Measured' 
        else heat_input_measure_indicator end AS ENUM(
        'Calculated', 
        'Measured', 
        'Substitute', 
        'Measured and Substitute',
        'LME',
        'Other'
    )) as heat_input_measure_indicator, 
    CAST(case when unit_type  = 'Combustion turbine (Started Jan 12, 2024)' then 'Combustion turbine'
        else unit_type end AS ENUM(
            'Arch-fired boiler',
            'Bubbling fluidized bed boiler',
            'Cyclone boiler',
            'Cell burner boiler',
            'Combined cycle',
            'Circulating fluidized bed boiler',
            'Combustion turbine',
            'Dry bottom wall-fired boiler',
            'Dry bottom turbo-fired boiler',
            'Dry bottom vertically-fired boiler',
            'Internal combustion engine',
            'Integrated gasification combined cycle',
            'Cement Kiln',
            'Other boiler',
            'Other turbine',
            'Pressurized fluidized bed boiler',
            'Process Heater',
            'Stoker',
            'Tangentially-fired',
            'Wet bottom wall-fired boiler',
            'Wet bottom turbo-fired boiler',
            'Wet bottom vertically-fired boiler',
        )) as unit_type,    
FROM (
    SELECT 
        CAST("State" AS VARCHAR(2)) as state,
        CAST("Facility Name" AS VARCHAR) as facility_name,
        CAST("Facility ID" AS UINTEGER) as facility_id,
        CAST("Unit ID" AS VARCHAR) as unit_id,
        CAST("Associated Stacks" AS VARCHAR) as associated_stacks,
        CAST(Date AS DATE) as date,
        CAST(Hour AS UTINYINT) as hour,
        -- CAST(date + Hour * INTERVAL '1 hour' AS TIMESTAMPTZ) AS hour_beginning,
        -- Fraction of the hour that the unit was operating, from 0 to 1.
        CAST("Operating Time" AS DECIMAL(3, 2)) as operating_time,
        CAST("Gross Load (MW)" AS USMALLINT) as gross_load,
        CAST("Steam Load (1000 lb/hr)" AS FLOAT) as steam_load,
        CAST("SO2 Mass (lbs)" AS DECIMAL(9, 4)) as so2_mass,
        CAST("SO2 Mass Measure Indicator" AS VARCHAR) as so2_mass_measure_indicator,
        CAST("SO2 Rate (lbs/mmBtu)" AS DECIMAL(9, 4)) as so2_rate,
        CAST("SO2 Rate Measure Indicator" AS VARCHAR) as so2_rate_measure_indicator,
        CAST("CO2 Mass (short tons)" AS DECIMAL(9, 5)) as co2_mass,
        CAST("CO2 Mass Measure Indicator" AS VARCHAR) as co2_mass_measure_indicator,
        CAST("CO2 Rate (short tons/mmBtu)" AS DECIMAL(9, 6)) as co2_rate,
        CAST("CO2 Rate Measure Indicator" AS VARCHAR) as co2_rate_measure_indicator,
        CAST("NOx Mass (lbs)" AS DECIMAL(9, 4)) as nox_mass,
        CAST("NOx Mass Measure Indicator" AS VARCHAR) as nox_mass_measure_indicator,
        CAST("NOx Rate (lbs/mmBtu)" AS DECIMAL(9, 6)) as nox_rate,
        CAST("NOx Rate Measure Indicator" AS VARCHAR) as nox_rate_measure_indicator,
        CAST("Heat Input (mmBtu)" AS DECIMAL(9, 4)) as heat_input,
        CAST("Heat Input Measure Indicator" AS VARCHAR) as heat_input_measure_indicator,
        CAST("Primary Fuel Type" AS VARCHAR) as primary_fuel_type,
        CAST("Secondary Fuel Type" AS VARCHAR) as secondary_fuel_type,
        CAST("Unit Type" AS VARCHAR) as unit_type,    
        CAST("SO2 Controls" AS VARCHAR) as so2_controls,
        CAST("NOx Controls" AS VARCHAR) as nox_controls,
        CAST("PM Controls" AS VARCHAR) as pm_controls,
        CAST("Hg Controls" AS VARCHAR) as hg_controls,
        CAST("Program Code" AS VARCHAR) as program_code
    FROM read_csv(
            '/home/adrian/Downloads/Archive/EPA/Emissions/Hourly/VA/Raw/emissions-hourly-202*-va.csv.gz',
            header = true,
            types = { 'Unit ID': 'VARCHAR' },
            dateformat = '%Y-%m-%d'
        )
);


INSERT INTO emissions BY NAME
(SELECT * FROM tmp
WHERE NOT EXISTS (
    SELECT 1
    FROM emissions e
    WHERE e.facility_id = tmp.facility_id
    AND e.unit_id = tmp.unit_id
    AND e.date = tmp.date
    AND e.hour = tmp.hour
))
ORDER BY facility_id, unit_id, date, hour;



select DISTINCT unit_type from tmp;

PRAGMA table_info('tmp');




select * from tmp limit 3;

select distinct "Operating Time" from tmp
ORDER BY "Operating Time";