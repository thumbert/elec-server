SELECT 
    GEO as region,
    REF_DATE as month,
    VALUE as MWh,
FROM   
    electricity_production
WHERE
    "Type of electricity generation" = 'Hydraulic turbine'
    AND "Class of electricity producer" = 'Total all classes of electricity producer'
ORDER BY REF_DATE, GEO;    





SELECT 
    REF_DATE as month,
    VALUE as MWh,
    (AVG(VALUE) OVER (ORDER BY REF_DATE ROWS BETWEEN 11 PRECEDING AND CURRENT ROW)) AS MWh_12m_MA
FROM   
    electricity_production
WHERE
    "Type of electricity generation" = 'Hydraulic turbine'
    AND "Class of electricity producer" = 'Total all classes of electricity producer'
    AND GEO = 'Newfoundland and Labrador' -- 'Quebec', 'Ontario', 'Quebec', ''
;    


duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/statistics_canada/energy_generation.duckdb' AS ep;
SELECT 
    REF_DATE as month,
    VALUE as MWh
FROM   
    ep.electricity_production
WHERE
    \"Type of electricity generation\" = 'Hydraulic turbine'
    AND \"Class of electricity producer\" = 'Total all classes of electricity producer'
    AND GEO = 'Newfoundland and Labrador'
;    
" | qplot



---==================================================================================================================
--- Create file DuckDB/statistics_canada/energy_generation.duckdb
LOAD zipfs;
CREATE TABLE electricity_production AS (
    SELECT *
    FROM 'zip:///home/adrian/Downloads/Archive/Canada/StatisticsCanada/ElectricPowerGeneration/Raw/25100015-eng.zip/25100015.csv'
);


