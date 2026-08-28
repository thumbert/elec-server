load ggsql;

SELECT * FROM WaterLevel;

--- Show which dates are in the table
SELECT DISTINCT hour_beginning::DATE AS date
FROM WaterLevel
ORDER BY date;


SELECT DISTINCT station_id
FROM WaterLevel
ORDER BY station_id;


-- One station hourly data
SELECT hour_beginning, value
FROM WaterLevel
-- WHERE station_id = '1-2944'
-- WHERE station_id = '1-2987'
-- WHERE station_id = '1-3009'
WHERE station_id = '1-2919'
-- AND value > 300
ORDER BY hour_beginning
VISUALIZE 
    hour_beginning as x,
    value as y
DRAW line
;

--- Get the median value by day
SELECT hour_beginning::DATE AS date, median(value) AS value
FROM WaterLevel
WHERE station_id = '1-2919'
GROUP BY date
ORDER BY date
VISUALIZE 
    date as x,
    value as y
DRAW line
;



--- Aggregate all stations (there is some bad data)
SELECT hour_beginning, SUM(value) AS total_value
FROM WaterLevel
GROUP BY hour_beginning
ORDER BY hour_beginning
VISUALIZE 
    hour_beginning as x,
    total_value as y
DRAW line
;

--- Plot all stations as separate lines
SELECT station_id, hour_beginning::DATE AS date, median(value) AS value
FROM WaterLevel
WHERE value > 0
GROUP BY station_id, date
ORDER BY date
VISUALIZE 
    date as x,
    value as y,
    station_id as color
DRAW line
SCALE ORDINAL color
;






SELECT station_id, MIN(value) AS min_value, MAX(value) AS max_value
FROM WaterLevel
GROUP BY station_id
ORDER BY station_id;

-- Station 1-7306 has bad data from 5/7/2025
SELECT strftime('%Y-%m-%d', hour_beginning) AS date,
    mean(value) AS value
FROM WaterLevel
WHERE station_id = '1-7306'
GROUP BY date
ORDER BY date;



SELECT strftime('%Y-%m-%d', hour_beginning) AS date,
    station_id,
    median(value) AS value
FROM WaterLevel
GROUP BY date, station_id
ORDER BY station_id, date;


SELECT strftime('%Y-%m-%d', hour_beginning) AS date, 
       round(mean(value)) AS value
FROM (
    SELECT hour_beginning, 
        sum(value) AS value
    FROM WaterLevel
    GROUP BY hour_beginning
)       
GROUP BY date
ORDER BY date;





SELECT station_id, hour_beginning, value
FROM WaterLevel
WHERE station_id == '1-2951'
ORDER BY hour_beginning;


SELECT station_id, hour_beginning::DATE AS date, mean(value)::DECIMAL(9,2) AS value
FROM WaterLevel
WHERE station_id == '1-2951'
GROUP BY station_id, date
ORDER BY date;

-- ============================================================================================================
-- Read



-- ============================================================================================================

CREATE TABLE IF NOT EXISTS WaterLevel (
    station_id VARCHAR NOT NULL,
    hour_beginning TIMESTAMP NOT NULL,
    value DOUBLE NOT NULL, 
);


-- Insert the *NEW* data from one daily file into the WaterLevel table
INSERT INTO WaterLevel
    SELECT station_id, hour_beginning, value 
    FROM read_csv('~/Downloads/Archive/HQ/HydroMeteorologicalData/Processed/WaterLevel/data_2024-12-05.csv', 
        header = true) 
    EXCEPT SELECT * FROM WaterLevel;



