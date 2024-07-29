

--  Which months are in the table
SELECT strftime("IntervalBeginning5Min", '%Y-%m') AS YEARMON, COUNT(*) 
FROM rt_reserve_price
GROUP BY YEARMON
ORDER BY YEARMON;

SELECT DISTINCT "IntervalBeginning5Min" 
FROM rt_reserve_price
ORDER BY IntervalBeginning5Min
LIMIT 5
;


.mode box
SELECT IntervalBeginning5Min, RosTmsrClearingPrice
FROM rt_reserve_price
LIMIT 12*2;

--- calculate hourly averages
SELECT datetrunc('hour', IntervalBeginning5Min) AS hour, 
    AVG(RosTmsrClearingPrice) AS RosTmsrClearingPrice
FROM rt_reserve_price
GROUP BY hour 
ORDER BY hour;





