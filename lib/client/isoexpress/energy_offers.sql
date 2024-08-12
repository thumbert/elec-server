

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
FROM rt_offers
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


