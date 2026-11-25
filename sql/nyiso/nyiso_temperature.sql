
SELECT min(forecast_date), max(forecast_date), count(*)
FROM temperature;

SELECT * FROM temperature
WHERE station_id = 'ALB'
;





---=======================================================================
--- monthly auction bids/offers
CREATE TABLE IF NOT EXISTS temperature (
    forecast_date DATE NOT NULL,
    vintage_date DATE NOT NULL,
    vintage ENUM('Actual', 'Forecast') NOT NULL,
    station_id VARCHAR NOT NULL,
    max_temperature SMALLINT NOT NULL,
    min_temperature SMALLINT NOT NULL,
    max_wet_bulb SMALLINT NOT NULL,
    min_wet_bulb SMALLINT NOT NULL
);


CREATE TEMPORARY TABLE tmp
AS (
    SELECT 
        "Forecast Date"::DATE AS forecast_date,
        "Vintage Date"::DATE AS vintage_date,
        "Vintage"::VARCHAR AS vintage,
        "Station ID"::VARCHAR AS station_id,
        "Max Temp"::SMALLINT AS max_temperature,
        "Min Temp"::SMALLINT AS min_temperature,
        "Max Wet Bulb"::SMALLINT AS max_wet_bulb,
        "Min Wet Bulb"::SMALLINT AS min_wet_bulb    
    FROM read_csv('/home/adrian/Downloads/Archive/Nyiso/Temperature/tmp/2026*lfweather.csv', 
        header = true, 
        dateformat = '%m/%d/%Y'
));


INSERT INTO temperature
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM temperature d
        WHERE
            d.forecast_date = t.forecast_date AND
            d.vintage_date = t.vintage_date AND
            d.vintage = t.vintage AND
            d.station_id = t.station_id AND
            d.max_temperature = t.max_temperature AND
            d.min_temperature = t.min_temperature AND
            d.max_wet_bulb = t.max_wet_bulb AND
            d.min_wet_bulb = t.min_wet_bulb
    )
);


