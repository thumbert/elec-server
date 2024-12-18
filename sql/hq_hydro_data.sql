
SELECT * FROM WaterLevel;

--- Show which dates are in the table
SELECT DISTINCT hour_beginning::DATE AS date
FROM WaterLevel
ORDER BY date;


SELECT DISTINCT station_id
FROM WaterLevel
ORDER BY station_id;


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



