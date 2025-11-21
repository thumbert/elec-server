

--- Calculate the settle price for a path 
CREATE TEMPORARY TABLE paths (
    source_ptid INT,
    sink_ptid INT,
);

INSERT INTO paths (source_ptid, sink_ptid) VALUES
    (4000, 4001),
    (4000, 4008);

ATTACH '~/Downloads/Archive/DuckDB/isone/dalmp.duckdb' AS dalmp;
ATTACH '~/Downloads/Archive/DuckDB/calendars/buckets.duckdb' AS buckets;
SELECT * FROM buckets.buckets;

SELECT
  p.source_ptid,
  p.sink_ptid,
  strftime(lmp_src.hour_beginning, '%Y-%m') AS month,
  AVG(lmp_src.mcc)::DECIMAL(9,4) AS source_price,
  AVG(lmp_sink.mcc)::DECIMAL(9,4) AS sink_price,
  AVG(lmp_sink.mcc)::DECIMAL(9,4) - AVG(lmp_src.mcc)::DECIMAL(9,4) AS settle_price
FROM paths p
JOIN dalmp.da_lmp AS lmp_src
  ON lmp_src.ptid = p.source_ptid
JOIN dalmp.da_lmp AS lmp_sink
  ON lmp_sink.ptid = p.sink_ptid
  AND lmp_sink.hour_beginning = lmp_src.hour_beginning
JOIN buckets.buckets
  ON lmp_src.hour_beginning = buckets.buckets.hour_beginning
WHERE buckets.buckets."5x16" = true
  AND lmp_src.hour_beginning >= '2025-01-01 00:00:00.00-05:00'
  AND lmp_src.hour_beginning < '2025-08-01 00:00:00.00-04:00'
GROUP BY p.source_ptid, p.sink_ptid, month
ORDER BY p.source_ptid, p.sink_ptid, month;




    
SELECT 
    ptid,
    AVG(mcc)::DECIMAL(9,4) as price
FROM dalmp.da_lmp
JOIN buckets.buckets
    ON dalmp.da_lmp.hour_beginning = buckets.buckets.hour_beginning
WHERE ptid IN (4000, 4001)
AND strftime(dalmp.da_lmp.hour_beginning, '%Y-%m') = '2025-01'
GROUP BY ptid, buckets.buckets."5x16"
HAVING buckets.buckets."5x16" = true;    



---=====================================================================


CREATE TEMPORARY TABLE tmp AS (
    SELECT unnest(FtrAuctionClearingPrices.FtrAuctionClearingPrice, recursive := true)
    FROM read_json(
        '/home/adrian/Downloads/Archive/IsoExpress/FTR/ClearedPrices/Raw/ftr_clearing_prices_2025_monthly.json.gz',
        maximum_object_size=50000000  -- 50MB, or set higher as needed
    )
);

SELECT DISTINCT AuctionName 
FROM tmp
ORDER BY AuctionName;   

