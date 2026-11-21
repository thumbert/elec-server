
SELECT min(time_stamp), max(time_stamp), count(*)
FROM load_actual;

SELECT * FROM load_actual
WHERE ptid = 61752;





---=======================================================================
CREATE TABLE IF NOT EXISTS load_actual (
    time_stamp TIMESTAMPTZ NOT NULL,
    ptid INTEGER NOT NULL,
    load DECIMAL(9,4) NOT NULL
);





CREATE TEMPORARY TABLE tmp
AS (
    SELECT 
        CASE "Time Zone"
            WHEN 'EST' THEN strptime("Time Stamp" || ' -0500', '%m/%d/%Y %H:%M:%S %z')::TIMESTAMPTZ
            WHEN 'EDT' THEN strptime("Time Stamp" || ' -0400', '%m/%d/%Y %H:%M:%S %z')::TIMESTAMPTZ
            ELSE NULL
        END AS time_stamp,
        "PTID"::INTEGER AS ptid,
        "Load"::DECIMAL(9,4) AS load
    FROM read_csv('/home/adrian/Downloads/Archive/Nyiso/LoadActual/Raw/20251102pal.csv', 
        header = true, 
        types = {
            "Time Stamp": 'VARCHAR',
            "Time Zone": 'VARCHAR',
            "PTID": 'INTEGER',
            "Load": 'DECIMAL(9,4)'
        }
    )
);


INSERT INTO load_actual
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM load_actual d
        WHERE
            d.time_stamp = t.time_stamp AND
            d.ptid = t.ptid AND
            d.load = t.load
    )
);


