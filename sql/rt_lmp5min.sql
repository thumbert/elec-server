
SELECT * FROM rt_lmp5min
LIMIT 5;

SELECT DISTINCT ptid, report 
FROM rt_lmp5min;

-- get the number of observations by month
SELECT strftime(date, '%Y-%m') as month, COUNT(*)
FROM rt_lmp5min
WHERE ptid = 4000
AND report = 'final'
GROUP BY month
ORDER BY month;





