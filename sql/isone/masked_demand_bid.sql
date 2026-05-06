
--- there are 50 segments!
SELECT DISTINCT segment, COUNT(*) AS count
FROM da_bids
GROUP BY segment
ORDER BY segment;
-- ┌─────────┬──────────┐
-- │ segment │  count   │
-- │  uint8  │  int64   │
-- ├─────────┼──────────┤
-- │       1 │ 17278341 │
-- │       2 │  2850358 │
-- │       3 │  1870266 │
-- │       4 │  1369609 │
-- │       5 │  1153054 │
-- │       6 │   424343 │
-- │       7 │   152488 │
-- │       8 │   111433 │
-- │       9 │    84936 │
-- │      10 │    61573 │
-- │      11 │    44913 │
-- │      12 │    36531 │
-- │      13 │    27856 │
-- │      14 │    22403 │
-- │      15 │    17084 │
-- │      16 │    12832 │
-- │      17 │     9658 │
-- │      18 │     7632 │
-- │      19 │     4724 │
-- │      20 │     3653 │
-- │       · │        · │
-- │       · │        · │
-- │       · │        · │
-- │      31 │       88 │
-- │      32 │       66 │
-- │      33 │       49 │
-- │      34 │       44 │
-- │      35 │       39 │
-- │      36 │       32 │
-- │      37 │       16 │
-- │      38 │       15 │
-- │      39 │       12 │
-- │      40 │       10 │
-- │      41 │        7 │
-- │      42 │        5 │
-- │      43 │        4 │
-- │      44 │        4 │
-- │      45 │        4 │
-- │      46 │        4 │
-- │      47 │        1 │
-- │      48 │        1 │
-- │      49 │        1 │
-- │      50 │        1 │
-- ├─────────┴──────────┤


SELECT * FROM da_bids LIMIT 5;

SELECT *
FROM da_bids
WHERE hourBeginning = '2025-06-01 00:00:00-04:00'
AND bidType = 'DEC';


SELECT 
    MaskedParticipantId,
    MaskedAssetId, 
    BidType,
    HourBeginning,
    Segment,
    Price,
    MW AS Quantity
FROM da_bids
WHERE HourBeginning >= '2025-06-01 00:00:00.000-04:00'
AND HourBeginning < '2025-06-02 00:00:00.000-04:00'   
AND "MaskedParticipantId" = 504170 
AND "BidType" in ('PRICE', 'FIXED') 
ORDER BY "MaskedAssetId", "HourBeginning";


SELECT hourBeginning, strftime(hourBeginning, '%Y-%m-%d'), maskedParticipantId, segment, mw 
FROM da_bids
WHERE hourBeginning >= '2022-01-01'
AND hourBeginning < '2022-02-01'
AND bidType in ('FIXED', 'PRICE')
AND locationType = 'LOAD ZONE'
AND maskedParticipantId in (504170, 212494);



--- Get daily average MW for all participants,  aggregated over all zones
SELECT strftime(hourBeginning, '%Y-%m-%d')::DATE as day, 
    maskedParticipantId, 
    sum(mw) as mw
FROM da_bids
WHERE hourBeginning >= '2022-01-01'
AND hourBeginning < '2022-02-01'
AND bidType in ('FIXED', 'PRICE')
AND locationType = 'LOAD ZONE'
AND maskedParticipantId in (504170, 212494)
GROUP BY day, maskedParticipantId
ORDER BY maskedParticipantId, day;

--- Get daily average MW for all participants,  aggregated over all zones
SELECT strftime(hourBeginning, '%Y-%m-%d')::DATE as day, 
    maskedParticipantId, 
    maskedAssetId,
    sum(mw) as mw
FROM da_bids
WHERE hourBeginning >= '2022-01-01'
AND hourBeginning < '2022-02-01'
AND bidType in ('FIXED', 'PRICE')
AND locationType = 'LOAD ZONE'
AND maskedParticipantId in (504170, 212494)
GROUP BY day, maskedParticipantId, maskedAssetId
ORDER BY maskedParticipantId, maskedAssetId, day;



SELECT strftime(hourBeginning, '%Y-%m-%d')::DATE as day, 
    maskedParticipantId, 
    round(sum(mw)/24) as mw
FROM da_bids
WHERE hourBeginning >= '2022-01-01'
AND hourBeginning < '2022-02-01'
AND bidType in ('FIXED', 'PRICE')
AND locationType = 'LOAD ZONE'
GROUP BY day, maskedParticipantId
ORDER BY maskedParticipantId, day
VISUALIZE day AS x, mw AS y, maskedParticipantId AS color
DRAW line
SCALE ORDINAL color;


SELECT 1 as x, 2 as y VISUALIZE x, y DRAW point;



--- Get daily average MW for all participants, pivot so that each participant is a column
duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/isone/masked_demand_bids.duckdb' AS db;
PIVOT (
    SELECT strftime(hourBeginning, '%Y-%m-%d')::DATE as day, 
        maskedParticipantId, 
        round(sum(mw)/24) as mw
    FROM db.da_bids
    WHERE hourBeginning >= '2023-01-01'
    AND hourBeginning < '2026-02-01'
    AND bidType in ('FIXED', 'PRICE')
    AND locationType = 'LOAD ZONE'
    -- AND maskedParticipantId in (504170, 212494)
    GROUP BY day, maskedParticipantId
)
ON maskedParticipantId
USING
    MAX(mw) AS mw
ORDER BY day;
" | qplot --config='{"height": 900}'


PIVOT (
    SELECT strftime(hourBeginning, '%Y-%m-%d')::DATE as day, 
        maskedParticipantId, 
        round(sum(mw)/24) as mw
    FROM da_bids
    WHERE hourBeginning >= '2022-01-01'
    AND hourBeginning < '2022-02-01'
    AND bidType in ('FIXED', 'PRICE')
    AND locationType = 'LOAD ZONE'
    AND maskedParticipantId in (504170, 212494)
    GROUP BY day, maskedParticipantId
)
ON maskedParticipantId
USING
    MAX(mw) AS mw
ORDER BY day;







--==========================================================================================
CREATE TABLE IF NOT EXISTS da_bids (
    hourBeginning TIMESTAMPTZ NOT NULL,
    maskedParticipantId UINTEGER NOT NULL,
    maskedLocationId UINTEGER NOT NULL,
    locationType ENUM('HUB', 'LOAD ZONE', 'NETWORK NODE', 'DRR AGGREGATION ZONE') NOT NULL,
    bidType ENUM('FIXED', 'INC', 'DEC', 'PRICE') NOT NULL,
    bidID UINTEGER NOT NULL,
    segment UTINYINT NOT NULL,
    price FLOAT,
    mw FLOAT NOT NULL,
);

SELECT *
FROM read_csv(
    '~/Downloads/Archive/IsoExpress/PricingReports/DaDemandBid/month/da_demand_bids_2022-01.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');


--- Decrement all segments by 1 to make them 0-based instead of 1-based!
BEGIN TRANSACTION;
UPDATE da_bids
SET segment = segment - 1
WHERE segment > 0;
COMMIT;

-- quick check
SELECT DISTINCT segment FROM da_bids ORDER BY segment;
