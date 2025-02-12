

--- Delete one month of data (Mar24)
DELETE FROM da_energy_offers 
WHERE HourBeginning >= '2024-03-01'
AND HourBeginning < '2024-04-01';

--- Insert one month of data (Mar24)
INSERT INTO da_energy_offers
FROM read_csv(
    '/home/adrian/Downloads/Archive/IsoExpress/PricingReports/DaEnergyOffer/month/da_energy_offers_2024-03.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');

--- Which months are in the table 
SELECT strftime("HourBeginning", '%Y-%m') AS YEARMON, COUNT(*) 
FROM da_offers
GROUP BY YEARMON
ORDER BY YEARMON;

---
SELECT COUNT(*) FROM da_offers;
SELECT COUNT(*) FROM rt_offers;

--- Select offers for a couple of asset ids
SELECT 
    UnitStatus,
    MaskedAssetId, 
    HourBeginning,
    Segment,
    Quantity,
    Price,
FROM da_offers 
WHERE HourBeginning >= '2024-03-01'
AND HourBeginning <= '2024-03-03'
AND MaskedAssetId in (77459, 86083, 31662)
LIMIT 3;


--- Get the stack for a given hour
SELECT 
    UnitStatus,
    MaskedAssetId, 
    HourBeginning,
    Segment,
    Quantity,
    Price,
FROM da_offers 
WHERE HourBeginning == '2024-03-01'
AND UnitStatus <> 'UNAVAILABLE'
ORDER BY Price;

--- Get the stack for several hours
SELECT 
    UnitStatus,
    MaskedAssetId, 
    HourBeginning,
    Segment,
    Quantity,
    Price,
FROM da_offers 
WHERE UnitStatus <> 'UNAVAILABLE'
AND HourBeginning in ('2024-02-01 00:00:00.000-05:00', '2024-03-01 00:00:00.000-05:00')
ORDER BY HourBeginning, Price;


--- Get the units & participants for one month
SELECT DISTINCT MaskedAssetId, MaskedParticipantId,  strftime(HourBeginning, '%Y-%m') as YEARMON,
FROM da_offers 
WHERE HourBeginning >= '2024-01-01'
AND HourBeginning < '2024-02-01';


--- Find the assets that changed hands between two months (Jan24 and Feb24).  
--- It does not show any 'new' assets!
SELECT  a.MaskedAssetId, a.MaskedParticipantId AS Participant1,  a.YEARMON AS Month1, 
    b.MaskedParticipantId AS Participant2, b.YEARMON AS Month2
FROM (
        SELECT DISTINCT MaskedAssetId, MaskedParticipantId,  strftime(HourBeginning, '%Y-%m') as YEARMON,
        FROM da_offers 
        WHERE HourBeginning >= '2024-03-01'
        AND HourBeginning < '2024-04-01'
    ) as a,
    (
        SELECT DISTINCT MaskedAssetId, MaskedParticipantId,  strftime(HourBeginning, '%Y-%m') as YEARMON,
        FROM da_offers 
        WHERE HourBeginning >= '2024-04-01'
        AND HourBeginning < '2024-05-01' 
    ) as b 
WHERE a.MaskedAssetId = b.MaskedAssetId
AND a.MaskedParticipantId != b.MaskedParticipantId;


--- Find the assets that have changed ownership in a period (here the 4 months Jan24-Apr24)
--- Note that assets sometimes change hands in the middle of the month!
SELECT * FROM (
    SELECT COUNT(*) AS Total, MaskedAssetId FROM (
        SELECT DISTINCT MaskedAssetId, MaskedParticipantId,  strftime(HourBeginning, '%Y-%m') as YEARMON,
        FROM da_offers 
        WHERE HourBeginning >= '2024-01-01'
        AND HourBeginning < '2024-05-01'
        ORDER BY MaskedAssetId, YEARMON
    )
    GROUP BY MaskedAssetId
)
WHERE Total != 4;


--- Find the ownership of a given asset by month
SELECT DISTINCT MaskedParticipantId,  strftime(HourBeginning, '%Y-%m') as YEARMON,
FROM da_offers 
WHERE HourBeginning >= '2022-01-01'
AND HourBeginning < '2024-05-01'
AND MaskedAssetId = 57986
ORDER BY YEARMON;

SELECT * FROM da_offers
WHERE MaskedAssetId = 77459
AND HourBeginning >= '2024-01-01'
AND HourBeginning < '2024-05-01'
AND UnitStatus = 'UNAVAILABLE'
LIMIT 5;

--- Get all the units for a market participant
SELECT DISTINCT MaskedAssetId, strftime(HourBeginning, '%Y-%m') as YEARMON,
FROM da_offers 
WHERE HourBeginning >= '2022-01-01'
AND HourBeginning < '2024-05-01'
AND MaskedParticipantId = 953967
ORDER BY YEARMON, MaskedAssetId;


--- Find new assets and assets that changed hands
SELECT * FROM (
    SELECT MaskedAssetId, MaskedParticipantId, MIN(HourBeginning) as StartDate, MAX(EcoMax) as EcoMax
    FROM da_offers
    GROUP BY MaskedAssetId, MaskedParticipantId
) 
WHERE StartDate > '2024-01-01'
ORDER BY StartDate;


--- Find start date for an asset
SELECT * FROM (
    SELECT MaskedAssetId, MIN(HourBeginning) as StartDate, MAX(EcoMax) as EcoMax
    FROM da_offers
    GROUP BY MaskedAssetId
) 
WHERE StartDate > '2024-01-01'
ORDER BY StartDate;
