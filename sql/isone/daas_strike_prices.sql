
-- Wow!  This is slick! 
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

