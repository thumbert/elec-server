

SELECT * FROM morning_report LIMIT 1;

SELECT MIN(MarketDate), MAX(MarketDate) FROM morning_report;

-- Look at the days when the Excess Commitment Surplus/Deficiency was the lowest
SELECT MarketDate, ExcessCommitMw
FROM morning_report
WHERE ReportType = 'Final'
ORDER BY ExcessCommitMw ASC
LIMIT 30;



SELECT MarketDate, ReportType, ExcessCommitMw
FROM morning_report
WHERE MarketDate > '2024-06-01';




