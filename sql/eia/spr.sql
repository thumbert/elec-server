SELECT * FROM spr;


-- ==============================================================================
CREATE TABLE IF NOT EXISTS spr (
    month VARCHAR NOT NULL,
    value DOUBLE NOT NULL
);


-- Set EIA_API_KEY in the environment before running this script.
SET VARIABLE eia_api_key = getenv('EIA_API_KEY');
LOAD httpfs;

-- Note that the API really needs to use encoding for the query parameters!
-- It will fail if the %5B and %5D are not used for array indexing in the query parameters!
CREATE OR REPLACE TEMP TABLE tmp AS
SELECT
    point.period AS month,
    CAST(point.value AS DOUBLE) AS value
FROM read_json_auto(
    'https://api.eia.gov/v2/petroleum/stoc/typ/data/?api_key='
    || getvariable('eia_api_key')
    || '&frequency=monthly&data%5B0%5D=value'
    || '&facets%5Bseries%5D%5B%5D=M_EP00_SAS_NUS_MBBL'
    || '&sort%5B0%5D%5Bcolumn%5D=period'
    || '&sort%5B0%5D%5Bdirection%5D=asc'
    || '&start=2026-01'
) AS api_response
CROSS JOIN UNNEST(api_response.response.data) AS eia_rows(point);

INSERT INTO spr (
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT 1
        FROM spr s
        WHERE s.month = t.month
    )   
) ORDER BY month;

