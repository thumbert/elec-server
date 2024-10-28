

SELECT * FROM forecast LIMIT 5;

--- Which months are in the table 
SELECT strftime("forecast_hour_beginning", '%Y-%m') AS YEARMON, COUNT(*) 
FROM forecast
GROUP BY YEARMON
ORDER BY YEARMON;


--- Delete one month of data
DELETE FROM forecast 
WHERE forecast_hour_beginning >= '2024-10-01'
AND forecast_hour_beginning < '2024-11-01';


--- Insert one month of data from gz file
INSERT INTO forecast
FROM read_csv(
    '7daySolarForecast/month/solar_forecast_2024-10.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');


--- Check that a given report date is there
SELECT * FROM forecast
WHERE report_date = '2024-10-25';



--- Get the latest forecast for a given hour_beginning.
--- NOTE:  It may NOT be what you want, because it contains the intra-day forecast!
SELECT a.* FROM forecast a
JOIN (
    SELECT forecast_hour_beginning, MAX(report_date) as last_version
    FROM forecast
    GROUP BY forecast_hour_beginning
) b
ON a.forecast_hour_beginning = b.forecast_hour_beginning
AND a.report_date = b.last_version
WHERE a.forecast_hour_beginning >= '2024-10-18'
AND a.forecast_hour_beginning < '2024-10-22';


--- Always get the forecast as of the previous day, or the last forecast!
--- This is probably a better query to use for decision making
SELECT a.* FROM forecast a
JOIN (
    SELECT MAX(report_date, 2) AS versions, forecast_hour_beginning,
        CASE 
            WHEN len(versions) = 1 THEN 1
            WHEN len(versions) = 2 THEN IF (versions[1] = CAST(forecast_hour_beginning AS DATE), 2, 1)
        END AS idx,
        versions[idx] as last_version
    FROM forecast
    GROUP BY forecast_hour_beginning
) b
ON a.forecast_hour_beginning = b.forecast_hour_beginning
AND a.report_date = b.last_version
WHERE a.forecast_hour_beginning >= '2024-10-18'
-- AND a.forecast_hour_beginning < '2024-10-22'
ORDER BY a.forecast_hour_beginning;


--- Get all the forecasts for one day, say 2024-10-18
SELECT * FROM forecast
WHERE forecast_hour_beginning >= '2024-10-18 18:00:00'
AND forecast_hour_beginning < '2024-10-18 19:00:00'
ORDER BY forecast_hour_beginning;











--- Scratch space below ---------------------

SELECT MAX(report_date, 2) AS versions, forecast_hour_beginning,
    CASE 
        WHEN len(versions) = 1 THEN 1
        WHEN len(versions) = 2 THEN IF (versions[1] = CAST(forecast_hour_beginning AS DATE), 2, 1)
        ELSE 3
    END AS idx,
    versions[idx] as last_version
FROM forecast
WHERE forecast_hour_beginning >= '2024-10-19'
-- AND forecast_hour_beginning < '2024-10-20'
-- AND report_date < forecast_hour_beginning
GROUP BY forecast_hour_beginning
ORDER BY forecast_hour_beginning;




