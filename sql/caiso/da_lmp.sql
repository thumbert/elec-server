

-- https://oasis.caiso.com/oasisapi/SingleZip?resultformat=6&queryname=PRC_LMP&version=12&startdatetime=20251206T08:00-0000&enddatetime=20251207T08:00-0000&market_run_id=DAM&grp_type=ALL


---========================================================================
LOAD icu;
SET TimeZone = 'America/Los_Angeles';

CREATE TABLE IF NOT EXISTS lmp (
    node_id VARCHAR NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    lmp DECIMAL(18,5) NOT NULL,
);
CREATE INDEX IF NOT EXISTS idx_lmp_node_id ON lmp(node_id);

CREATE TEMPORARY TABLE tmp 
AS 
    SELECT 
        "NODE_ID"::STRING AS node_id,
        "INTERVALSTARTTIME_GMT"::STRING AS hour_beginning,
        "MW"::DECIMAL(18,5) as lmp
    FROM read_csv(
            '/home/adrian/Downloads/Archive/Caiso/DA_LMP/Raw/2025/*_PRC_LMP_DAM_LMP_v12.csv.gz',
            header = true
    )
    ORDER BY node_id, hour_beginning 
;

INSERT INTO lmp
(
    SELECT * FROM tmp
    WHERE NOT EXISTS 
    (
        SELECT 1 FROM lmp 
        WHERE lmp.node_id = tmp.node_id 
        AND lmp.hour_beginning = tmp.hour_beginning
    )
)

