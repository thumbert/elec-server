
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
ORDER BY "Date Time" DESC
LIMIT 5;


-----------------------------------------------------------------------
-- Make a small table with one hour only to see how to create the stack
-- focus on DAM only
CREATE TABLE one AS 
    SELECT "Masked Gen ID", "Date Time", 
        "Dispatch $/MW1",
        "Dispatch $/MW2",
        "Dispatch $/MW3",
        "Dispatch $/MW4",
        "Dispatch $/MW5",
        "Dispatch $/MW6",
        "Dispatch $/MW7",
        "Dispatch $/MW8",
        "Dispatch $/MW9",
        "Dispatch $/MW10",
        "Dispatch $/MW11",
        "Dispatch $/MW12",
        "Dispatch MW1" AS MW1, 
        "Dispatch MW2" - "Dispatch MW1" AS MW2, 
        "Dispatch MW3" - "Dispatch MW2" AS MW3, 
        "Dispatch MW4" - "Dispatch MW3" AS MW4, 
        "Dispatch MW5" - "Dispatch MW4" AS MW5, 
        "Dispatch MW6" - "Dispatch MW5" AS MW6, 
        "Dispatch MW7" - "Dispatch MW6" AS MW7, 
        "Dispatch MW8" - "Dispatch MW7" AS MW8, 
        "Dispatch MW9" - "Dispatch MW8" AS MW9, 
        "Dispatch MW10" - "Dispatch MW9" AS MW10, 
        "Dispatch MW11" - "Dispatch MW10" AS MW11, 
        "Dispatch MW12" - "Dispatch MW11" AS MW12,  
    FROM da_energy_offers
    WHERE "Date Time" == '2024-03-31 23:00:00-04:00'
    AND "Market" == 'DAM'
    -- AND "Masked Gen ID" == 67537750
    AND "Masked Bidder ID" == 78710750
;

    SELECT "Masked Gen ID", "Date Time", 
        "Dispatch $/MW1", 
        "Dispatch MW1" AS MW1, 
        "Dispatch MW2" - "Dispatch MW1" AS MW2, 
        "Dispatch MW3" - "Dispatch MW2" AS MW3, 
        "Dispatch MW4" - "Dispatch MW3" AS MW4, 
        "Dispatch MW5" - "Dispatch MW4" AS MW5, 
        "Dispatch MW6" - "Dispatch MW5" AS MW6, 
        "Dispatch MW7" - "Dispatch MW6" AS MW7, 
        "Dispatch MW8" - "Dispatch MW7" AS MW8, 
        "Dispatch MW9" - "Dispatch MW8" AS MW9, 
        "Dispatch MW10" - "Dispatch MW9" AS MW10, 
        "Dispatch MW11" - "Dispatch MW10" AS MW11, 
        "Dispatch MW12" - "Dispatch MW11" AS MW12, 
    FROM one
    WHERE "Date Time" == '2024-03-31 23:00:00-04:00'
    AND "Market" == 'DAM'
    AND "Masked Bidder ID" == 78710750
    ;




-- Unpivot the offers into 3 columns: (Segment, MW, Price)
--
WITH unpivot_alias AS (
    UNPIVOT one
    ON  ("MW1", "Dispatch $/MW1") AS "0", 
        ("MW2", "Dispatch $/MW2") AS "1", 
        ("MW3", "Dispatch $/MW3") AS "2",
        ("MW4", "Dispatch $/MW4") AS "3", 
        ("MW5", "Dispatch $/MW5") AS "4",
        ("MW6", "Dispatch $/MW6") AS "5", 
        ("MW7", "Dispatch $/MW7") AS "6",
        ("MW8", "Dispatch $/MW8") AS "7", 
        ("MW9", "Dispatch $/MW9") AS "8",
        ("MW10", "Dispatch $/MW10") AS "9", 
        ("MW11", "Dispatch $/MW11") AS "10",
        ("MW12", "Dispatch $/MW12") AS "11",
    INTO  
        NAME Segment
        VALUE MW, Price
)
SELECT  "Masked Gen ID", "Date Time", "Segment", "MW", "Price" 
FROM unpivot_alias;





SELECT COUNT(*) FROM one;


SELECT * FROM one
WHERE "Masked Gen ID" == 67537750
;

UNPIVOT 




    SELECT "Masked Gen ID", MAX("Upper Oper Limit") as EcoMax, "Masked Bidder ID" 
    FROM da_energy_offers
    WHERE "Masked Bidder ID" == 78710750
    GROUP BY "Masked Gen ID", "Masked Bidder ID"
    ORDER BY "Masked Gen ID" ASC;








