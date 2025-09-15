
SELECT * from fuel_mix
ORDER BY zoned;


---==================================================================================
---  HQ Fuel Mix
---==================================================================================
CREATE TABLE IF NOT EXISTS fuel_mix (
    zoned TIMESTAMPTZ NOT NULL,
    total DECIMAL(9,2) NOT NULL,
    hydro DECIMAL(9,2) NOT NULL,
    wind DECIMAL(9,2),
    solar DECIMAL(9,2),
    other DECIMAL(9,2),
    thermal DECIMAL(9,2)
);

CREATE TEMPORARY TABLE tmp
AS
    SELECT
        date::TIMESTAMPTZ AS zoned,
        valeurs_total::DECIMAL(9,2) AS total,
        valeurs_hydraulique::DECIMAL(9,2) AS hydro,
        valeurs_eolien::DECIMAL(9,2) AS wind,
        valeurs_solaire::DECIMAL(9,2) AS solar,
        valeurs_autres::DECIMAL(9,2) AS other,
        valeurs_thermique::DECIMAL(9,2) AS thermal,
    FROM (
        SELECT unnest(results, recursive := true)
        FROM read_json('~/Downloads/Archive/HQ/FuelMix/Raw/2025/fuel_mix_2025-09-15.json.gz')
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

