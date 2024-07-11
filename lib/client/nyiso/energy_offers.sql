
INSERT INTO da_energy_offers
FROM read_csv(
    'DaEnergyOffer/month/da_energy_offers_2024-04.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');


SELECT count(*) FROM da_energy_offers;


SELECT * FROM da_energy_offers
LIMIT 1;


SELECT * FROM (
    SELECT "Masked Gen ID", MAX("Upper Oper Limit") as EcoMax, "Masked Bidder ID" 
    FROM da_energy_offers
    WHERE "Date Time" >= '2023-07-28'
    AND "Date Time" < '2023-07-29'
    GROUP BY "Masked Gen ID", "Masked Bidder ID"
    ORDER BY EcoMax DESC
) WHERE EcoMax > 200
AND EcoMax < 350;

-- Get the count of units by participant at one moment in time, focus on participants with 4 units
SELECT * FROM (
    SELECT COUNT("Masked Gen ID") AS count, ROUND(SUM("Upper Oper Limit")) as TotalMW, "Masked Bidder ID" 
    FROM da_energy_offers
    WHERE "Date Time" == '2023-01-01'
    GROUP BY "Masked Bidder ID"
    ORDER BY TotalMW DESC
) WHERE count == 4;

-- Look at one participant Id (Dynergy)
    SELECT "Masked Gen ID", MAX("Upper Oper Limit") as EcoMax, "Masked Bidder ID" 
    FROM da_energy_offers
    WHERE "Date Time" == '2023-01-01'
    AND "Masked Bidder ID" == 78710750
    GROUP BY "Masked Gen ID", "Masked Bidder ID"
    ORDER BY "Masked Gen ID" ASC;



-- How to check that all months got inserted?
SELECT strftime("Date Time", '%Y-%m') AS YEARMON, COUNT(*) 
FROM da_energy_offers
GROUP BY YEARMON
ORDER BY YEARMON;


SELECT DISTINCT "Date Time"
FROM da_energy_offers
ORDER BY "Date Time";






SELECT * 
FROM da_energy_offers
WHERE "Date Time" >= '2024-01-01'
AND "Date Time" < '2024-01-02'
LIMIT 3;

SELECT MAX("Date Time") FROM da_energy_offers;




