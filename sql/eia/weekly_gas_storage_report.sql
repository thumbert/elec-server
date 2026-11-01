SELECT *
FROM weekly_gas_storage
ORDER BY day;

-- ==============================================================================
CREATE TABLE IF NOT EXISTS weekly_gas_storage (
    day DATE NOT NULL,
    value DOUBLE NOT NULL
);


-- Set EIA_API_KEY in the environment before running this script.
SET VARIABLE eia_api_key = getenv('EIA_API_KEY');
LOAD httpfs;

-- Note that the API really needs to use encoding for the query parameters!
-- It will fail if the %5B and %5D are not used for array indexing in the query parameters!
CREATE OR REPLACE TEMP TABLE tmp AS
SELECT
    CAST(point.period AS DATE) AS day,
    CAST(point.value AS DOUBLE) AS value
FROM read_json_auto(
    'https://api.eia.gov/v2/natural-gas/stor/wkly/data/?api_key='
    || getvariable('eia_api_key')
    || '&frequency=weekly&data%5B0%5D=value'
    || '&facets%5Bseries%5D%5B%5D=NW2_EPG0_SWO_R48_BCF'
    || '&sort%5B0%5D%5Bcolumn%5D=period'
    || '&sort%5B0%5D%5Bdirection%5D=asc'
    || '&start=2026-08-01'
) AS api_response
CROSS JOIN UNNEST(api_response.response.data) AS eia_rows(point);

INSERT INTO weekly_gas_storage (
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT 1
        FROM weekly_gas_storage wgs
        WHERE wgs.day = t.day
    )   
) ORDER BY day;

