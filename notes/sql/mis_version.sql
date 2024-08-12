--- How extract different versions of an MIS report stored in a SQL table?
--- Only some groupings get new versions.  

--- For a table with one grouping variable (month)
CREATE TABLE IF NOT EXISTS tbl_1g AS 
    SELECT * FROM 'test/_assets/mis_version_1g.csv';
SELECT * FROM tbl_1g;

--- In the query below, `1` is the version you want. 
--- Change it to 0, 1, 2 to get other available versions.
SELECT a.*  
FROM tbl_1g a 
LEFT JOIN (
    SELECT month, LEAST(MAX(version), 1) AS max_version
    FROM tbl_1g,
    GROUP by month
) b 
ON a.month = b.month
AND a.version = b.max_version
WHERE max_version IS NOT NULL;

--- For a table with two grouping variables (month, ptid)
CREATE TABLE IF NOT EXISTS tbl_2g AS 
    SELECT * FROM 'test/_assets/mis_version_2g.csv';
SELECT * FROM tbl_2g;

--- In the query below, `1` is the version you want. 
--- Change it to 0, 1, 2 to get other available versions.
SELECT a.*  
FROM tbl_2g a 
LEFT JOIN (
    SELECT month, ptid, LEAST(MAX(version), 1) AS max_version
    FROM tbl_2g,
    GROUP by month, ptid
) b 
ON a.month = b.month
AND a.ptid = b.ptid 
AND a.version = b.max_version
WHERE max_version IS NOT NULL
ORDER BY a.ptid, a.month;


--- Used  
--- https://stackoverflow.com/questions/7745609/sql-select-only-rows-with-max-value-on-a-column
--- for inspiration


