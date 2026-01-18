

SELECT * FROM bids_offers LIMIT 10;

SELECT DISTINCT month 
FROM bids_offers
ORDER BY month;


SELECT month,
    capacityZoneId,
    capacityZoneType,
    capacityZoneName,
    supplyOffersSubmitted,
    demandBidsSubmitted,
    supplyOffersCleared,
    demandBidsCleared,
    netCapacityCleared,
    clearingPrice
FROM results_zone 
WHERE month == 202401;



SELECT DISTINCT month 
FROM results_zone
ORDER BY month;


SELECT * FROM results_interface LIMIT 5;

--- get the stack for one zone one month
--- not worth having an api for that.  Just grab the data directly.
SELECT *, row_number() OVER (PARTITION BY bidOffer) as Idx,
FROM (
    SELECT bidOffer, maskedResourceId, segment, quantity, price 
    FROM bids_offers
    WHERE month == 202403
    AND maskedCapacityZoneId == 8506
    AND bidOffer == 'bid'
    ORDER BY bidOffer, price DESC
)
UNION ALL
SELECT *, row_number() OVER (PARTITION BY bidOffer) as Idx,
FROM (
    SELECT bidOffer, maskedResourceId, segment, quantity, price 
    FROM bids_offers
    WHERE month == 202403
    AND maskedCapacityZoneId == 8506
    AND bidOffer == 'offer'
    ORDER BY bidOffer, price
)
;


---==========================================================================
--- https://webservices.iso-ne.com/api/v1.1/hbfcmara/cp/2025-26/ara/ARA3
CREATE TABLE IF NOT EXISTS bids_offers (
    capacity_period VARCHAR NOT NULL, 
    auction_type ENUM('ARA1', 'ARA2', 'ARA3') NOT NULL,
    masked_resource_id UINTEGER NOT NULL,
    masked_capacity_zone_id UINTEGER NOT NULL,
    resource_type ENUM('Generating') NOT NULL,
    bid_type ENUM('Demand_Bid', 'Supply_Offer') NOT NULL,
    segment UTINYINT NOT NULL, -- 0-4
    mw DECIMAL(9,4) NOT NULL,
    price DECIMAL(9,4) NOT NULL,
) 

CREATE TEMPORARY TABLE tmp AS
    SELECT 
        BeginDate::TIMESTAMPTZ AS hour_beginning,
        "@LocId"::UINTEGER AS ptid,
        ActInterchange::DECIMAL(9,2) AS Net,
        Purchase::DECIMAL(9,2) AS Purchase,
        Sale::DECIMAL(9,2) AS Sale
    FROM (
        SELECT unnest(Hbfcmaras.Hbfcmara, recursive := true)
        FROM read_json('~/Downloads/Archive/IsoExpress/ActualInterchange/Raw/2025/act_interchange_2025*.json.gz')
    )
ORDER BY hour_beginning, ptid
;
-- SELECT * from tmp;

INSERT INTO flows
(SELECT * FROM tmp 
WHERE NOT EXISTS (
    SELECT * FROM flows d
    WHERE d.hour_beginning = tmp.hour_beginning
    AND d.ptid = tmp.ptid
    )
)
ORDER BY hour_beginning, ptid;








