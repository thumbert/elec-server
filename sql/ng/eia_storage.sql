
SELECT * FROM eia_storage LIMIT 10;

SELECT MIN(week_ending), MAX(week_ending), COUNT(*) FROM eia_storage;

SELECT 
    week_ending,
    SUM(value_bcf) AS total_storage_bcf
FROM eia_storage
GROUP BY week_ending
ORDER BY week_ending;



duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/natural_gas/eia_storage.duckdb' AS tbl;
SELECT 
    week_ending,
    SUM(value_bcf) AS total_storage_bcf
FROM tbl.eia_storage
GROUP BY week_ending
ORDER BY week_ending;
" | qplot







---===================================================================
--- EIA Storage Data


CREATE TABLE eia_storage (
    week_ending DATE NOT NULL,
    source ENUM('EIA-912', 'Derived EIA Weekly Estimates') NOT NULL,
    region_name VARCHAR NOT NULL,
    storage_type ENUM('Salt', 'NonSalt'),
    value_bcf FLOAT NOT NULL,
);


INSERT INTO eia_storage
SELECT 
    week_ending,
    source,
    regexp_replace(id, ' Salt| NonSalt', '') AS region_name,
    CASE 
        WHEN contains(id, ' Salt') THEN 'Salt'
        WHEN contains(id, ' NonSalt') THEN 'NonSalt'
        ELSE NULL
    END AS storage_type,
    storage
FROM (
    UNPIVOT (
        SELECT 
        strptime("Week ending", '%d-%b-%y')::DATE AS week_ending, 
        "Source"::VARCHAR AS source,
        "East Region"::int64 AS "East",
        "Midwest Region"::int64 AS "Midwest",
        "Mountain Region"::int64 AS "Mountain",
        "Pacific Region"::int64 AS "Pacific",
        "Salt"::int64 AS "South Central Salt",
        "NonSalt"::int64 AS "South Central NonSalt",
        FROM read_csv(
                '/home/adrian/Documents/Cassie_SharedWithDad/ngshistory.csv',
                header = true, 
                skip = 6,
                thousands = ','
        )
    ) ON East, Midwest, Mountain, Pacific, "South Central Salt", "South Central NonSalt"
    INTO 
        NAME id 
        VALUE storage
);    
    

CREATE TABLE tmp (ID VARCHAR);
INSERT INTO tmp VALUES ('Pacific'), ('South Central Salt'), ('South Central NonSalt');    
SELECT * FROM tmp;

SELECT 
    -- id,
    regexp_replace(id, ' Salt| NonSalt', '') AS region_name,
    CASE 
        WHEN contains(id, ' Salt') THEN 'Salt'
        WHEN contains(id, ' NonSalt') THEN 'NonSalt'
        ELSE NULL
    END AS storage_type
FROM tmp;
