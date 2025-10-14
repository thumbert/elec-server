SELECT MIN(hour_beginning) AS min_hour, MAX(hour_beginning) AS max_hour, COUNT(*) AS total_rows
FROM offers;




SELECT * FROM offers
WHERE hour_beginning >= '2025-03-02 00:00:00'
AND hour_beginning < '2025-03-03 00:00:00'
-- AND masked_lead_participant_id = 353795
-- AND masked_asset_id = 98805
ORDER BY hour_beginning, masked_lead_participant_id, masked_asset_id;



---=======================================================
--- How many unique participants are offering every day?
WITH daily_participants AS (
    SELECT 
        hour_beginning::DATE AS offer_date,
        COUNT(DISTINCT masked_lead_participant_id) AS unique_participants
    FROM offers
    GROUP BY offer_date
)
SELECT 
    offer_date,
    unique_participants
FROM daily_participants
ORDER BY offer_date;    

duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/isone/masked_daas_offers.duckdb' AS db;
WITH daily_participants AS (
    SELECT 
        hour_beginning::DATE AS offer_date,
        COUNT(DISTINCT masked_lead_participant_id) AS unique_participants
    FROM db.offers
    GROUP BY offer_date
)
SELECT 
    offer_date,
    unique_participants
FROM daily_participants
ORDER BY offer_date;    
" | qplot --config='{"title":"DAAS Offers","yaxis":{"title":"Number of unique participants"}}'


---=======================================================================
--- histogram of unique number of participants per day
SELECT 
    kv['key'] AS unique_participants, 
    kv['value'] AS days
FROM (
    WITH daily_participants AS (
        SELECT 
            hour_beginning::DATE AS offer_date,
            COUNT(DISTINCT masked_lead_participant_id) AS unique_participants
        FROM offers
        GROUP BY offer_date
    )
    SELECT 
        unnest(map_entries(histogram(unique_participants))) as kv
    FROM daily_participants
);
-- ┌─────────────────────┬────────┐
-- │ unique_participants │  days  │
-- │        int64        │ uint64 │
-- ├─────────────────────┼────────┤
-- │                  36 │      1 │
-- │                  39 │      8 │
-- │                  40 │     15 │
-- │                  41 │     14 │
-- │                  42 │      9 │
-- │                  43 │      8 │
-- │                  44 │     20 │
-- │                  45 │     14 │
-- │                  46 │      3 │
-- └─────────────────────┴────────┘


---=======================================================================
-- How many MW are offered every day?  Average all hours in the day.
WITH daily_offers AS (
    SELECT 
        hour_beginning,
        SUM(offer_mw) AS total_offer_mw
    FROM offers
    GROUP BY hour_beginning
)
SELECT 
    hour_beginning::DATE AS offer_date,
    ROUND(mean(total_offer_mw)) AS total_offer_mw
FROM daily_offers
GROUP BY offer_date
ORDER BY offer_date;



duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/isone/masked_daas_offers.duckdb' AS db;
WITH daily_offers AS (
    SELECT 
        hour_beginning,
        SUM(offer_mw) AS total_offer_mw
    FROM db.offers
    GROUP BY hour_beginning
)
SELECT 
    hour_beginning,
    total_offer_mw
FROM daily_offers
ORDER BY hour_beginning;
" | qplot --config='{"title":"DAAS Offers","yaxis":{"title":"Total MW offered"}}'



---=======================================================================
-- Who is offering the most MWs every day?
SELECT 
    masked_lead_participant_id,
    MAX(offer_mw) AS max_offer_mw
FROM offers
GROUP BY masked_lead_participant_id
HAVING max_offer_mw > 50   
ORDER BY max_offer_mw DESC;
-- ┌────────────────────────────┬──────────────┐
-- │ masked_lead_participant_id │ max_offer_mw │
-- │           int32            │ decimal(9,2) │
-- ├────────────────────────────┼──────────────┤
-- │                     958512 │       620.00 │
-- │                     595644 │       595.00 │
-- │                     126216 │       568.00 │
-- │                     748190 │       514.80 │
-- │                     352775 │       403.10 │
-- │                     379629 │       402.00 │
-- │                     855157 │       400.20 │
-- │                     878461 │       348.00 │
-- │                     931987 │       330.00 │
-- │                     706923 │       320.00 │
-- │                     591975 │       299.00 │
-- │                     582462 │       292.00 │
-- │                     295534 │       265.00 │
-- │                     328723 │       250.00 │
-- │                     396955 │       202.00 │
-- │                     872788 │       194.70 │
-- │                     639879 │       186.00 │
-- │                     207554 │       103.50 │
-- │                     953967 │       100.00 │


---=======================================================================
-- Show the historical MW offers for one given participant
SELECT hour_beginning, sum(offer_mw) AS total_offer_mw
FROM offers
WHERE masked_lead_participant_id = 958512
GROUP BY hour_beginning
ORDER BY hour_beginning;

--- Pivot the data to show historical MW offers for all participants, each as a column
SELECT hour_beginning,
FROM (
    PIVOT offers
    ON masked_lead_participant_id
    USING SUM(offer_mw)
    GROUP BY hour_beginning
    ORDER BY hour_beginning;
)

duckdb -csv -c "
ATTACH '~/Downloads/Archive/DuckDB/isone/masked_daas_offers.duckdb' AS db;
PIVOT db.offers
ON masked_lead_participant_id
USING SUM(offer_mw)
GROUP BY hour_beginning
ORDER BY hour_beginning;
" | qplot --config='{"title":"DAAS Offers by participant","yaxis":{"title":"Total MW offered"}}'



---=======================================================================
-- Show the assets for 
SELECT DISTINCT masked_lead_participant_id, masked_asset_id
FROM offers
WHERE masked_lead_participant_id = 748190
ORDER BY masked_lead_participant_id, masked_asset_id;

SELECT masked_lead_participant_id, masked_asset_id, MEAN(offer_mw) AS avg_offer_mw, MAX(offer_mw) AS max_offer_mw
FROM offers
WHERE masked_lead_participant_id = 379629
GROUP BY masked_lead_participant_id, masked_asset_id
ORDER BY masked_lead_participant_id, masked_asset_id;















-- ========================================================
CREATE TABLE IF NOT EXISTS offers (
    hour_beginning TIMESTAMPTZ NOT NULL,
    masked_lead_participant_id INTEGER NOT NULL,
    masked_asset_id INTEGER NOT NULL,
    offer_mw DECIMAL(9,2) NOT NULL,
    tmsr_offer_price DECIMAL(9,2) NOT NULL,
    tmnsr_offer_price DECIMAL(9,2) NOT NULL,
    tmor_offer_price DECIMAL(9,2) NOT NULL,
    eir_offer_price DECIMAL(9,2) NOT NULL,
);

CREATE TEMPORARY TABLE tmp
AS
    SELECT * 
    FROM (
        SELECT unnest(isone_web_services.offer_publishing.day_ahead_ancillary_services.daas_gen_offer_data, recursive := true)
        FROM read_json('~/Downloads/Archive/IsoExpress/PricingReports/DaasOffers/Raw/2025/hbdaasenergyoffer_2025-03-*.json.gz')
    )
    ORDER BY local_day
;
SELECT * from tmp;

INSERT INTO offers
(
    SELECT 
        local_day::TIMESTAMPTZ as hour_beginning,
        masked_lead_participant_id::INTEGER as masked_lead_participant_id,
        masked_asset_id::INTEGER as masked_asset_id,
        offer_mw::DECIMAL(9,2) as offer_mw,
        tmsr_offer_price::DECIMAL(9,2) as tmsr_offer_price,
        tmnsr_offer_price::DECIMAL(9,2) as tmnsr_offer_price,
        tmor_offer_price::DECIMAL(9,2) as tmor_offer_price,
        eir_offer_price::DECIMAL(9,2) as eir_offer_price
    FROM tmp t
WHERE NOT EXISTS (
        SELECT * FROM offers o
        WHERE
            o.hour_beginning = t.local_day AND
            o.masked_lead_participant_id = t.masked_lead_participant_id AND
            o.masked_asset_id = t.masked_asset_id AND
            o.tmsr_offer_price = t.tmsr_offer_price AND
            o.tmnsr_offer_price = t.tmnsr_offer_price AND
            o.tmor_offer_price = t.tmor_offer_price AND
            o.eir_offer_price = t.eir_offer_price
    )
) ORDER BY hour_beginning, masked_lead_participant_id, masked_asset_id; 







