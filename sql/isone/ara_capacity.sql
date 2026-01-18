

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
);


---=======================================================


CREATE TABLE IF NOT EXISTS bids_offers (
    capability_period VARCHAR NOT NULL,
    auction_type ENUM('ARA1', 'ARA2', 'ARA3') NOT NULL,
    masked_resource_id UINTEGER NOT NULL,
    masked_participant_id UINTEGER NOT NULL,
    masked_capacity_zone_id USMALLINT NOT NULL,
    resource_type ENUM('Import', 'Generating', 'Demand') NOT NULL,
    bid_offer ENUM('Demand_Bid', 'Supply_Offer') NOT NULL,
    segment UTINYINT NOT NULL,
    quantity DECIMAL(9,4) NOT NULL,
    price DECIMAL(9,4) NOT NULL
);

--- Several data transformations are needed to get the data into a normalized form.
--- The data is stored in JSON format with segment quantities and prices as separate fields.
--- 1) unpivot these fields to create rows for each segment.
--- 2) then pivot them back to have segment as a column.
CREATE TEMPORARY TABLE tmp AS (
PIVOT (
    SELECT 
        COLUMNS(* EXCLUDE (pq)),
        string_split(pq, '_')[1]::VARCHAR AS variable,
        string_split(pq, '_')[2]::UTINYINT AS segment,
    FROM (
        UNPIVOT (
            SELECT 
                json_extract(aux, '$.Cp')::VARCHAR as capability_period,
                json_extract_string(aux, '$.AucType')::ENUM('ARA1', 'ARA2', 'ARA3') AS auction_type,
                json_extract(aux, '$.MaskResID')::UINTEGER as masked_resource_id,
                json_extract(aux, '$.MaskLPID')::UINTEGER as  masked_participant_id,
                json_extract(aux, '$.MaskCZID')::USMALLINT as masked_capacity_zone_id,
                json_extract_string(aux, '$.ResType')::ENUM('Import', 'Generating', 'Demand') as resource_type,
                json_extract_string(aux, '$.BidType')::ENUM('Demand_Bid', 'Supply_Offer') as bid_offer,
                json_extract(aux, '$.Seg1Mw')::DECIMAL(9,4) AS quantity_1,
                json_extract(aux, '$.Seg2Mw')::DECIMAL(9,4) AS quantity_2,
                json_extract(aux, '$.Seg3Mw')::DECIMAL(9,4) AS quantity_3,
                json_extract(aux, '$.Seg4Mw')::DECIMAL(9,4) AS quantity_4,
                json_extract(aux, '$.Seg5Mw')::DECIMAL(9,4) AS quantity_5,
                json_extract(aux, '$.Seg1Price')::DECIMAL(9,4) AS price_1,
                json_extract(aux, '$.Seg2Price')::DECIMAL(9,4) AS price_2,
                json_extract(aux, '$.Seg3Price')::DECIMAL(9,4) AS price_3,
                json_extract(aux, '$.Seg4Price')::DECIMAL(9,4) AS price_4,
                json_extract(aux, '$.Seg5Price')::DECIMAL(9,4) AS price_5
            FROM (
                SELECT unnest(Hbfcmaras.Hbfcmara)::JSON as aux
                FROM read_json(
                    '/home/adrian/Downloads/Archive/IsoExpress/Capacity/HistoricalBidsOffers/AnnualReconfigurationAuction/Raw/2025-26/hbfcmara_2025-26_ARA3.json.gz'
                )
            )
        ) ON price_1, quantity_1,
        price_2, quantity_2,
        price_3, quantity_3,
        price_4, quantity_4,
        price_5, quantity_5
        INTO 
            NAME pq
            VALUE value
    )
) ON variable
USING first(value)
);


INSERT INTO bids_offers
    SELECT * FROM tmp t
WHERE NOT EXISTS (
    SELECT * FROM bids_offers b
    WHERE
        b.capability_period = t.capability_period
        AND b.auction_type = t.auction_type
        AND b.masked_resource_id = t.masked_resource_id
        AND b.masked_participant_id = t.masked_participant_id
        AND b.masked_capacity_zone_id = t.masked_capacity_zone_id
        AND b.resource_type = t.resource_type
        AND b.bid_offer = t.bid_offer
        AND b.segment = t.segment
);

