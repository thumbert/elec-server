
CREATE TABLE vulns
AS (    
    SELECT *
    FROM read_csv('https://www.cisa.gov/sites/default/files/csv/known_exploited_vulnerabilities.csv', header = true)
);


SELECT * FROM vulns
ORDER BY dateAdded DESC
LIMIT 10;


SELECT * FROM vulns
WHERE dateAdded >= '2026-01-01'
AND vendorProject IN ('Cisco', 'Fortinet');

SELECT MIN(dateAdded) AS earliest, MAX(dateAdded) AS latest
FROM vulns;

SELECT DISTINCT vendorProject
FROM vulns
WHERE dateAdded >= '2024-01-01'
ORDER BY vendorProject;


--INSTALL ggsql FROM community;
LOAD ggsql;

--- Show the cumulative count of vulnerabilities vs. dateAdded

SELECT dateAdded, 
    COUNT(*) AS daily_count,
    SUM(COUNT(*)) OVER (ORDER BY dateAdded)::DOUBLE AS cumulative_count
FROM vulns
WHERE vendorProject = 'Fortinet'
-- WHERE vendorProject = 'Cisco'
GROUP BY dateAdded
ORDER BY dateAdded
VISUALIZE 
    dateAdded as x,
    cumulative_count as y
DRAW line
DRAW point
LABEL
    title => 'Fortinet Vulnerabilities Over Time',
    x => 'Date Added',
    y => 'Cumulative Count of Vulnerabilities'
;


--- Show the top 20 vendorProject with the most vulnerabilities
SELECT vendorProject, COUNT(*) AS count
FROM vulns
GROUP BY vendorProject
ORDER BY count DESC
LIMIT 20;

VISUALIZE 
    vendorProject as x,
    count as y
DRAW bar;

