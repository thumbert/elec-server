select * from ptid_table;

SELECT * from ptid_table
WHERE node_type = 'zone';


---=======================================================================
--- Add an asof column to the ptid_table to track when a new ptid was added.
SET VARIABLE asof_date = CURRENT_DATE;
SET VARIABLE asof_date = DATE '2026-06-06';

CREATE TABLE IF NOT EXISTS ptid_table (
    node_type ENUM('hub', 'generator', 'load', 'load_zone', 'aggregation_zone', 'reserve_zone', 'interface') NOT NULL,
    ptid INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    zone_id INTEGER,
    reserve_id INTEGER,
    rsp_area VARCHAR,
    dispatch_zone VARCHAR,
    dr_reserve_aggregation_zone_id INTEGER,
    latitude DOUBLE,
    longitude DOUBLE,
    "asof" DATE NOT NULL
);

INSERT INTO ptid_table
   VALUES 
   ('zone', 61752, 'Zone A', NULL, NULL, 'WEST', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61753, 'Zone B', NULL, NULL, 'GENESE', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61754, 'Zone C', NULL, NULL, 'CENTRL', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61755, 'Zone D', NULL, NULL, 'NORTH', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61756, 'Zone E', NULL, NULL, 'MHK VL', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61757, 'Zone F', NULL, NULL, 'CAPITL', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61758, 'Zone G', NULL, NULL, 'HUD VL', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61759, 'Zone H', NULL, NULL, 'MILLWD', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61760, 'Zone I', NULL, NULL, 'DUNWOD', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61761, 'Zone J', NULL, NULL, 'N.Y.C.', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61762, 'Zone K', NULL, NULL, 'LONGIL', NULL, NULL, true, getvariable('asof_date')),
   ---
   ('zone', 61844, 'H Q', NULL, NULL, 'H Q', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61845, 'NPX', NULL, NULL, 'NPX', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61846, 'O H', NULL, NULL, 'O H', NULL, NULL, true, getvariable('asof_date')),
   ('zone', 61847, 'PJM', NULL, NULL, 'PJM', NULL, NULL, true, getvariable('asof_date'))
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
        end AS active,
        CAST('2026-06-06' AS DATE) AS asof
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

--- update the active status of existing ptids (if it has changed)
UPDATE ptid_table p
SET active = t.active,
    "asof" = t.asof
FROM tmp t
WHERE p.ptid = t.ptid
  AND p.active IS DISTINCT FROM t.active;


--- get the new ptids
SELECT t.*
FROM tmp AS t
LEFT JOIN ptid_table AS p ON p.ptid = t.ptid
WHERE p.ptid IS NULL
AND p.asof IS NULL
ORDER BY t.ptid;

--- get the ptids that have changed active status
SELECT p.*, t.active AS new_active
FROM ptid_table p
JOIN tmp t ON p.ptid = t.ptid
WHERE p.active IS DISTINCT FROM t.active
ORDER BY p.ptid;