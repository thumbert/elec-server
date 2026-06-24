
SELECT * from fuel_mix
ORDER BY zoned;

SELECT MIN(zoned), MAX(zoned), COUNT(*) FROM fuel_mix;

SELECT strftime(zoned, '%Y-%m') AS month, COUNT(*) AS count
FROM fuel_mix
GROUP BY month
ORDER BY month;

-- missing an hour on 2024-06
SELECT strftime(zoned, '%Y-%m-%d') AS day, COUNT(*) AS count
FROM fuel_mix
WHERE strftime(zoned, '%Y-%m') = '2025-03'
GROUP BY day
ORDER BY day;

-- missing hours on 2024-03-15, 2024-06-30, 
---   2025-03-08 22:30:00-05:00 (values are doubled), 








---==================================================================================
---  HQ Fuel Mix
---==================================================================================
CREATE TABLE IF NOT EXISTS fuel_mix (
    zoned TIMESTAMPTZ NOT NULL,
    total INT64 NOT NULL,
    hydro INT64 NOT NULL,
    wind INT64 NOT NULL,
    solar INT64 NOT NULL,
    other INT64 NOT NULL,
    thermal INT64 NOT NULL
);

CREATE TEMPORARY TABLE tmp
AS
    SELECT
        make_timestamptz(epoch_us("time")) AS zoned,
        total::INT64 AS total,
        hydraulique::INT64 AS hydro,
        eolien::INT64 AS wind,
        solaire::INT64 AS solar,
        autres::INT64 AS other,
        thermique::INT64 AS thermal,
    FROM (
        SELECT unnest(data, recursive := true)
        FROM read_json('~/Downloads/Archive/HQ/FuelMix/Raw/2025/fuel_mix_2025-03-08.json.gz')
    )
    WHERE total != 0
    ORDER BY zoned
;


INSERT INTO fuel_mix
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM fuel_mix d
        WHERE
            d.zoned = t.zoned AND
            d.total = t.total AND
            d.hydro = t.hydro
    )
) ORDER BY zoned; 

