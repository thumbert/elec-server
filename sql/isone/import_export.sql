

SELECT * FROM bidsoffers;


SELECT MIN(HourBeginning) AS MinHourBeginning, 
       MAX(HourBeginning) AS MaxHourBeginning, 
       COUNT(*) AS TotalRecords
FROM bidsoffers;


---How many participants are there?  50 in 2024!
SELECT COUNT(DISTINCT MaskedCustomerId) AS TotalParticipants FROM bidsoffers;  

---Who is the participant with the most transactions?
SELECT MaskedCustomerId, COUNT(*) AS TransactionCount
FROM bidsoffers
GROUP BY MaskedCustomerId
ORDER BY TransactionCount DESC;
-- ┌──────────────────┬──────────────────┐
-- │ MaskedCustomerId │ TransactionCount │
-- │      uint32      │      int64       │
-- ├──────────────────┼──────────────────┤
-- │           850388 │           393510 │
-- │           530232 │           330561 │
-- │           680204 │           206882 │
-- │           567428 │           165318 │
-- │           750576 │           151262 │
-- │           276389 │            93212 │
-- │           473304 │            79944 │
-- │           513694 │            78892 │
-- │           412080 │            70673 │
-- │           596395 │            53280 │
-- │           473638 │            47318 │
-- │           902793 │            47182 │
-- │           288630 │            42066 │
-- │           910093 │            31418 │
-- │           592398 │            26956 │
-- │           848665 │            22758 │

--- How many unique sources and sinks are there?
SELECT DISTINCT MaskedSourceId AS UniqueSources, 
FROM bidsoffers
UNION
SELECT DISTINCT MaskedSinkId AS UniqueSinks
FROM bidsoffers
ORDER BY UniqueSources;
;
-- │ UniqueSources │
-- ├───────────────┤
-- │         10670 │
-- │         28934 │
-- │         46625 │
-- │         75309 │
-- │         80486 │
-- │         85066 │
-- │         97180 │
-- │         97805 |


--- Which source is most frequently used?
SELECT MaskedSourceId, COUNT(*) AS Frequency, ROUND(SUM(Mw)) AS TotalMw
FROM bidsoffers
WHERE Direction = 'IMPORT'
GROUP BY MaskedSourceId
ORDER BY Frequency DESC;
-- ┌────────────────┬───────────┬───────────────┐
-- │ MaskedSourceId │ Frequency │    TotalMw    │
-- │     uint32     │   int64   │ decimal(38,2) │
-- ├────────────────┼───────────┼───────────────┤
-- │          97805 │    921773 │   28577721.00 │
-- │          97180 │    619611 │   30520642.00 │
-- │          46625 │    231645 │   10655656.00 │
-- │          10670 │    143080 │   12078419.00 │
-- │          80486 │     62306 │    7409171.00 │
-- │          85066 │     47342 │    4426666.00 │
-- │          75309 │       144 │       9095.00 │
-- └────────────────┴───────────┴───────────────┘


--- How many unique participants are at each source?
SELECT MaskedSourceId, COUNT(DISTINCT MaskedCustomerId) AS UniqueParticipants
FROM bidsoffers
GROUP BY MaskedSourceId
ORDER BY UniqueParticipants DESC;
-- ┌────────────────┬────────────────────┐
-- │ MaskedSourceId │ UniqueParticipants │
-- │     uint32     │       int64        │
-- ├────────────────┼────────────────────┤
-- │          97805 │                 43 │
-- │          10670 │                 17 │
-- │          97180 │                 11 │
-- │          46625 │                 10 │
-- │          80486 │                  8 │
-- │          85066 │                  2 │
-- │          75309 │                  1 │
-- └────────────────┴────────────────────┘


--- How many unique participants are at each sink?
SELECT MaskedSinkId, COUNT(DISTINCT MaskedCustomerId) AS UniqueParticipants
FROM bidsoffers
WHERE 
GROUP BY MaskedSinkId
ORDER BY UniqueParticipants DESC;

--- Focus on HQ participation.  See average quantity by location in January 2024.
SELECT  strftime(HourBeginning, '%Y-%m-%d') AS Day,
        MaskedSourceId, 
        MaskedSinkId,
        ROUND(SUM(Mw)/24) AS AverageMw
FROM bidsoffers
WHERE MaskedCustomerId = 850388
AND MarketType = 'DA'
AND Direction = 'IMPORT'
AND strftime(HourBeginning, '%Y-%m') = '2024-10'
AND MaskedSinkId = 97180
GROUP BY Day, MaskedSourceId, MaskedSinkId
ORDER BY Day;




--- 46625
--- 80486 is Highgate

--- 97180 is Phase I/II.  
--- On 2024-10-15, HQ started offering 1461 MW from 236 MW on 2024-10-14.  This is consistent with 
--- the TTC limits on those days.


--- How many unique combinations of MaskedSourceId and MaskedSinkId are there?
SELECT DISTINCT MaskedSourceId || ' -> ' || MaskedSinkId AS SourceSink
FROM bidsoffers
ORDER BY SourceSink;
-- |   SourceSink   |
-- |----------------|
-- | 10670 -> 10670 |
-- | 46625 -> 46625 |
-- | 46625 -> 75309 |
-- | 75309 -> 10670 |
-- | 75309 -> 97805 |
-- | 80486 -> 80486 |
-- | 85066 -> 85066 |
-- | 97180 -> 97180 |
-- | 97805 -> 28934 |
-- | 97805 -> 75309 |
-- | 97805 -> 97805 |

--- I don't know what to make of the bids/offers that have source = sink.  



--- Investigate some transactions at the same source and sink
SELECT *
FROM bidsoffers
WHERE MaskedSourceId = 10670 
AND MaskedSinkId = 10670
AND MarketType = 'DA'
AND strftime(HourBeginning, '%Y-%m-%d %H') = '2024-01-01 00';




Create the whole table from scratch
```sql
CREATE TABLE IF NOT EXISTS bidsoffers (
        HourBeginning TIMESTAMPTZ NOT NULL,
        MarketType ENUM('DA', 'RT') NOT NULL,
        MaskedCustomerId UINTEGER NOT NULL,
        MaskedSourceId UINTEGER NOT NULL,
        MaskedSinkId UINTEGER NOT NULL,
        EmergencyFlag BOOLEAN NOT NULL,
        Direction ENUM('IMPORT', 'EXPORT') NOT NULL,
        TransactionType ENUM('FIXED', 'DISPATCHABLE', 'UP-TO CONGESTION') NOT NULL,
        Mw DECIMAL(9,2) NOT NULL,
        Price DECIMAL(9,2),
);

CREATE TEMPORARY TABLE tmp AS
    SELECT unnest(HbImportExports.HbImportExport, recursive := true)
    FROM read_json('/home/adrian/Downloads/Archive/IsoExpress/PricingReports/ImportExport/Raw/2024/hbimportexport_*_2024-01-*.json.gz')
;
-- SELECT * from tmp;


CREATE TEMPORARY TABLE tmp1 AS
    (SELECT 
        BeginDate::TIMESTAMPTZ as HourBeginning,
        MarketType::ENUM('DA', 'RT') as MarketType,
        MaskedCustomerId::UINTEGER as MaskedCustomerId,
        MaskedSourceId::UINTEGER as MaskedSourceId,
        MaskedSinkId::UINTEGER as MaskedSinkId,
        IF(EmergencyFlag = 'Y', TRUE, FALSE) as EmergencyFlag,
        Direction::ENUM('IMPORT', 'EXPORT') as Direction,
        TransactionType::ENUM('FIXED', 'DISPATCHABLE', 'UP-TO CONGESTION') as TransactionType,
        Mw::DECIMAL(9,2) as Mw,
        Price::DECIMAL(9,2) as Price
    FROM tmp
    ORDER BY MarketType, HourBeginning, MaskedCustomerId);


INSERT INTO bidsoffers
(SELECT * FROM tmp1 t
WHERE NOT EXISTS (
    SELECT * FROM bidsoffers b
    WHERE
        b.HourBeginning = t.HourBeginning AND
        b.MarketType = t.MarketType AND
        b.MaskedCustomerId = t.MaskedCustomerId AND
        b.MaskedSourceId = t.MaskedSourceId AND
        b.MaskedSinkId = t.MaskedSinkId AND
        b.EmergencyFlag = t.EmergencyFlag AND
        b.Direction = t.Direction AND
        b.TransactionType = t.TransactionType AND
        b.Mw = t.Mw AND
        b.Price = t.Price
    )    
)
ORDER BY HourBeginning, MarketType, MaskedCustomerId;
```

