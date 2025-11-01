
SELECT * 
FROM capacity_forecast;

SELECT min(for_day) AS min_date, max(for_day) AS max_date
FROM capacity_forecast;



---====================================================================================================
---====================================================================================================
---====================================================================================================

CREATE TABLE IF NOT EXISTS capacity_forecast (
    for_day DATE NOT NULL,
    day_index UINT8 NOT NULL,
    cso_mw INT,
    cold_weather_outages_mw INT,
    other_gen_outages_mw INT,
    delist_mw INT,
    total_available_gen_mw INT,
    peak_import_mw INT,
    total_available_gen_import_mw INT,
    peak_load_mw INT,
    replacement_reserve_req_mw INT,
    required_reserve_mw INT,
    required_reserve_incl_replacement_mw INT,
    total_load_plus_required_reserve_mw INT,
    drr_mw INT,
    surplus_deficiency_mw INT,
    is_power_watch BOOLEAN,
    is_power_warn BOOLEAN, 
    is_cold_weather_watch BOOLEAN,
    is_cold_weather_warn BOOLEAN,
    is_cold_weather_event BOOLEAN,
    boston_high_temp_F INT1,
    boston_dew_point_F INT1,
    hartford_high_temp_F INT1,
    hartford_dew_point_F INT1,
);


-- format from 1/1/2023 to 6/16/2024
CREATE TEMPORARY TABLE tmp
AS
    PIVOT (
        SELECT 
            * EXCLUDE (city_weather),
            CAST(city_weather ->> 'CityName' AS STRING) AS city_name,
            CAST(city_weather -> 'HighTempF' AS INT1) AS high_temp_f,
            CAST(city_weather -> 'DewPointF' AS INT1) AS dew_point_f
        FROM (
        SELECT 
            CAST(aux -> 'MarketDate' AS DATE) AS for_day,
            CAST(aux -> '@Day' AS INTEGER) AS day_index,
            CAST(aux -> 'CsoMw' AS INTEGER) AS cso_mw,
            CAST(aux -> 'ColdWeatherOutagesMw' AS INTEGER) AS cold_weather_outages_mw,
            CAST(aux -> 'OtherGenOutagesMw' AS INTEGER) AS other_gen_outages_mw,
            CAST(aux -> 'DelistMw' AS INTEGER) AS delist_mw,
            CAST(aux -> 'TotAvailGenMw' AS INTEGER) AS total_available_gen_mw,
            CAST(aux -> 'PeakImportMw' AS INTEGER) AS peak_import_mw,    
            CAST(aux -> 'TotAvailGenImportMw' AS INTEGER) AS total_available_gen_import_mw,
            CAST(aux -> 'PeakLoadMw' AS INTEGER) AS peak_load_mw,
            CAST(aux -> 'ReplReserveReqMw' AS INTEGER) AS replacement_reserve_req_mw,
            CAST(aux -> 'ReqdReserveMw' AS INTEGER) AS required_reserve_mw,
            CAST(aux -> 'ReqdReserveInclReplMw' AS INTEGER) AS required_reserve_incl_replacement_mw,
            CAST(aux -> 'TotLoadPlusReqdReserveMw' AS INTEGER) AS total_load_plus_required_reserve_mw,
            CAST(aux -> 'DrrMw' AS INTEGER) AS drr_mw,
            CAST(aux -> 'SurplusDeficiencyMw' AS INTEGER) AS surplus_deficiency_mw,
            CASE 
                WHEN aux ->> 'PowerWatch' = 'Y' THEN TRUE 
                WHEN aux ->> 'PowerWatch' = 'N' THEN FALSE
                ELSE NULL 
                END AS is_power_watch,
            CASE 
                WHEN aux ->> 'PowerWarn' = 'Y' THEN TRUE 
                WHEN aux ->> 'PowerWarn' = 'N' THEN FALSE        
                ELSE NULL 
                END AS is_power_warn,
            CASE 
                WHEN aux ->> 'ColdWeatherWatch' = 'Y' THEN TRUE 
                WHEN aux ->> 'ColdWeatherWatch' = 'N' THEN FALSE
                ELSE NULL 
                END AS is_cold_weather_watch,
            CASE 
                WHEN aux ->> 'ColdWeatherWarn' = 'Y' THEN TRUE 
                WHEN aux ->> 'ColdWeatherWarn' = 'N' THEN FALSE
                ELSE NULL 
                END AS is_cold_weather_warn,
            CASE 
                WHEN aux ->> 'ColdWeatherEvent' = 'Y' THEN TRUE 
                WHEN aux ->> 'ColdWeatherEvent' = 'N' THEN FALSE
                ELSE NULL    
                END AS is_cold_weather_event,
            unnest(aux -> '$.Weather' -> '$.CityWeather[*]', recursive := true) AS city_weather,  
            FROM (
                SELECT 
                    unnest(CAST(sevendayforecasts.Sevendayforecast AS JSON) -> '$[0]' -> '$.MarketDay[*]') as aux
                -- FROM read_json('~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-05-*.json.gz')
                FROM read_json(
                    ['~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-01.json.gz',
                     '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-02.json.gz',
                     '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-03.json.gz',
                    '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-04.json.gz',
                     '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-05.json.gz',
                     '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-06.json.gz',
                        '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-07.json.gz',
                        '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-08.json.gz',
                        '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-09.json.gz',
                        '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-10.json.gz',
                        '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-11.json.gz',
                        '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-12.json.gz',
                        '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-13.json.gz',
                        '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-14.json.gz',
                        '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-15.json.gz',
                        '~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-16.json.gz'
                     ])
            )
        ) 
    ) ON city_name 
    USING 
        FIRST(high_temp_f) as high_temp_f, 
        FIRST(dew_point_f) as dew_point_f
    ORDER BY for_day, day_index    
;


--- How to get only some files from the month of interest!
SELECT file_name 
FROM (
    SELECT 
        file as file_name,
        regexp_extract(file, '7dayforecast_(\d{4}-\d{2}-\d{2})\.json\.gz', 1)::DATE AS extracted_date
    FROM glob('~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-*.json.gz')
    WHERE extracted_date < '2024-06-17'
);






SELECT * FROM glob('~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-0?.json.gz')
UNION ALL
SELECT * FROM glob('~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-1[0-6].json.gz');


-- format from 1/1/2022 -> 12/31/2022 and 6/17/2024 -> present
-- Note:  I couldn't simply unnest the whole file at once because the ISO sometimes publishes empty files
-- which breaks the unnesting process.  So I have to select each column by hand.
CREATE TEMPORARY TABLE tmp
AS
    PIVOT (
        SELECT 
            * EXCLUDE (city_weather),
            CAST(city_weather ->> 'CityName' AS STRING) AS city_name,
            CAST(city_weather -> 'HighTempF' AS INT1) AS high_temp_F,
            CAST(city_weather -> 'DewPointF' AS INT1) AS dew_point_F
        FROM (
        SELECT 
            CAST(aux -> 'MarketDate' AS DATE) AS for_day,
            CAST(aux -> 'Day' AS INTEGER) AS day_index,
            CAST(aux -> 'CsoMw' AS INTEGER) AS cso_mw,
            CAST(aux -> 'ColdWeatherOutagesMw' AS INTEGER) AS cold_weather_outages_mw,
            CAST(aux -> 'OtherGenOutagesMw' AS INTEGER) AS other_gen_outages_mw,
            CAST(aux -> 'DelistMw' AS INTEGER) AS delist_mw,
            CAST(aux -> 'TotAvailGenMw' AS INTEGER) AS total_available_gen_mw,
            CAST(aux -> 'PeakImportMw' AS INTEGER) AS peak_import_mw,    
            CAST(aux -> 'TotAvailGenImportMw' AS INTEGER) AS total_available_gen_import_mw,
            CAST(aux -> 'PeakLoadMw' AS INTEGER) AS peak_load_mw,
            CAST(aux -> 'ReplReserveReqMw' AS INTEGER) AS replacement_reserve_req_mw,
            CAST(aux -> 'ReqdReserveMw' AS INTEGER) AS required_reserve_mw,
            CAST(aux -> 'ReqdReserveInclReplMw' AS INTEGER) AS required_reserve_incl_replacement_mw,
            CAST(aux -> 'TotLoadPlusReqdReserveMw' AS INTEGER) AS total_load_plus_required_reserve_mw,
            CAST(aux -> 'DrrMw' AS INTEGER) AS drr_mw,
            CAST(aux -> 'SurplusDeficiencyMw' AS INTEGER) AS surplus_deficiency_mw,
            CASE 
                WHEN aux ->> 'PowerWatch' = 'Y' THEN TRUE 
                WHEN aux ->> 'PowerWatch' = 'N' THEN FALSE
                ELSE NULL 
                END AS is_power_watch,
            CASE 
                WHEN aux ->> 'PowerWarn' = 'Y' THEN TRUE 
                WHEN aux ->> 'PowerWarn' = 'N' THEN FALSE        
                ELSE NULL 
                END AS is_power_warn,
            CASE 
                WHEN aux ->> 'ColdWeatherWatch' = 'Y' THEN TRUE 
                WHEN aux ->> 'ColdWeatherWatch' = 'N' THEN FALSE
                ELSE NULL 
                END AS is_cold_weather_watch,
            CASE 
                WHEN aux ->> 'ColdWeatherWarn' = 'Y' THEN TRUE 
                WHEN aux ->> 'ColdWeatherWarn' = 'N' THEN FALSE
                ELSE NULL 
                END AS is_cold_weather_warn,
            CASE 
                WHEN aux ->> 'ColdWeatherEvent' = 'Y' THEN TRUE 
                WHEN aux ->> 'ColdWeatherEvent' = 'N' THEN FALSE
                ELSE NULL    
                END AS is_cold_weather_event,
            unnest(aux -> '$.Weather' -> '$.CityWeather[*]', recursive := true) AS city_weather,  
            FROM (
                SELECT 
                    unnest(CAST(sevendayforecasts.Sevendayforecast AS JSON) -> '$[0]' -> '$.MarketDay[*]') as aux
                FROM read_json('~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-07-*.json.gz')
            )
        ) 
    ) ON city_name 
    USING 
        FIRST(high_temp_f) as high_temp_f, 
        FIRST(dew_point_f) as dew_point_f
    ORDER BY for_day    
;


INSERT INTO capacity_forecast
    SELECT * FROM tmp
WHERE NOT EXISTS (
    SELECT * FROM capacity_forecast
        WHERE capacity_forecast.for_day = tmp.for_day
        AND capacity_forecast.day_index = tmp.day_index
) ORDER BY for_day, day_index;






----  GOOD STUFF! 







WITH city_weather AS (
    SELECT     
        -- aux -> '$.Weather' -> '$.CityWeather[*]' AS city_weather
        unnest(aux -> '$.Weather' -> '$.CityWeather[*]', recursive := true) AS city_weather
    FROM (
        SELECT 
            unnest(CAST(sevendayforecasts.Sevendayforecast AS JSON) -> '$[0]' -> '$.MarketDay[*]') as aux
        FROM read_json('~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-01.json.gz')
    );
)
SELECT
    CAST(city_weather -> 'CityName' AS STRING) AS city_name,
    CAST(city_weather -> 'HighTempF' AS INT1) AS high_temp_f,
    CAST(city_weather -> 'DewPointF' AS INT1) AS dew_point_f
FROM city_weather;






--- Empty file!
SELECT 
    unnest(CAST(sevendayforecasts AS JSON) -> '$.SevenDayForecast' -> '$[0]' -> '$.MarketDay[*]', recursive := true) AS market_days
FROM read_json('~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2023/7dayforecast_2023-09-18.json.gz');


CREATE TABLE example (j JSON);
INSERT INTO example VALUES
    ('{ "family": "anatidae", "species": [ "duck", "goose", "swan", null ] }');


CREATE TEMPORARY TABLE weather (j JSON); 
INSERT INTO weather VALUES 
    ('[{"CityName":"Boston","HighTempF":74,"DewPointF":56}, {"CityName":"Hartford","HighTempF":83,"DewPointF":52}]'),
    ('[{"CityName":"Boston","HighTempF":74,"DewPointF":56}, {"CityName":"Hartford","HighTempF":84,"DewPointF":55}]'),
    ('[{"CityName":"Boston","HighTempF":71,"DewPointF":57}, {"CityName":"Hartford","HighTempF":84,"DewPointF":57}]'),
    ('[{"CityName":"Boston","HighTempF":74,"DewPointF":60}, {"CityName":"Hartford","HighTempF":82,"DewPointF":61}]'),
    ('[{"CityName":"Boston","HighTempF":72,"DewPointF":62}, {"CityName":"Hartford","HighTempF":80,"DewPointF":63}]');
SELECT * FROM weather;


    WITH city_weather AS (
        SELECT 
            unnest(j -> '$[*]', recursive := true) AS city_weather
        FROM weather AS w
    )
    SELECT
        CAST(city_weather -> 'CityName' AS STRING) AS city_name,
        CAST(city_weather -> 'HighTempF' AS INT1) AS high_temp_f,
        CAST(city_weather -> 'DewPointF' AS INT1) AS dew_point_f
    FROM city_weather
;





