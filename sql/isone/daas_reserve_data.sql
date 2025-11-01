


SELECT 
    MIN(hour_beginning) as start, 
    MAX(hour_beginning) as end, 
    COUNT(*) as rows
FROM reserve_data;


--- How many times was the FER price > DAM price?
ATTACH '~/Downloads/Archive/DuckDB/isone/dalmp.duckdb' AS lmp;
SELECT 
    hour_beginning, 
    fer_clearing_price, 
    lmp - mcc - mcl AS energy_price
FROM reserve_data
JOIN lmp.da_lmp USING(hour_beginning)
WHERE ptid = 4000
AND fer_clearing_price > energy_price
ORDER BY hour_beginning;



SELECT hour_beginning, forecasted_energy_req_mw, fer_clearing_price, eir_designation_mw, 
FROM reserve_data
WHERE hour_beginning >= '2025-06-25 00:00:00'
AND hour_beginning < '2025-06-26 00:00:00'
ORDER BY hour_beginning;
-- ┌──────────────────────────┬──────────────────────────┬────────────────────┬────────────────────┐
-- │      hour_beginning      │ forecasted_energy_req_mw │ fer_clearing_price │ eir_designation_mw │
-- │ timestamp with time zone │       decimal(9,2)       │    decimal(9,2)    │    decimal(9,2)    │
-- ├──────────────────────────┼──────────────────────────┼────────────────────┼────────────────────┤
-- │ 2025-06-25 00:00:00-04   │                 19160.00 │              11.10 │            1083.30 │
-- │ 2025-06-25 01:00:00-04   │                 18130.00 │               9.50 │             331.10 │
-- │ 2025-06-25 02:00:00-04   │                 17380.00 │              10.35 │              87.20 │
-- │ 2025-06-25 03:00:00-04   │                 16890.00 │               8.02 │             270.80 │
-- │ 2025-06-25 04:00:00-04   │                 16560.00 │               0.00 │               0.00 │
-- │ 2025-06-25 05:00:00-04   │                 16970.00 │               0.00 │               0.00 │
-- │ 2025-06-25 06:00:00-04   │                 17980.00 │               0.00 │               0.00 │
-- │ 2025-06-25 07:00:00-04   │                 19010.00 │               0.00 │               0.00 │
-- │ 2025-06-25 08:00:00-04   │                 19610.00 │              15.90 │             498.70 │
-- │ 2025-06-25 09:00:00-04   │                 19840.00 │              16.88 │             517.50 │
-- │ 2025-06-25 10:00:00-04   │                 20220.00 │              16.69 │             154.30 │
-- │ 2025-06-25 11:00:00-04   │                 20970.00 │              27.64 │             313.70 │
-- │ 2025-06-25 12:00:00-04   │                 21640.00 │              29.92 │             785.20 │
-- │ 2025-06-25 13:00:00-04   │                 22440.00 │              66.45 │             784.50 │
-- │ 2025-06-25 14:00:00-04   │                 22910.00 │              93.02 │             786.00 │
-- │ 2025-06-25 15:00:00-04   │                 23300.00 │              87.73 │             521.30 │
-- │ 2025-06-25 16:00:00-04   │                 23700.00 │              52.42 │             289.40 │
-- │ 2025-06-25 17:00:00-04   │                 23960.00 │              30.99 │             130.90 │
-- │ 2025-06-25 18:00:00-04   │                 23810.00 │               0.00 │               0.00 │
-- │ 2025-06-25 19:00:00-04   │                 23350.00 │               4.42 │              29.80 │
-- │ 2025-06-25 20:00:00-04   │                 22630.00 │              21.23 │              29.80 │
-- │ 2025-06-25 21:00:00-04   │                 21300.00 │              30.96 │             152.30 │
-- │ 2025-06-25 22:00:00-04   │                 19420.00 │              37.22 │             218.50 │
-- │ 2025-06-25 23:00:00-04   │                 17630.00 │              23.60 │             158.50 │
-- ├──────────────────────────┴──────────────────────────┴────────────────────┴────────────────────┤




---==========================================================================
CREATE TEMPORARY TABLE tmp
AS
    SELECT * 
    FROM (
        SELECT unnest(isone_web_services.day_ahead_reserves.day_ahead_reserve, recursive := true)
        FROM read_json('~/Downloads/Archive/IsoExpress/DASI/ReserveData/Raw/2025/daas_reserve_data_2025-03-*.json.gz')
    )
    ORDER BY local_day
;
SELECT * from tmp;

INSERT INTO reserve_data
    SELECT 
        local_day::TIMESTAMPTZ as hour_beginning,
        ten_min_spin_req_mw::DECIMAL(9,2) as ten_min_spin_req_mw,
        total_ten_min_req_mw::DECIMAL(9,2) as total_ten_min_req_mw,
        total_thirty_min_req_mw::DECIMAL(9,2) as total_thirty_min_req_mw,
        forecasted_energy_req_mw::DECIMAL(9,2) as forecasted_energy_req_mw,
        tmsr_clearing_price::DECIMAL(9,2) as tmsr_clearing_price,
        tmnsr_clearing_price::DECIMAL(9,2) as tmnsr_clearing_price,
        tmor_clearing_price::DECIMAL(9,2) as tmor_clearing_price,
        fer_clearing_price::DECIMAL(9,2) as fer_clearing_price,
        tmsr_designation_mw::DECIMAL(9,2) as tmsr_designation_mw,
        tmnsr_designation_mw::DECIMAL(9,2) as tmnsr_designation_mw,
        tmor_designation_mw::DECIMAL(9,2) as tmor_designation_mw,
        eir_designation_mw::DECIMAL(9,2) as eir_designation_mw
    FROM tmp
EXCEPT 
    SELECT * FROM reserve_data;        


-- ========================================================
CREATE TABLE IF NOT EXISTS reserve_data (
    hour_beginning TIMESTAMPTZ NOT NULL,
    ten_min_spin_req_mw DECIMAL(9,2) NOT NULL,
    total_ten_min_req_mw DECIMAL(9,2) NOT NULL,
    total_thirty_min_req_mw DECIMAL(9,2) NOT NULL,
    forecasted_energy_req_mw DECIMAL(9,2) NOT NULL,
    tmsr_clearing_price DECIMAL(9,2) NOT NULL,
    tmnsr_clearing_price DECIMAL(9,2) NOT NULL,
    tmor_clearing_price DECIMAL(9,2) NOT NULL,
    fer_clearing_price DECIMAL(9,2) NOT NULL,
    tmsr_designation_mw DECIMAL(9,2) NOT NULL,
    tmnsr_designation_mw DECIMAL(9,2) NOT NULL,
    tmor_designation_mw DECIMAL(9,2) NOT NULL,
    eir_designation_mw DECIMAL(9,2) NOT NULL,
);









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

