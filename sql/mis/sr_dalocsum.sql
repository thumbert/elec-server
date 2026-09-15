
SET VARIABLE settlement = 0;
SELECT 
    location_id, 
    hour_beginning,
    versions[LEAST(len(versions), getvariable('settlement') + 1)] as version,
    y[LEAST(len(versions), getvariable('settlement') + 1)] as da_cleared_generation
FROM (
    SELECT 
        location_id,
        hour_beginning,
        array_agg(version) as versions,
        array_agg(da_cleared_generation) as y 
    FROM tab1
    WHERE report_date >= '2026-09-01'
    AND report_date <= '2026-09-10'
    AND subaccount_id = 'WHLGENLD'
    AND location_id = 4004
)
ORDER BY location_id, hour_beginning;



---=========================================================================
CREATE TABLE IF NOT EXISTS tab1 (
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    account_id UINTEGER NOT NULL,
    subaccount_id UINTEGER NOT NULL,
    subaccount_name VARCHAR NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    location_id UINTEGER NOT NULL,
    location_name VARCHAR NOT NULL,
    location_type ENUM ('LOAD ZONE', 'NETWORK NODE', 'HUB', 'DRR AGGREGATION ZONE') NOT NULL,
    da_cleared_generation DOUBLE,
    da_cleared_increments DOUBLE,
    da_cleared_imports DOUBLE,
    da_generation_obligation DOUBLE,
    da_cleared_demand_bids DOUBLE, 
    da_cleared_decrements DOUBLE, 
    da_cleared_exports DOUBLE, 
    da_load_obligation DOUBLE,
    da_internal_bilateral_for_purchases DOUBLE,
    da_internal_bilateral_for_sales DOUBLE,
    da_adjusted_load_obligation DOUBLE,
    da_adjusted_net_interchange DOUBLE,
    da_energy_component DOUBLE,
    da_congestion_component DOUBLE,
    da_marginal_loss_component DOUBLE,
    da_energy_charge_or_credit DOUBLE,
    da_congestion_charge_or_credit DOUBLE,
    da_marginal_loss_charge_or_credit DOUBLE,
    da_cleared_asset_related_demand_bids DOUBLE,
    da_load_obligation_for_charge_allocation DOUBLE,
    da_demand_reduction DOUBLE,
    da_demand_reduction_obligation DOUBLE,
    da_cleared_sodera_load DOUBLE,
    da_cleared_sodera_generation DOUBLE,
);
CREATE INDEX idx ON tab1 (report_date, account_id, subaccount_id);


-- Data section 2 (subaccount level detail rows) of the raw report populates tab1.
-- Row types live in column00: C=comment, H=header, D=data, T=trailer.
-- Section 1's D rows have location_type in column04; section 2's D rows have it one
-- column later, in column06 (section 1 has subaccount_id/name inserted before it).
-- Matching column06 against the known location_type values is what tells the two
-- sections apart; a numeric-cast check on a nearby column would be fragile since
-- trading_interval can be a non-numeric value like "02X" on a DST fall-back day.
-- report_date, version and account_id aren't in the csv; they come from the file name,
-- e.g. sr_dalocsum_<account_id>_<report_date>00_<version>.csv
--
-- trading_interval is normally numeric 1-24, but on a DST fall-back (25-hour) day the
-- repeated hour is reported as e.g. "02X", and on a DST spring-forward (23-hour) day
-- hour 2 is simply absent. hour_position below turns that into a 0-based elapsed-hour
-- count so hour_beginning lands on the correct absolute instant on crossover days too.
--
-- older report files don't have the last 2 (sodera) columns; union_by_name +
-- null_padding line files up by position (column0N) and fill those 2 columns with
-- NULL for rows read from an older file.
WITH raw AS (
    SELECT
        regexp_extract(filename, '([^/]+)\.csv$', 1) AS base_name,
        column01::UINTEGER AS subaccount_id,
        column02 AS subaccount_name,
        column03 AS trading_interval,
        column04::UINTEGER AS location_id,
        column05 AS location_name,
        column06 AS location_type,
        column07::DOUBLE AS da_cleared_generation,
        column08::DOUBLE AS da_cleared_increments,
        column09::DOUBLE AS da_cleared_imports,
        column10::DOUBLE AS da_generation_obligation,
        column11::DOUBLE AS da_cleared_demand_bids,
        column12::DOUBLE AS da_cleared_decrements,
        column13::DOUBLE AS da_cleared_exports,
        column14::DOUBLE AS da_load_obligation,
        column15::DOUBLE AS da_internal_bilateral_for_purchases,
        column16::DOUBLE AS da_internal_bilateral_for_sales,
        column17::DOUBLE AS da_adjusted_load_obligation,
        column18::DOUBLE AS da_adjusted_net_interchange,
        column19::DOUBLE AS da_energy_component,
        column20::DOUBLE AS da_congestion_component,
        column21::DOUBLE AS da_marginal_loss_component,
        column22::DOUBLE AS da_energy_charge_or_credit,
        column23::DOUBLE AS da_congestion_charge_or_credit,
        column24::DOUBLE AS da_marginal_loss_charge_or_credit,
        column25::DOUBLE AS da_cleared_asset_related_demand_bids,
        column26::DOUBLE AS da_load_obligation_for_charge_allocation,
        column27::DOUBLE AS da_demand_reduction,
        column28::DOUBLE AS da_demand_reduction_obligation,
        column29::DOUBLE AS da_cleared_sodera_load,
        column30::DOUBLE AS da_cleared_sodera_generation,
    FROM read_csv(
        '/home/adrian/Documents/repos/git/thumbert/elec-server/test/_assets/sr_dalocsum_*.csv',
        header = false,
        all_varchar = true,
        filename = true,
        null_padding = true,
        union_by_name = true,
        strict_mode = false
    )
    WHERE column00 = 'D'
    AND column06 IN ('LOAD ZONE', 'NETWORK NODE', 'HUB', 'DRR AGGREGATION ZONE')
),
parsed AS (
    SELECT *,
        strptime(substr(split_part(base_name, '_', 4), 1, 8), '%Y%m%d')::DATE AS report_date,
        strptime(split_part(base_name, '_', 5), '%Y%m%d%H%M%S') AS version,
        split_part(base_name, '_', 3)::UINTEGER AS account_id,
        regexp_replace(trading_interval, '[Xx]$', '')::UTINYINT AS base_hour,
        trading_interval ILIKE '%X' AS is_extra_hour
    FROM raw
),
positioned AS (
    SELECT *,
        max(is_extra_hour::INT) OVER (PARTITION BY report_date, subaccount_id, location_id) AS has_extra_hour,
        max((base_hour = 2 AND NOT is_extra_hour)::INT) OVER (PARTITION BY report_date, subaccount_id, location_id) AS has_hour2,
    FROM parsed
),
to_insert AS (
    SELECT
        report_date,
        version,
        account_id,
        subaccount_id,
        subaccount_name,
        (report_date AT TIME ZONE 'America/New_York')
            + (
                CASE
                    WHEN is_extra_hour THEN 2
                    WHEN base_hour <= 2 THEN base_hour - 1
                    ELSE base_hour - 1 + has_extra_hour
                        - CASE WHEN has_extra_hour = 0 AND has_hour2 = 0 THEN 1 ELSE 0 END
                END
            ) * INTERVAL '1 hour' AS hour_beginning,
        location_id,
        location_name,
        location_type,
        da_cleared_generation,
        da_cleared_increments,
        da_cleared_imports,
        da_generation_obligation,
        da_cleared_demand_bids,
        da_cleared_decrements,
        da_cleared_exports,
        da_load_obligation,
        da_internal_bilateral_for_purchases,
        da_internal_bilateral_for_sales,
        da_adjusted_load_obligation,
        da_adjusted_net_interchange,
        da_energy_component,
        da_congestion_component,
        da_marginal_loss_component,
        da_energy_charge_or_credit,
        da_congestion_charge_or_credit,
        da_marginal_loss_charge_or_credit,
        da_cleared_asset_related_demand_bids,
        da_load_obligation_for_charge_allocation,
        da_demand_reduction,
        da_demand_reduction_obligation,
        da_cleared_sodera_load,
        da_cleared_sodera_generation,
    FROM positioned
)
-- skip rows already present, keyed on (account_id, subaccount_id, report_date, version, hour_beginning, location_id)
INSERT INTO tab1
SELECT ti.*
FROM to_insert ti
WHERE NOT EXISTS (
    SELECT 1 FROM tab1 t
    WHERE t.account_id = ti.account_id
    AND t.subaccount_id = ti.subaccount_id
    AND t.report_date = ti.report_date
    AND t.version = ti.version
    AND t.hour_beginning = ti.hour_beginning
    AND t.location_id = ti.location_id
);


SELECT * FROM tab1 ORDER BY subaccount_id, location_id, hour_beginning;


