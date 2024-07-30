

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
WHERE month >= 202401
AND month <= 202407;


SELECT DISTINCT month 
FROM results_zone
ORDER BY month;


SELECT * FROM results_interface LIMIT 5;



CREATE TABLE stats (
    name ENUM('CA', 'NY'),
    value INTEGER,
);
INSERT INTO stats VALUES ('CA', 10), ('CA', 20), ('NY', 4);




