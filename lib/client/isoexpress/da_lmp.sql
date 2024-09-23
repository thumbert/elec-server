
CREATE TABLE IF NOT EXISTS da_lmp (
    ptid UINTEGER NOT NULL,
    date DATE NOT NULL,
    hour UTINYINT NOT NULL,
    extraDstHour bool NOT NULL,
    lmp DECIMAL(9,4) NOT NULL,
    mcc DECIMAL(9,4) NOT NULL,
    mcl DECIMAL(9,4) NOT NULL,
);

--- Insert one year of data 
INSERT INTO da_lmp
FROM read_csv(
    '/home/adrian/Downloads/Archive/IsoExpress/PricingReports/DaLmpHourly/month/da_lmp_2023-*.csv.gz', 
    header = true, 
    dateformat = '%Y-%m-%d');

--- As of 9/1/2024 I've ingested years 2022-2023.  21M rows.


--- 
CREATE TABLE nerc_holidays (
    date DATE NOT NULL,
);
INSERT INTO nerc_holidays
FROM read_csv(
    '/home/adrian/Downloads/Archive/Calendars/nerc_holidays.csv', 
    header = true, 
    dateformat = '%Y-%m-%d');

--- Calculate ATC prices
SELECT ptid, strftime(date, '%Y-%m') as YEARMON,  ROUND(AVG(lmp), 4) as lmp
FROM da_lmp
-- WHERE ptid = 4000
GROUP BY ptid, YEARMON
ORDER BY ptid, YEARMON
LIMIT 5;

--- Calculate 5x16 prices by stacking together two groups of rows:
--- 1) All weekdays with hours between 7-22 that are not nerc holidays
SELECT ptid, strftime(date, '%Y-%m') as YEARMON, COUNT(*) as hours_5x16, ROUND(AVG(lmp), 4) as lmp  
FROM da_lmp
-- WHERE ptid = 4000
WHERE date NOT IN (SELECT date FROM nerc_holidays)
AND dayofweek(da_lmp.date) in (1, 2, 3, 4, 5) 
AND hour BETWEEN 7 and 22
GROUP BY ptid, YEARMON
ORDER BY ptid, YEARMON
LIMIT 5;


--- Calculate 2x16H prices by stacking together two groups of rows:
--- 1) All weekends with hours between 7-22
--- 2) All nerc_holidays that are not on the weekend, with hours 7-22
SELECT ptid, strftime(date, '%Y-%m') as YEARMON, COUNT(*) as hours_2x16H, ROUND(AVG(lmp), 4) as lmp  
FROM (
    (SELECT * 
        FROM da_lmp
        WHERE ptid = 4000
        AND dayofweek(date) in (0, 6) 
        AND hour BETWEEN 7 AND 22
    )
        UNION
    (SELECT da_lmp.* 
        FROM da_lmp
        JOIN nerc_holidays
            ON da_lmp.date = nerc_holidays.date
        WHERE ptid = 4000
        AND dayofweek(da_lmp.date) in (1, 2, 3, 4, 5) 
        AND hour BETWEEN 7 AND 22
    )
)
GROUP BY ptid, YEARMON
ORDER BY ptid, YEARMON;

--- Calculate 7x8 prices 
--- 1) All days with hours between 0-6 and 23
SELECT ptid, strftime(date, '%Y-%m') as YEARMON, COUNT(*) as hours_7x8, ROUND(AVG(lmp), 4) as lmp  
FROM da_lmp
WHERE ptid = 4000
AND (hour < 7 OR hour = 23)
GROUP BY ptid, YEARMON
ORDER BY ptid, YEARMON;


SELECT ptid, date, hour, extraDstHour, lmp
FROM da_lmp
WHERE date >= '2022-01-01'
AND date <= '2022-01-31'
AND ptid in ('4000', '4001')
ORDER BY ptid, date, hour, extraDstHour;
