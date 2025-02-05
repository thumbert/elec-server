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



--- For a table with two grouping variables (month, ptid) with version as a timestamp 
CREATE TABLE IF NOT EXISTS tbl_utc_2g AS 
    SELECT * FROM 'test/_assets/mis_version_utc_2g.csv';
SELECT * FROM tbl_utc_2g;

--- Note that because SQL list indexing starts at 1 (not 0), you need to add 1 in 
--- the outer select. 
--- The inner select creates a list from all the versions and then indexes into this 
--- list to get the requested version. This only works if the rows are ordered by 
--- (month, ptid, version) before creating the list. 
SET VARIABLE version = 0;
SELECT month,
    ptid,
    values[LEAST(len(values), getvariable('version') + 1)] as value
FROM (
        SELECT month,
            ptid,
            array_agg(value) as values,
        FROM tbl_utc_2g
        GROUP BY month,
            ptid
    )
ORDER BY month,
    ptid;






--- In the query below, `1` is the version you want. 
--- Change it to 0, 1, 2 to get other available versions.
SELECT a.*  
FROM tbl_utc_2g a 
LEFT JOIN (
    SELECT month, ptid, LEAST(MAX(version), 1) AS max_version
    FROM tbl_utc_2g,
    GROUP by month, ptid
) b 
ON a.month = b.month
AND a.ptid = b.ptid 
AND a.version = b.max_version
WHERE max_version IS NOT NULL
ORDER BY a.ptid, a.month;







--- For a table with two grouping variables (month, ptid) with version as an integer
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


