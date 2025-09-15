SET TimeZone = 'America/Cancun';
select * from forecast_summary
WHERE organization = 'MARKET PARTICIPANT'
AND fuel_type = 'Solar'
AND zone = 'NORTHEAST';

-- get the latest forecast
SELECT 
    arg_max(forecast_timestamp, forecast_timestamp) AS forecast_timestamp,
    organization,
    fuel_type,
    zone,
    hour_beginning,
    arg_max(mw, forecast_timestamp) AS mw
FROM forecast_summary
WHERE organization = 'MARKET PARTICIPANT'
AND fuel_type = 'Solar'
AND zone = 'NORTHEAST'
GROUP BY organization, fuel_type, zone, hour_beginning
ORDER BY forecast_timestamp, hour_beginning;



---=============================================================================================
--
SET TimeZone = 'America/Cancun';
CREATE TABLE IF NOT EXISTS forecast_summary (
    forecast_timestamp TIMESTAMPTZ NOT NULL,
    organization ENUM('MARKET PARTICIPANT', 'EMBEDDED') NOT NULL,
    fuel_type ENUM('Wind', 'Solar') NOT NULL,
    zone VARCHAR NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,    
    mw DECIMAL(9,4) NOT NULL,
);

CREATE TEMPORARY TABLE tmp
AS
    SELECT 
        forecast_timestamp, organization, fuel_type, zone, hour_beginning, mw
    FROM read_csv('/home/adrian/Downloads/Archive/Ieso/VGForecastSummary/month/PUB_VGForecastSummary_2025-08.csv.gz', 
    columns = {
        'forecast_timestamp': "TIMESTAMPTZ NOT NULL",
        'organization': "ENUM('MARKET PARTICIPANT', 'EMBEDDED') NOT NULL",
        'fuel_type': "ENUM('Wind', 'Solar') NOT NULL",
        'zone': "VARCHAR NOT NULL",
        'hour_beginning': "TIMESTAMPTZ NOT NULL",
        'mw': "DECIMAL(9,4) NOT NULL"
        }
    )
;

INSERT INTO forecast_summary BY NAME
(SELECT * FROM tmp 
WHERE NOT EXISTS (
    SELECT * FROM forecast_summary f
    WHERE f.forecast_timestamp = tmp.forecast_timestamp
    AND f.organization = tmp.organization
    AND f.zone = tmp.zone
    AND f.fuel_type = tmp.fuel_type
    AND f.hour_beginning = tmp.hour_beginning
    )
)
ORDER BY forecast_timestamp, organization, fuel_type, zone, hour_beginning;

select * from tmp
WHERE organization = 'MARKET PARTICIPANT'
AND fuel_type = 'Solar'
AND zone = 'NORTHEAST';
