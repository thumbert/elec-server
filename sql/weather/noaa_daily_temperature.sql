

CREATE TABLE noaa_daily_temperature (
    station_id STRING,
    date DATE,
    tmax SMALLINT,
    tmin SMALLINT,
);

CREATE TEMPORARY TABLE tmp AS (
    SELECT 
        STATION AS station_id,
        DATE::DATE AS date,
        TMAX::SMALLINT AS tmax,
        TMIN::SMALLINT AS tmin,
    FROM
        read_csv('https://www.ncei.noaa.gov/access/services/data/v1?dataset=daily-summaries&dataTypes=TMIN,TMAX&stations=USW00014732&startDate=2025-01-01&endDate=2025-12-31&format=csv&units=standard&includeStationName=false')
);


INSERT INTO noaa_daily_temperature (
    SELECT * FROM tmp
    WHERE NOT EXISTS 
    (
        SELECT 1 FROM noaa_daily_temperature AS a
        WHERE a.station_id = tmp.station_id
        AND a.date = tmp.date
    )
);
