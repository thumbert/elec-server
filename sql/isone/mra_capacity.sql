

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










