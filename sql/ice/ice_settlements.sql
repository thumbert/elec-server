


---========================================================================
CREATE TABLE IF NOT EXISTS settlement_prices (
    market_id UINTEGER NOT NULL,
    asof DATE NOT NULL,
    price DECIMAL(18,5) NOT NULL
);

--- Unfortunately, only some markets are available via the API 
--- https://www.ice.com/marketdata/api/productguide/charting/data/historical?marketId=7703360&historicalSpan=3
CREATE TEMPORARY TABLE tmp
AS
    SELECT
        market_id, 
        strptime(trim(aux -> 0, '"')::VARCHAR, '%a %b %d 00:00:00 %Y')::DATE as asof,
        (aux -> 1)::DECIMAL(18,5) as price,
    FROM (
        SELECT marketId::UINTEGER as market_id, 
            unnest(bars)::JSON as aux
        FROM read_json('~/Downloads/Archive/ICE/Settlements/Raw/7703360_2026-04-*.json')
    );

    ORDER BY asof
;


INSERT INTO settlement_prices
    SELECT *
    FROM tmp t
WHERE NOT EXISTS (
    SELECT * FROM settlement_prices s
    WHERE
        s.market_id = t.market_id AND
        s.asof = t.asof
) ORDER BY asof;


