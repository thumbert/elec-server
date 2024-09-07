CREATE TABLE emissions (
    State VARCHAR(2) NOT NULL,
    "Facility Name" VARCHAR NOT NULL,
    "Facility ID" UINTEGER NOT NULL,
    "Unit ID" VARCHAR,
    "Associated Stacks" VARCHAR,
    Date DATE NOT NULL,
    Hour UTINYINT NOT NULL,
    -- Fraction of the hour
    "Operating Time" DECIMAL(3, 2),
    "Gross Load (MW)" USMALLINT,
    "Steam Load (1000 lb/hr)" FLOAT,
    "SO2 Mass (lbs)" DECIMAL(9, 4),
    "SO2 Mass Measure Indicator" ENUM(
        'Calculated',
        'Measured',
        'Substitute',
        'Measured and Substitute',
        'LME', 
        'Other'
    ),
    "SO2 Rate (lbs/mmBtu)" DECIMAL(9, 4),
    "SO2 Rate Measure Indicator" ENUM('Calculated'),
    "CO2 Mass (short tons)" DECIMAL(9, 5),
    "CO2 Mass Measure Indicator" ENUM(
        'Calculated',
        'Measured',
        'Substitute',
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    "CO2 Rate (short tons/mmBtu)" DECIMAL(9, 6),
    "CO2 Rate Measure Indicator" ENUM('Calculated'),
    "NOx Mass (lbs)" DECIMAL(9, 4),
    "NOx Mass Measure Indicator" ENUM(
        'Calculated', 
        'Measured', 
        'Substitute', 
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    "NOx Rate (lbs/mmBtu)" DECIMAL(9, 6),
    "NOx Rate Measure Indicator" ENUM(
        'Measured',
        'Substitute',
        'Calculated',
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    "Heat Input (mmBtu)" DECIMAL(9, 4),
    "Heat Input Measure Indicator" ENUM(
        'Measured',
        'Substitute',
        'Calculated',
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    "Primary Fuel Type" VARCHAR,
    "Secondary Fuel Type" VARCHAR,
    "Unit Type" ENUM(
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
    "SO2 Controls" VARCHAR,
    "NOx Controls" VARCHAR,
    "PM Controls" VARCHAR,
    "Hg Controls" VARCHAR,
    "Program Code" VARCHAR,
);

INSERT INTO emissions
FROM read_csv(
        '/home/adrian/Downloads/Archive/EPA/Emissions/Hourly/MA/Raw/emissions-hourly-202*-ma.csv.gz',
        header = true,
        dateformat = '%Y-%m-%d'
    );

-- DROP TABLE emissions;

SELECT COUNT(*) FROM emissions;


-- CREATE TABLE emissions AS
-- SELECT *
-- FROM read_csv(
--         '/home/adrian/Downloads/Archive/EPA/Emissions/Hourly/VT/emissions-hourly-2022-ny.csv',
--         header = true,
--         types = { 'Unit ID': 'VARCHAR' },
--         dateformat = '%Y-%m-%d'
--     );

INSERT INTO emissions
FROM read_csv(
        '/home/adrian/Downloads/Archive/EPA/Emissions/Hourly/VT/Raw/emissions-hourly-2022-vt.csv',
        header = true,
        dateformat = '%Y-%m-%d'
    );



.mode line
SELECT *
FROM emissions
LIMIT 2;

--- Get all facility names
SELECT DISTINCT "Facility Name"
FROM emissions
-- WHERE "Facility Name" LIKE 'I%'
ORDER BY "Facility Name";

--- Get the total generation by "Facility Name" 
SELECT Date,
    Hour,
    SUM("Gross Load (MW)")
FROM emissions
WHERE "Facility Name" = 'Independence'
    AND Date = '2022-03-13'
GROUP BY Date,
    Hour
ORDER BY Date,
    Hour;
LIMIT 100;




SELECT
    "Facility Name", "Unit ID", Date, Hour, "Gross Load (MW)", "Heat Input (mmBtu)"
FROM emissions
WHERE Date >= '2023-01-01'
AND Date <= '2023-03-01'
AND "Gross Load (MW)" IS NOT NULL
AND "Facility Name" in ('Mystic') 
-- AND "Facility Name" in ('Independence') 
ORDER BY "Facility Name", "Unit ID", "Date", "Hour";

