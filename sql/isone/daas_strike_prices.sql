
SELECT * FROM strike_prices;



---========================================================================
CREATE TABLE IF NOT EXISTS strike_prices (
    hour_beginning TIMESTAMPTZ NOT NULL,
    strike_price DECIMAL(9,2) NOT NULL,
    strike_price_timestamp TIMESTAMPTZ NOT NULL,
    spc_load_forecast_mw DECIMAL(9,2) NOT NULL,
    percentile_10_rt_hub_lmp DECIMAL(9,2) NOT NULL,
    percentile_25_rt_hub_lmp DECIMAL(9,2) NOT NULL,
    percentile_75_rt_hub_lmp DECIMAL(9,2) NOT NULL,
    percentile_90_rt_hub_lmp DECIMAL(9,2) NOT NULL, 
    expected_rt_hub_lmp DECIMAL(9,2) NOT NULL,
    expected_rt_hub_lmp_override DECIMAL(9,2),
    expected_closeout_charge DECIMAL(9,2) NOT NULL,
    expected_closeout_charge_override DECIMAL(9,2)
);

CREATE TEMPORARY TABLE tmp
AS
    SELECT 
        json_extract(aux, '$.market_hour.local_day')::TIMESTAMPTZ as hour_beginning,
        json_extract(aux, '$.strike_price')::DECIMAL(9,2) as strike_price,
        json_extract(aux, '$.strike_price_timestamp')::TIMESTAMPTZ as strike_price_timestamp,
        json_extract(aux, '$.spc_load_forecast_mw')::DECIMAL(9,2) as spc_load_forecast_mw,  
        json_extract(aux, '$.percentile_10_rt_hub_lmp')::DECIMAL(9,2) as percentile_10_rt_hub_lmp,
        json_extract(aux, '$.percentile_25_rt_hub_lmp')::DECIMAL(9,2) as percentile_25_rt_hub_lmp,
        json_extract(aux, '$.percentile_75_rt_hub_lmp')::DECIMAL(9,2) as percentile_75_rt_hub_lmp,
        json_extract(aux, '$.percentile_90_rt_hub_lmp')::DECIMAL(9,2) as percentile_90_rt_hub_lmp,
        json_extract(aux, '$.expected_rt_hub_lmp')::DECIMAL(9,2) as expected_rt_hub_lmp,
        json_extract(aux, '$.expected_rt_hub_lmp_override')::DECIMAL(9,2) as expected_rt_hub_lmp_override,
        json_extract(aux, '$.expected_closeout_charge')::DECIMAL(9,2) as expected_closeout_charge,
        json_extract(aux, '$.expected_closeout_charge_override')::DECIMAL(9,2) as expected_closeout_charge_override
    FROM (
        SELECT  unnest(isone_web_services.day_ahead_strike_prices.day_ahead_strike_price)::JSON as aux
        FROM read_json('~/Downloads/Archive/IsoExpress/DASI/StrikePrices/Raw/2025/daas_strike_prices_2025-04-*.json.gz')
    )
    ORDER BY hour_beginning
;


INSERT INTO strike_prices
    SELECT *
    FROM tmp t
WHERE NOT EXISTS (
    SELECT * FROM strike_prices s
    WHERE
        s.hour_beginning = t.hour_beginning
) ORDER BY hour_beginning;










CREATE TEMPORARY TABLE tmp2
AS
    SELECT unnest(isone_web_services.day_ahead_reserves.day_ahead_reserve, recursive := true)
    FROM read_json('~/Downloads/Archive/IsoExpress/DASI/ReserveData/Raw/2025/daas_reserve_data_2025-03-01.json.gz', 
        columns = {
            local_day: 'TIMESTAMPTZ',
            ten_min_spin_req_mw: 'DECIMAL(9,2)',
            total_ten_min_req_mw: 'DECIMAL(9,2)',
            total_thirty_min_req_mw: 'DECIMAL(9,2)',
            forecasted_energy_req_mw: 'DECIMAL(9,2)',
             tmsr_clearing_price: 'DECIMAL(9,2)',
            tmnsr_clearing_price: 'DECIMAL(9,2)',
            tmor_clearing_price: 'DECIMAL(9,2)',
            fer_clearing_price: 'DECIMAL(9,2)',
            tmsr_designation_mw: 'DECIMAL(9,2)',
            tmnsr_designation_mw: 'DECIMAL(9,2)',
            tmor_designation_mw: 'DECIMAL(9,2)',
            eir_designation_mw: 'DECIMAL(9,2)'
        }
    )
;
SELECT * from tmp2;

