

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
    masked_participant_id UINTEGER NOT NULL,
    masked_capacity_zone_id UINTEGER NOT NULL,
    masked_interface_id UINTEGER,
    resource_type ENUM('Generating', 'Demand', 'Import') NOT NULL,
    bid_type ENUM('Demand_Bid', 'Supply_Offer') NOT NULL,
    segment UTINYINT NOT NULL, -- 0-4
    mw DECIMAL(9,4) NOT NULL,
    price DECIMAL(9,4) NOT NULL
); 

CREATE TEMPORARY TABLE tmp AS
    SELECT 
        cp AS capacity_period,
        AucType AS auction_type,
        MaskResId AS masked_resource_id,
        MaskLPID AS masked_participant_id,
        MaskCzid AS masked_capacity_zone_id,
        MaskIntfcId AS masked_interface_id,
        ResType AS resource_type,
        BidType AS bid_type,
        Seg1Mw,
        Seg1Price,
        Seg2Mw,
        Seg2Price,
        Seg3Mw,
        Seg3Price,
        Seg4Mw,
        Seg4Price,
        Seg5Mw,
        Seg5Price
    FROM (
        SELECT unnest(Hbfcmaras.Hbfcmara, recursive := true)
        FROM read_json('~/Downloads/Archive/IsoExpress/Capacity/HistoricalBidsOffers/AnnualReconfigurationAuction/Raw/2025-26/hbfcmara_2025-26_ARA1.json.gz')
    )
;
-- SELECT * from tmp;

--- transpose the segments into rows, and filter out the nulls
CREATE TEMPORARY TABLE tmp1 AS (
    SELECT
        w.capacity_period,
        w.auction_type,
        w.masked_resource_id,
        w.masked_capacity_zone_id,
        w.masked_participant_id,
        w.masked_interface_id,
        w.resource_type,
        w.bid_type,
        v.seg_num AS segment,
        v.mw,
        v.price
    FROM tmp w
    CROSS JOIN LATERAL (
        VALUES
            (0, w.Seg1Mw, w.Seg1Price),
            (1, w.Seg2Mw, w.Seg2Price),
            (2, w.Seg3Mw, w.Seg3Price),
            (3, w.Seg4Mw, w.Seg4Price),
            (4, w.Seg5Mw, w.Seg5Price)

    ) AS v(seg_num, mw, price)
    WHERE v.mw IS NOT NULL
    ORDER BY w.capacity_period, w.auction_type, w.masked_resource_id, w.bid_type, v.seg_num
);


INSERT INTO bids_offers
(SELECT * FROM tmp1
WHERE NOT EXISTS (
        SELECT * FROM bids_offers d
        WHERE d.capacity_period = tmp1.capacity_period
        AND d.auction_type = tmp1.auction_type
        AND d.masked_resource_id = tmp1.masked_resource_id
        AND d.segment = tmp1.segment
        AND d.bid_type = tmp1.bid_type
    )
)
ORDER BY capacity_period, auction_type, masked_resource_id, bid_type, segment;








