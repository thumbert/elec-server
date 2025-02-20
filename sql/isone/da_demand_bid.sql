
SELECT hourBeginning, strftime(hourBeginning, '%Y-%m-%d'), maskedParticipantId, segment, mw 
FROM da_bids
WHERE hourBeginning >= '2022-01-01'
AND hourBeginning < '2022-02-01'
AND bidType in ('FIXED', 'PRICE')
AND locationType = 'LOAD ZONE'
AND maskedParticipantId in (504170, 212494);

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
ORDER BY maskedParticipantId, day;









--==========================================================================================
CREATE TABLE IF NOT EXISTS da_bids (
    hourBeginning TIMESTAMPTZ NOT NULL,
    maskedParticipantId UINTEGER NOT NULL,
    maskedAssetId UINTEGER NOT NULL,
    locationType ENUM('HUB', 'LOAD ZONE', 'NETWORK NODE', 'DRR AGGREGATION ZONE') NOT NULL,
    bidType ENUM('FIXED', 'INC', 'DEC', 'PRICE') NOT NULL,
    bidID UINTEGER NOT NULL,
    segment UTINYINT NOT NULL,
    price FLOAT,
    mw FLOAT NOT NULL,
);

INSERT INTO da_bids
FROM read_csv(
    '~/Downloads/Archive/IsoExpress/PricingReports/DaDemandBid/month/da_demand_bids_2022-01.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');


