SELECT * FROM offers;

SELECT * FROM offers
WHERE hour_beginning >= '2025-03-02 00:00:00'
AND hour_beginning < '2025-03-03 00:00:00'
-- AND masked_lead_participant_id = 353795
AND masked_asset_id = 98805
ORDER BY hour_beginning, masked_lead_participant_id, masked_asset_id;




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







