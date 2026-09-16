


---=========================================================================
CREATE TABLE IF NOT EXISTS tab0 (
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    account_id UINTEGER NOT NULL,
    location_id UINTEGER NOT NULL,
    location_name VARCHAR NOT NULL,
    location_type ENUM ('LOAD ZONE', 'NETWORK NODE', 'HUB', 'DRR AGGREGATION ZONE') NOT NULL,
    bid_offer_type ENUM ('DEMAND BID', 'GEN OFFER', 'INC', 'DEC', 'REDUCTION OFFER') NOT NULL,
    reference_id VARCHAR,
    asset_id UINTEGER NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    ownership_share DECIMAL(9,4) NOT NULL,
    cleared_mw DECIMAL(9,1) NOT NULL
);
CREATE INDEX idx ON tab0 (report_date, account_id, location_id);



-- Row types live in column00: C=comment, H=header, D=data, T=trailer.
-- Section 1's D rows have location_type in column04; section 2's D rows have it one
-- column later, in column06 (section 1 has subaccount_id/name inserted before it).
-- Matching column06 against the known location_type values is what tells the two
-- sections apart; a numeric-cast check on a nearby column would be fragile since
-- trading_interval can be a non-numeric value like "02X" on a DST fall-back day.
-- report_date, version and account_id aren't in the csv; they come from the file name,
-- e.g. sd_dacleared_<account_id>_<report_date>00_<version>.csv
--
-- trading_interval is normally numeric 1-24, but on a DST fall-back (25-hour) day the
-- repeated hour is reported as e.g. "02X", and on a DST spring-forward (23-hour) day
-- hour 2 is simply absent. hour_position below turns that into a 0-based elapsed-hour
-- count so hour_beginning lands on the correct absolute instant on crossover days too.
--

SET VARIABLE files = array_value(
    '/home/adrian/Documents/repos/git/thumbert/elec-server/test/_assets/sd_dacleared_1.csv', 
    '/home/adrian/Documents/repos/git/thumbert/elec-server/test/_assets/sd_dacleared_2.csv'
);

WITH raw AS (
    SELECT
        regexp_extract(filename, 'sd_dacleared_([^/]+)\.csv$', 1) AS base_name,
        column1 AS trading_interval,
        column2::UINTEGER AS location_id,
        column3 AS location_name,
        column4 AS location_type,
        column5 AS bid_offer_type,
        column6::VARCHAR AS reference_id,
        column7::UINTEGER AS asset_id,
        column8::DECIMAL(9,4) AS ownership_share,
        column9::DECIMAL(9,1) AS cleared_mw
    FROM read_csv(
        '/home/adrian/Documents/repos/git/thumbert/elec-server/test/_assets/sd_dacleared_*.csv',
        header = false,
        all_varchar = true,
        filename = true
    )
    WHERE column0 = 'D'
),
parsed AS (
    SELECT *,
        strptime(substr(split_part(base_name, '_', 2), 1, 8), '%Y%m%d')::DATE AS report_date,
        strptime(split_part(base_name, '_', 3), '%Y%m%d%H%M%S') AS version,
        split_part(base_name, '_', 1)::UINTEGER AS account_id,
        regexp_replace(trading_interval, '[Xx]$', '')::UTINYINT AS base_hour,
        trading_interval ILIKE '%X' AS is_extra_hour
    FROM raw
),
positioned AS (
    SELECT *,
        max(is_extra_hour::INT) OVER (PARTITION BY report_date, location_id) AS has_extra_hour,
        max((base_hour = 2 AND NOT is_extra_hour)::INT) OVER (PARTITION BY report_date, location_id) AS has_hour2,
    FROM parsed
),
to_insert AS (
    SELECT
        report_date,
        version,
        account_id,
        location_id,
        location_name,
        location_type,
        bid_offer_type,
        reference_id,
        asset_id,
        (report_date AT TIME ZONE 'America/New_York')
            + (
                CASE
                    WHEN is_extra_hour THEN 2
                    WHEN base_hour <= 2 THEN base_hour - 1
                    ELSE base_hour - 1 + has_extra_hour
                        - CASE WHEN has_extra_hour = 0 AND has_hour2 = 0 THEN 1 ELSE 0 END
                END
            ) * INTERVAL '1 hour' AS hour_beginning,
        ownership_share,
        cleared_mw
    FROM positioned
)
-- skip rows already present, keyed on (account_id, report_date, version, hour_beginning, location_id)
INSERT INTO tab0
SELECT ti.*
FROM to_insert ti
WHERE NOT EXISTS (
    SELECT 1 FROM tab0 t
    WHERE t.account_id = ti.account_id
    AND t.report_date = ti.report_date
    AND t.version = ti.version
    AND t.hour_beginning = ti.hour_beginning
    AND t.location_id = ti.location_id
    AND t.reference_id = ti.reference_id
);
