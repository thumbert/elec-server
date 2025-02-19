-- duckdb ~/Downloads/Archive/DuckDB/nrc_generation_status.duckdb < sql/nrc_generation_status.sql

DROP TABLE Status;

-- Load all the csv files
-- Noticed that if the 'Power' column is UTINYINT, the size of the DB is larger!
CREATE TEMPORARY TABLE tmp 
AS 
    SELECT * 
    FROM read_csv('/home/adrian/Downloads/Archive/NRC/ReactorStatus/Raw/*powerstatus.txt', 
        delim = '|', 
        header = true, 
        ignore_errors = true, -- need this because the last row of file is wrong format!
        columns = {
            'ReportDt': 'DATETIME',
            'Unit': 'VARCHAR',
            'Power': 'INT',
        });

CREATE TABLE Status 
AS
    SELECT strftime(ReportDt, '%Y-%m-%d')::DATE AS ReportDt, Unit, Power 
    FROM tmp
    ORDER BY Unit, ReportDt
;


SELECT * FROM Status;

SELECT DISTINCT Unit FROM Status
WHERE Unit LIKE 'S%'
ORDER BY Unit;

SELECT * FROM Status
WHERE Unit = 'Turkey Point 3';
-- WHERE Unit = 'Beaver Valley 1'
-- WHERE Unit = 'FitzPatrick'
-- WHERE Unit = 'Nine Mile Point 2'
-- WHERE Unit = 'Seabrook 1'


-- Get the day on day non zero changes in percent online
SELECT ReportDt, Unit, Power, Prev_Power, Change
FROM( 
    SELECT ReportDt, 
      Unit, 
      Power,
      LAG(Power) OVER (PARTITION BY Unit ORDER BY ReportDt) as Prev_Power,
      Power - Prev_Power as Change, 
    FROM Status 
    WHERE ReportDt > current_date - 10
    ) AS a
WHERE Change != 0
AND ReportDt = (SELECT MAX(ReportDt) FROM Status)
ORDER BY Unit;



-- Get average % 
SELECT Unit, ROUND(MEAN(Power), 1) as Avg
FROM Status
GROUP BY Unit
ORDER BY Avg;








