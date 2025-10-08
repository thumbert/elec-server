
SELECT * FROM buckets;



---========================================================================
CREATE TABLE buckets 
AS SELECT * 
FROM read_csv('/home/adrian/Downloads/Archive/Calendars/buckets.csv.gz', header = true);

