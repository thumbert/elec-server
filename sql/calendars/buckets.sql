
SELECT * FROM buckets LIMIT 10;

--- Get all available buckets
SELECT name
FROM pragma_table_info('buckets')
WHERE type = 'BOOLEAN'
ORDER BY name;

LOAD icu;SET TimeZone = 'America/Los_Angeles';
SELECT
    hour_beginning,
    caiso_6x16,
    caiso_1x16H,
    caiso_7x8
FROM buckets
WHERE hour_beginning >= '2025-12-01 00:00:00.000-08:00'
AND hour_beginning < '2025-12-05 00:00:00.000-08:00'
ORDER BY hour_beginning;    

--- calculate monthly hourly counts of each bucket type
LOAD icu;SET TimeZone = 'America/Los_Angeles';
SELECT
    strftime(hour_beginning, '%Y-%m') AS month,
    SUM(CASE WHEN caiso_6x16 THEN 1 ELSE 0 END)::INT as caiso_6x16,
    SUM(CASE WHEN caiso_1x16H THEN 1 ELSE 0 END)::INT AS caiso_1x16H,
    SUM(CASE WHEN caiso_7x8 THEN 1 ELSE 0 END)::INT AS caiso_7x8
FROM buckets
GROUP BY month
ORDER BY month; 




---========================================================================
DROP TABLE IF EXISTS buckets;

CREATE TABLE buckets 
AS SELECT * 
FROM read_csv('/home/adrian/Downloads/Archive/Calendars/buckets.csv.gz', header = true);


