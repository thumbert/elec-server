


CREATE TEMPORARY TABLE tbl (
    date DATE,
    id INT,
    price DECIMAL(9,4)[]
);
INSERT INTO tbl VALUES
    ('2025-07-01', 4000, [1.3456, 2.4567]),
    ('2025-07-01', 4001, [14.5678, 15.6789]),
    ('2025-07-02', 4000, [1.7890, 2.8901]),
    ('2025-07-02', 4001, [19.0123, 20.1234]);

--=======================================================================================
-- How to read a JSON file into a set of columns, some columns may be missing 
-- from this particular file, in this case the expected_rt_hub_lmp_override is optional.  
-- See another even more complicated example in sql/sevenday_capacity_forecast.sql
SELECT 
    json_extract(aux, '$.strike_price')::DECIMAL(9,2) as strike_price,
    json_extract(aux, '$.expected_rt_hub_lmp_override')::DECIMAL(9,2) as expected_rt_hub_lmp_override
FROM (
    SELECT  unnest(isone_web_services.day_ahead_strike_prices.day_ahead_strike_price)::JSON as aux
    FROM read_json('~/Downloads/Archive/IsoExpress/DASI/StrikePrices/Raw/2025/daas_strike_prices_2025-04-01.json.gz')
);






--================================================================================
-- Construct the json output by hand.  Useful if you want DuckDB to do all the work
-- and not having Rust serialize/deserialize the results  
WITH per_date AS (
    SELECT
        date,
         '{' || string_agg(id || ':' || to_json(price), ',') || '}' AS map_json
    FROM tbl
    GROUP BY date
    ORDER BY date
)
SELECT '{' || string_agg('"' || date || '":' || map_json, ',') || '}' AS out
FROM per_date;
-- ┌────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
-- │                                                          out                                                           │
-- │                                                        varchar                                                         │
-- ├────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
-- │ {"2025-07-01":{4000:[1.3456,2.4567],4001:[14.5678,15.6789]},"2025-07-02":{4000:[1.789,2.8901],4001:[19.0123,20.1234]}} │
-- └────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
