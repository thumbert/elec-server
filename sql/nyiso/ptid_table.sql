select * from ptid_table limit 5;

SELECT * from ptid_table
WHERE node_type = 'zone';


---=======================================================================
CREATE TABLE IF NOT EXISTS ptid_table (
    node_type ENUM('gen', 'zone') NOT NULL,
    ptid INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    aggregation_ptid INTEGER,
    subzone VARCHAR,
    zone VARCHAR NOT NULL,
    latitude DOUBLE,
    longitude DOUBLE,
    active BOOLEAN NOT NULL
);

INSERT INTO ptid_table
   VALUES 
   ('zone', 61752, 'Zone A', NULL, NULL, 'WEST', NULL, NULL, true),
   ('zone', 61753, 'Zone B', NULL, NULL, 'GENESE', NULL, NULL, true),
   ('zone', 61754, 'Zone C', NULL, NULL, 'CENTRL', NULL, NULL, true),
   ('zone', 61755, 'Zone D', NULL, NULL, 'NORTH', NULL, NULL, true),
   ('zone', 61756, 'Zone E', NULL, NULL, 'MHK VL', NULL, NULL, true),
   ('zone', 61757, 'Zone F', NULL, NULL, 'CAPITL', NULL, NULL, true),
   ('zone', 61758, 'Zone G', NULL, NULL, 'HUD VL', NULL, NULL, true),
   ('zone', 61759, 'Zone H', NULL, NULL, 'MILLWD', NULL, NULL, true),
   ('zone', 61760, 'Zone I', NULL, NULL, 'DUNWOD', NULL, NULL, true),
   ('zone', 61761, 'Zone J', NULL, NULL, 'N.Y.C.', NULL, NULL, true),
   ('zone', 61762, 'Zone K', NULL, NULL, 'LONGIL', NULL, NULL, true),
   ---
   ('zone', 61844, 'H Q', NULL, NULL, 'H Q', NULL, NULL, true),
   ('zone', 61845, 'NPX', NULL, NULL, 'NPX', NULL, NULL, true),
   ('zone', 61846, 'O H', NULL, NULL, 'O H', NULL, NULL, true),
   ('zone', 61847, 'PJM', NULL, NULL, 'PJM', NULL, NULL, true)
;

CREATE TEMPORARY TABLE tmp
AS (
    SELECT 
        'gen' AS node_type,
        CAST("Generator PTID" AS INTEGER) AS ptid,
        "Generator Name" AS name,
        CAST("Aggregation PTID" AS INTEGER) AS aggregation_ptid,
        "Subzone" AS subzone,
        "Zone" AS zone,
        CAST("Latitude" AS DOUBLE) AS latitude,
        CAST("Longitude" AS DOUBLE) AS longitude,
        case "Active"
            when 'Y' then true
            when 'N' then false
            else NULL
        end AS active
    FROM read_csv('/home/adrian/Downloads/Archive/Nyiso/PnodeTable/Raw/generator_2026-06-06.csv', 
        header = true)
);

INSERT INTO ptid_table
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM ptid_table d
        WHERE
            d.ptid = t.ptid
    )
);



