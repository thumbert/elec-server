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
        ignore_errors = true, 
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





