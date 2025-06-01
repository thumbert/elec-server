
CREATE TABLE IF NOT EXISTS Locations (
    type ENUM('AREA', 'ZONE', 'NODE') NOT NULL,
    name VARCHAR NOT NULL
);

SET VARIABLE day = DATE '2025-05-03';
CREATE TEMPORARY TABLE tmp AS
    SELECT * FROM read_csv(
        CONCAT('/home/adrian/Downloads/Archive/Ieso/NodeTable/Raw/node_table_', getvariable('day'), '.csv'), 
        header = true,
        columns = {
            'type': "ENUM('AREA', 'ZONE', 'NODE') NOT NULL",
            'name': 'VARCHAR NOT NULL'
        })
;
 
INSERT INTO locations
    SELECT 
        type, name,
    FROM tmp
EXCEPT 
    SELECT * FROM locations
ORDER BY type, name;

SELECT * FROM locations
WHERE location_type != 'NODE';












INSERT OR IGNORE  INTO Locations VALUES (0, 'AREA', 'Ontario');
INSERT OR IGNORE INTO Locations VALUES (1, 'ZONE', 'EAST');
INSERT OR IGNORE INTO Locations VALUES (2, 'ZONE', 'ESSA');
INSERT OR IGNORE INTO Locations VALUES (3, 'ZONE', 'NIAGARA');
INSERT OR IGNORE INTO Locations VALUES (4, 'ZONE', 'NORTHEAST');
INSERT OR IGNORE INTO Locations VALUES (5, 'ZONE', 'NORTHWEST');
INSERT OR IGNORE INTO Locations VALUES (6, 'ZONE', 'OTTAWA');
INSERT OR IGNORE INTO Locations VALUES (7, 'ZONE', 'SOUTHWEST');
INSERT OR IGNORE INTO Locations VALUES (8, 'ZONE', 'TORONTO');
INSERT OR IGNORE INTO Locations VALUES (9, 'ZONE', 'WEST');
    

CREATE SEQUENCE IF NOT EXISTS nodes_seq START WITH 101 INCREMENT BY 1;

SELECT a.*, b.*
FROM (
    SELECT 
            'NODE' as location_type
    ) as a
    CROSS JOIN (
        SELECT 
            nextval(nodes_seq) as id,
            *
        FROM (
            SELECT DISTINCT "Pricing Location" as location_name
            FROM read_csv(
                    CONCAT(
                        '/home/adrian/Downloads/Archive/Ieso/DaLmp/Node/Raw/2025/PUB_DAHourlyEnergyLMP_',
                        strftime(getvariable('day'), '%Y%m%d'),
                        '.csv.gz'
                    ),
                    header = true,
                    skip = 1
                )
        )
    ) as b
;




            SELECT 
                DISTINCT "Pricing Location" as location_name
            FROM read_csv(
                    CONCAT(
                        '/home/adrian/Downloads/Archive/Ieso/DaLmp/Node/Raw/2025/PUB_DAHourlyEnergyLMP_',
                        strftime(getvariable('day'), '%Y%m%d'),
                        '.csv.gz'
                    ),
                    header = true,
                    skip = 1
                );
