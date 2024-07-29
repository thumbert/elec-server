
INSERT INTO da_offers
FROM read_csv(
    'DaEnergyOffer/month/da_energy_offers_2024-04.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');


SELECT count(*) FROM da_offers;


SELECT * FROM da_offers
LIMIT 3;


SELECT * FROM (
    SELECT "Masked Gen ID", MAX("Upper Oper Limit") as EcoMax, "Masked Bidder ID" 
    FROM da_offers
    WHERE "Date Time" >= '2023-07-28'
    AND "Date Time" < '2023-07-29'
    GROUP BY "Masked Gen ID", "Masked Bidder ID"
    ORDER BY EcoMax DESC
) WHERE EcoMax > 200
AND EcoMax < 350;

-- Get the count of units by participant at one moment in time, focus on participants with 4 units
SELECT * FROM (
    SELECT COUNT("Masked Gen ID") AS count, ROUND(SUM("Upper Oper Limit")) as TotalMW, "Masked Bidder ID" 
    FROM da_offers
    WHERE "Date Time" == '2023-01-01'
    GROUP BY "Masked Bidder ID"
    ORDER BY TotalMW DESC
) WHERE count == 4;


-- Look at one participant Id (Dynergy)
    SELECT "Masked Gen ID", MAX("Upper Oper Limit") as EcoMax, "Masked Bidder ID" 
    FROM da_offers
    WHERE "Date Time" == '2023-01-01'
    AND "Masked Bidder ID" == 78710750
    GROUP BY "Masked Gen ID", "Masked Bidder ID"
    ORDER BY "Masked Gen ID" ASC;



--  Which months are in the table
SELECT strftime("Date Time", '%Y-%m') AS YEARMON, COUNT(*) 
FROM da_offers
GROUP BY YEARMON
ORDER BY YEARMON;

-- Delete one month from the table
DELETE FROM da_offers
WHERE "Date Time" >= '2024-03-01T00:00:00-05:00'
AND "Date Time" < '2024-04-01T00:00:00-04:00';


SELECT DISTINCT "Date Time"
FROM da_offers
ORDER BY "Date Time" DESC
LIMIT 5;


-----------------------------------------------------------------------
--- Query to get the offers for several units between a start/end date
---
WITH unpivot_alias AS (
    UNPIVOT (
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
        FROM da_offers
        WHERE "Date Time" >= '2024-03-01 00:00:00-05:00'
        AND "Date Time" < '2024-03-01 23:00:00-05:00'
        AND "Masked Gen ID" in (35537750, 55537750, 67537750, 75537750)
        AND "Market" == 'DAM'
    )
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
SELECT "Masked Gen ID", 
    "Date Time", 
    CAST("Segment" as UTINYINT) AS Segment, 
    "MW", "Price", 
FROM unpivot_alias
ORDER BY "Masked Gen ID", "Date Time", "Price" LIMIT 3;




-----------------------------------------------------------------------
--- Query to calculate the stack 
--- 1) Calculate the incremental MW from one segment to another
--- 2) Unpivot the result by (MW, Price, Segment)
--- 3) Add a row index by "Date Time"
--- 4) Calculate the running sum down this row index 
WITH unpivot_alias AS (
    UNPIVOT (
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
            ROUND("Dispatch MW2" - "Dispatch MW1", 1) AS MW2, 
            ROUND("Dispatch MW3" - "Dispatch MW2", 1) AS MW3, 
            ROUND("Dispatch MW4" - "Dispatch MW3", 1) AS MW4, 
            ROUND("Dispatch MW5" - "Dispatch MW4", 1) AS MW5, 
            ROUND("Dispatch MW6" - "Dispatch MW5", 1) AS MW6, 
            ROUND("Dispatch MW7" - "Dispatch MW6", 1) AS MW7, 
            ROUND("Dispatch MW8" - "Dispatch MW7", 1) AS MW8, 
            ROUND("Dispatch MW9" - "Dispatch MW8", 1) AS MW9, 
            ROUND("Dispatch MW10" - "Dispatch MW9", 1) AS MW10, 
            ROUND("Dispatch MW11" - "Dispatch MW10", 1) AS MW11, 
            ROUND("Dispatch MW12" - "Dispatch MW11", 1) AS MW12,  
        FROM da_offers
        WHERE "Date Time" >= '2024-03-01 00:00:00-05:00'
        AND "Date Time" < '2024-03-01 23:00:00-05:00'
        AND "Market" == 'DAM'
    )
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
SELECT *, 
    ROUND(SUM("MW") OVER (PARTITION BY "Date Time" ORDER BY "Idx"), 1) AS "cum_MW"   
FROM (
    SELECT *,
        row_number() OVER (PARTITION BY "Date Time") AS "Idx",
    FROM (
        SELECT "Masked Gen ID", 
            "Date Time", 
            CAST("Segment" as UTINYINT) AS Segment, 
            "MW", "Price", 
        FROM unpivot_alias
        ORDER BY "Date Time" ASC, Price ASC
    )
)
ORDER BY "Date Time", "Idx";



DROP TABLE ts;
CREATE TABLE ts (timestamp TIMESTAMPTZ);
INSERT INTO ts VALUES ('2024-03-01T00:00:00.000-05:00');
INSERT INTO ts VALUES ('2024-03-01T00:00:00.000Z');
SELECT timestamp, epoch_ms(timestamp) FROM ts;
┌──────────────────────────┬───────────────────────┐
│        timestamp         │ epoch_ms("timestamp") │
│ timestamp with time zone │         int64         │
├──────────────────────────┼───────────────────────┤
│ 2024-03-01 00:00:00-05   │         1709269200000 │
│ 2024-02-29 19:00:00-05   │         1709251200000 │
└──────────────────────────┴───────────────────────┘
SELECT * FROM (
    SELECT timestamp, epoch_ms(timestamp)
    FROM ts
)
WHERE timestamp == '2024-03-01T00:00:00.000-05:00';



-- If you do the same thing with a TIMESTAMP column
DROP TABLE ts2;
CREATE TABLE ts2 (timestamp TIMESTAMP);
INSERT INTO ts2 VALUES ('2024-03-01T00:00:00.000-05:00');
INSERT INTO ts2 VALUES ('2024-03-01T00:00:00.000Z');
SELECT timestamp, epoch_ms(timestamp) FROM ts2;
┌─────────────────────┬───────────────────────┐
│      timestamp      │ epoch_ms("timestamp") │
│      timestamp      │         int64         │
├─────────────────────┼───────────────────────┤
│ 2024-03-01 05:00:00 │         1709269200000 │
│ 2024-03-01 00:00:00 │         1709251200000 │
└─────────────────────┴───────────────────────┘
SELECT * FROM (
    SELECT timestamp, epoch_ms(timestamp)
    FROM ts2
)
WHERE timestamp == '2024-03-01T00:00:00.000-05:00';
-- correctly selects the hour zero in America/New_York
┌─────────────────────┬───────────────────────┐
│      timestamp      │ epoch_ms("timestamp") │
│      timestamp      │         int64         │
├─────────────────────┼───────────────────────┤
│ 2024-03-01 05:00:00 │         1709269200000 │
└─────────────────────┴───────────────────────┘




















-----------------------------------------------------------------------
-- Make a small table with one hour only to see how to create the stack
-- * Filter on DAM offers only, 
-- * Calculate the incremental MW quantities 
DROP TABLE IF EXISTS one;
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
    FROM da_offers
    WHERE "Date Time" == '2024-03-01 00:00:00-05:00'
    -- AND "Date Time" < '2024-03-04 00:00:00-05:00'
    AND "Market" == 'DAM'
    -- AND "Masked Bidder ID" == 78710750
;
select * from one limit 10;

-- Create the stack table.  This is done in 2 steps:
-- Step (1)
--   * Unpivot the offers into 3 columns: (Segment, MW, Price)
--

DROP TABLE IF EXISTS stack;
CREATE TABLE stack AS 
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
    SELECT  "Masked Gen ID", "Date Time", 
        CAST("Segment" as UTINYINT) AS Segment, 
        "MW", "Price", 
    FROM unpivot_alias
    ORDER BY "Date Time" ASC, Price ASC;
select * from stack;


SELECT *, 
        SUM("MW") OVER (PARTITION BY "Date Time" ORDER BY "Idx") AS "cum_MW"   
FROM (
    SELECT *, 
        row_number() OVER (PARTITION BY "Date Time") AS "Idx",
    FROM stack
);





















-----------------------------------------------------
-- Scratch space below ...
-----------------------------------------------------
    SELECT "Masked Gen ID", MAX("Upper Oper Limit") as EcoMax, "Masked Bidder ID" 
    FROM da_offers
    WHERE "Masked Bidder ID" == 78710750
    GROUP BY "Masked Gen ID", "Masked Bidder ID"
    ORDER BY "Masked Gen ID" ASC;



SELECT * FROM one
WHERE "Masked Gen ID" == 67537750;



DROP TABLE IF EXISTS stack;
CREATE TABLE stack 
AS SELECT *, 
    SUM(MW) OVER (PARTITION BY "Date Time" ORDER BY "Price") "cum_mw"
FROM tmp;    
SELECT * FROM stack;







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
