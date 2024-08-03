

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

--  Which months are in the table 
SELECT strftime("HourBeginning", '%Y-%m') AS YEARMON, COUNT(*) 
FROM rt_offers
GROUP BY YEARMON
ORDER BY YEARMON;

--
SELECT COUNT(*) FROM da_offers;
SELECT COUNT(*) FROM rt_offers;
