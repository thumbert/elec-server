SELECT * FROM capacity_prices_monthly LIMIT 5;

SELECT DISTINCT auction_month
FROM capacity_prices_monthly
ORDER BY auction_month;



---=======================================================================
--- strip auction clearing prices
CREATE TABLE IF NOT EXISTS capacity_prices_strip (
    capability_period VARCHAR NOT NULL,
    location VARCHAR NOT NULL,
    clearing_price DECIMAL(9,4) NOT NULL,
    awarded_mw DECIMAL(9,4) NOT NULL
);

CREATE TEMPORARY TABLE tmp
AS (
    SELECT * 
    FROM read_csv('/home/adrian/Downloads/Archive/Nyiso/CapacityPrices/Monthly/CSV/2026/capacity_prices_2026-*.csv.gz')
);

INSERT INTO capacity_prices_monthly
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM capacity_prices_monthly d
        WHERE
            d.capability_period = t.capability_period AND
            d.auction_month = t.auction_month AND
            d.forward_month = t.forward_month AND
            d.location = t.location
    )
);



--- spot auction clearing price
CREATE TABLE IF NOT EXISTS capacity_prices_spot (
    capability_period VARCHAR NOT NULL,
    location VARCHAR NOT NULL,
    clearing_price DECIMAL(9,4) NOT NULL,
    awarded_deficiency_mw DECIMAL(9,4) NOT NULL,
    awarded_excess_mw DECIMAL(9,4) NOT NULL,
    percent_excess_above_requirement DECIMAL(9,4) NOT NULL
);
