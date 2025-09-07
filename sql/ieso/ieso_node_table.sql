
--- 957 nodes, LMPs are published for 1025 nodes!
SELECT COUNT(location_name)
FROM node_table;


--- See which nodes are missing from this table
ATTACH '~/Downloads/Archive/DuckDB/ieso/da_lmp.duckdb' AS dalmp;
SELECT location_name
FROM node_table
WHERE location_name NOT IN (SELECT DISTINCT location_name FROM dalmp.da_lmp);


--- Do a full outer join to find all nodes that are missing from the IESO table
COPY (
    WITH tmp AS (
    SELECT DISTINCT location_name
    FROM dalmp.da_lmp
    WHERE dalmp.da_lmp.location_type = 'NODE'
    )
    SELECT node_table.location_name AS ieso_table,
        tmp.location_name AS dalmp_table 
    FROM node_table
    FULL OUTER JOIN tmp
    ON node_table.location_name = tmp.location_name
    WHERE tmp.location_name IS NULL OR node_table.location_name IS NULL
    ORDER BY ieso_table, dalmp_table
) TO '~/Downloads/Archive/DuckDB/ieso/ieso_node_diff.csv';






---==================================================================================================
--- I got this file from IESO directly when I asked for it
--- However, it doesn't have all the nodes that have LMP published 
--- 
CREATE TABLE IF NOT EXISTS node_table (
    location_name VARCHAR NOT NULL,
    location_type ENUM('GEN', 'LOAD') NOT NULL,
    zone_name VARCHAR NOT NULL
);

CREATE TEMPORARY TABLE tmp
AS
    SELECT 
        entity_name AS location_name,  
        resource_type AS location_type, 
        zone_name
    FROM read_csv('/home/adrian/Downloads/Archive/Ieso/NodeTable/Raw/IESO_node_table_2025-06-18.csv',
        columns = {
        'entity_name': "VARCHAR NOT NULL",
        'resource_type': "ENUM('GEN', 'LOAD') NOT NULL",
        'zone_name': "VARCHAR NOT NULL"
        }
    )
;

INSERT INTO node_table
(SELECT * FROM tmp 
WHERE NOT EXISTS (
    SELECT * FROM node_table t
    WHERE t.location_name = tmp.location_name
    )
)
ORDER BY location_name;

