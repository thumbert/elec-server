


CREATE TEMPORARY TABLE tmp
AS
    PIVOT (
        SELECT 
            MarketDate::DATE AS for_day,
            CsoMw::int64 AS cso_mw,
            ColdWeatherOutagesMw::int64 AS cold_weather_outages_mw,
            OtherGenOutagesMw::int64 AS other_gen_outages_mw,
            DelistMw::int64 AS delist_mw,
            TotAvailGenMw::int64 AS total_available_gen_mw,
            PeakImportMw::int64 AS peak_import_mw,
            TotAvailGenImportMw::int64 AS total_available_gen_import_mw,
            PeakLoadMw::int64 AS peak_load_mw,
            ReplReserveReqMw::int64 AS replacement_reserve_req_mw,
            ReqdReserveMw::int64 AS required_reserve_mw,
            ReqdReserveInclReplMw::int64 AS required_reserve_incl_replacement_mw,
            TotLoadPlusReqdReserveMw::int64 AS total_load_plus_required_reserve_mw,
            DrrMw::int64 AS drr_mw,
            SurplusDeficiencyMw::int64 AS surplus_deficiency_mw,
            CASE 
                WHEN PowerWatch = 'Y' THEN TRUE 
                WHEN PowerWatch = 'N' THEN FALSE
                ELSE NULL 
                END AS is_power_watch,
            CASE 
                WHEN PowerWarn = 'Y' THEN TRUE 
                WHEN PowerWarn = 'N' THEN FALSE
                ELSE NULL 
                END AS is_power_warn,
            CASE 
                WHEN ColdWeatherWatch = 'Y' THEN TRUE 
                WHEN ColdWeatherWatch = 'N' THEN FALSE
                ELSE NULL 
                END AS is_cold_weather_watch,
            CASE 
                WHEN ColdWeatherWarn = 'Y' THEN TRUE 
                WHEN ColdWeatherWarn = 'N' THEN FALSE
                ELSE NULL 
                END AS is_cold_weather_warn,
            CASE 
                WHEN ColdWeatherEvent = 'Y' THEN TRUE 
                WHEN ColdWeatherEvent = 'N' THEN FALSE
                ELSE NULL 
                END AS is_cold_weather_event,
            unnest(CityWeather, recursive := true) AS CityWeather,    
            TRY_CAST("day" AS int64) AS "day1",
            TRY_CAST("@Day" AS int64) AS "@Day",
        FROM (

            SELECT 
                *,
                struct_extract(keys, 'day') AS "day",
                -- TRY(keys['@Day']::int64) AS "@Day",
            FROM (
            SELECT 
                unnest(MarketDay, recursive := true), 
                -- MarketDay[1] AS "keys",
                -- json_extract(MarketDay, '$.MarketDay.Day') AS "Day",
                json_extract(MarketDay, '$.MarketDay.@Day') AS "Test",
            FROM (
                SELECT 
                    unnest(sevendayforecasts.sevendayforecast, recursive := true),
                    json_extract(sevendayforecasts.sevendayforecast.MarketDay, '.@Day') as Test
                    -- json_extract(sevendayforecasts.sevendayforecast.MarketDay, '$.MarketDay.@Day') AS "Test",
                FROM read_json('~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-01.json.gz');
            );

            );


        ) 
    ) ON CityName
    USING 
        FIRST(HighTempF) as high_temp_f, 
        FIRST(DewPointF) as dew_point_f
    ORDER BY for_day    
;






    ORDER BY local_day
;
SELECT * from tmp;


----  GOOD STUFF! 
SELECT 
    CAST(aux -> '@Day' AS INTEGER) AS "day",
    CAST(aux -> 'CsoMw' AS INTEGER) AS cso_mw,
FROM (
SELECT 
    unnest(CAST(sevendayforecasts.Sevendayforecast AS JSON) -> '$[0]' -> '$.MarketDay[*]') as aux
FROM read_json('~/Downloads/Archive/IsoExpress/7dayCapacityForecast/Raw/2024/7dayforecast_2024-06-01.json.gz')
  )
;



SELECT json_extract('{"a": 1, "b": 2}', '$.c') AS missing_field;
-- Returns NULL



CREATE TEMP TABLE tmp1 ("D" INTEGER, "@D" INTEGER);  
INSERT INTO tmp1 VALUES (1, NULL), (NULL, 2), (3, NULL), (NULL, 4);
SELECT D, "@D", COALESCE(D, "@D") AS D FROM tmp1;


CREATE TABLE example (j JSON);
INSERT INTO example VALUES
    ('{ "family": "anatidae", "species": [ "duck", "goose", "swan", null ] }');

SELECT json_extract(j, '$.family') FROM example;    
SELECT json_extract(j, '$.key') FROM example;    





