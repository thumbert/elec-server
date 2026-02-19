SELECT * FROM zonal_uplift
WHERE uplift_payment > 0
ORDER BY day DESC;


SELECT 
    day,
    SUM(uplift_payment) AS total_uplift_payment
FROM zonal_uplift
WHERE day >= '2026-01-01' AND day < '2026-02-01'
GROUP BY day
ORDER BY day;

SELECT 
    strftime('%Y-%m', day) AS month,
    SUM(uplift_payment) AS total_uplift_payment
FROM zonal_uplift
GROUP BY month
ORDER BY month;

duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/nyiso/zonal_uplift.duckdb' AS zu;
SELECT 
    strftime('%Y-%m', day) AS month,
    SUM(uplift_payment) AS total_uplift_payment
FROM zu.zonal_uplift
GROUP BY month
ORDER BY month;
" 


| qplot




---=======================================================================
CREATE TABLE IF NOT EXISTS zonal_uplift (
    day DATE NOT NULL,
    ptid VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    uplift_category VARCHAR NOT NULL,
    uplift_payment DECIMAL(18,2) NOT NULL,
);

CREATE TEMPORARY TABLE tmp
AS (
    SELECT 
        strptime("Market Day", '%m/%d/%Y')::DATE AS day,
        PTID::VARCHAR AS ptid,
        "Name"::VARCHAR AS name,
        "Uplift Payment Category"::VARCHAR AS uplift_category,
        "Uplift Payment Amount"::DECIMAL(18,2) AS uplift_payment
    FROM read_csv('/home/adrian/Downloads/Archive/Nyiso/ZonalUplift/Raw/2026/2026-01_zonal_uplift.csv.gz', 
        header = true)
    WHERE uplift_payment <> 0    
);

INSERT INTO zonal_uplift
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM zonal_uplift d
        WHERE
            d.day = t.day AND
            d.ptid = t.ptid AND
            d.name = t.name AND
            d.uplift_category = t.uplift_category AND
            d.uplift_payment = t.uplift_payment
    )
);
