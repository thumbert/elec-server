

LOAD ggsql;

CREATE TABLE tmp AS
SELECT *
FROM read_csv(
    '/home/adrian/Downloads/emissions-daily-2026-q1.csv',
    header = true,
    timestampformat = 'YYYY-MM-DD HH:MM:SS.000'
);

SELECT DISTINCT "Facility Name"
FROM tmp
WHERE State = 'NY'
ORDER BY "Facility Name"; 

SELECT * 
FROM tmp
WHERE "Facility Name" = 'Independence'
AND State = 'NY'
AND "Date" = '2026-01-01';




LOAD ggsql;
SELECT date as x, gross_load as y, unit_id as color
FROM emissions
WHERE facility_name = 'Independence'
AND state = 'NY'
ORDER BY date
VISUALIZE x, y, color
DRAW line
SCALE ordinal color
LABEL
    x => 'Date',
    y => 'Gross Load (MWh)',
    color => 'Unit ID'
;





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
    -- How many hours the unit ran
    hour_count UTINYINT NOT NULL,
    -- Fraction of the hour that the unit was operating, from 0 to 1.
    day_fraction DECIMAL(4, 2),
    gross_load USMALLINT,
    steam_load FLOAT,
    so2_mass DECIMAL(9, 4),
    so2_rate DECIMAL(9, 4),
    co2_mass DECIMAL(18, 6),
    co2_rate DECIMAL(9, 6),
    nox_mass DECIMAL(9, 4),
    nox_rate DECIMAL(9, 6),
    heat_input DECIMAL(18, 6),
    primary_fuel_type VARCHAR,
    secondary_fuel_type VARCHAR,
    so2_controls VARCHAR,
    nox_controls VARCHAR,
    pm_controls VARCHAR,
    hg_controls VARCHAR,
    program_code VARCHAR,
    -- unit_type VARCHAR
);

CREATE TEMPORARY TABLE tmp AS
SELECT * EXCLUDE(
        unit_type
    ),  
FROM (
    SELECT 
        CAST("State" AS VARCHAR(2)) as state,
        CAST("Facility Name" AS VARCHAR) as facility_name,
        CAST("Facility ID" AS UINTEGER) as facility_id,
        CAST("Unit ID" AS VARCHAR) as unit_id,
        CAST("Associated Stacks" AS VARCHAR) as associated_stacks,
        CAST(Date AS DATE) as date,
        CAST("Operating Time Count" AS UTINYINT) as hour_count,
        CAST("Sum of the Operating Time" AS DECIMAL(4, 2)) as day_fraction,
        CAST("Gross Load (MWh)" AS USMALLINT) as gross_load,
        CAST("Steam Load (1000 lb)" AS FLOAT) as steam_load,
        CAST("SO2 Mass (short tons)" AS DECIMAL(9, 4)) as so2_mass,
        CAST("SO2 Rate (lbs/mmBtu)" AS DECIMAL(9, 4)) as so2_rate,
        CAST("CO2 Mass (short tons)" AS DECIMAL(18, 6)) as co2_mass,
        CAST("CO2 Rate (short tons/mmBtu)" AS DECIMAL(9, 6)) as co2_rate,
        CAST("NOx Mass (short tons)" AS DECIMAL(9, 4)) as nox_mass,
        CAST("NOx Rate (lbs/mmBtu)" AS DECIMAL(9, 6)) as nox_rate,
        CAST("Heat Input (mmBtu)" AS DECIMAL(18, 6)) as heat_input,
        CAST("Primary Fuel Type" AS VARCHAR) as primary_fuel_type,
        CAST("Secondary Fuel Type" AS VARCHAR) as secondary_fuel_type,
        CAST("Unit Type" AS VARCHAR) as unit_type,    
        CAST("SO2 Controls" AS VARCHAR) as so2_controls,
        CAST("NOx Controls" AS VARCHAR) as nox_controls,
        CAST("PM Controls" AS VARCHAR) as pm_controls,
        CAST("Hg Controls" AS VARCHAR) as hg_controls,
        CAST("Program Code" AS VARCHAR) as program_code
    FROM read_csv(
            '/home/adrian/Downloads/Archive/EPA/Emissions/Daily/Raw/emissions-daily-202*-q2.csv.gz',
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
))
ORDER BY facility_id, unit_id, date;



PRAGMA table_info('tmp');

SELECT "Operating Time Count", COUNT(*) from tmp
GROUP BY "Operating Time Count"
ORDER BY "Operating Time Count";

SELECT "Sum of the Operating Time", COUNT(*) from tmp
GROUP BY "Sum of the Operating Time"
ORDER BY "Sum of the Operating Time";

