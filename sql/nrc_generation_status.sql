
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




----####################################################
-- duckdb ~/Downloads/Archive/DuckDB/nrc_generation_status.duckdb < sql/nrc_generation_status.sql


DROP TABLE IF EXISTS Status;

-- Load all the csv files
-- Noticed that if the 'Power' column is UTINYINT, the size of the DB is larger!
--
-- Note: 
--  * Need to read the first column as a string and then parse the date part because in the 
--    early years 2005, the date was in format 1/1/2005 and in later years, say 2024,
--    the date was in 12/21/2024 12:00:00 AM! 
-- 
CREATE TEMPORARY TABLE tmp 
AS 
    SELECT * 
    FROM read_csv('/home/adrian/Downloads/Archive/NRC/ReactorStatus/Raw/*powerstatus.txt.gz', 
        delim = '|', 
        header = true, 
        ignore_errors = true, -- need this because the last row of file is wrong format!
        columns = {
            'ReportDt': 'VARCHAR',
            'Unit': 'VARCHAR',
            'Power': 'INT',
        }
    );


CREATE TABLE Status 
AS
    SELECT strptime(split_part(ReportDt, ' ', 1), '%m/%d/%Y')::DATE AS ReportDt, Unit, Power 
    FROM tmp
    ORDER BY ReportDt, Unit
;


----------------------------------------------------------------------------------

-- SELECT * FROM Status LIMIT 5;


-- CREATE TEMPORARY TABLE tmp 
-- AS 
--     SELECT * 
--     FROM read_csv('/home/adrian/Downloads/Archive/NRC/ReactorStatus/Raw/2024powerstatus.txt.gz', 
--         delim = '|', 
--         header = true, 
--         ignore_errors = true, -- need this because the last row of file is wrong format!
--         columns = {
--             'ReportDt': 'VARCHAR',
--             'Unit': 'VARCHAR',
--             'Power': 'INT',
--         }
--     );

-- DELETE FROM Status
-- WHERE ReportDt >= '2024-01-01'
-- AND ReportDt <= '2024-12-31';

-- INSERT INTO Status
--     SELECT strptime(split_part(ReportDt, ' ', 1), '%m/%d/%Y')::DATE AS ReportDt, Unit, Power 
--     FROM tmp
--     ORDER BY ReportDt, Unit
-- ;


-- Get the unique units
SELECT DISTINCT Unit FROM Status
ORDER BY Unit;

-- Get the latest 5 days in the database
SELECT DISTINCT ReportDt FROM Status
ORDER BY ReportDt DESC
LIMIT 5;


-- 
SELECT ReportDt, Unit, Power FROM Status
WHERE ReportDt >= '2024-01-01'
AND ReportDt <= '2024-01-15'
AND Unit in ('Byron 1', 'Calvert Cliffs 1')
ORDER BY Unit, ReportDt;



