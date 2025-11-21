
SELECT * FROM hour_count;



---========================================================================
CREATE TABLE hour_count 
AS SELECT * 
FROM read_csv('/home/adrian/Downloads/Archive/Calendars/hour_count.csv.gz', header = true);

