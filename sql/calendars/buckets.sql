
SELECT * FROM buckets
LIMIT 10;



---========================================================================
DROP TABLE IF EXISTS buckets;

CREATE TABLE buckets 
AS SELECT * 
FROM read_csv('/home/adrian/Downloads/Archive/Calendars/buckets.csv.gz', header = true);


