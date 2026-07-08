SELECT * FROM capacity_seasons LIMIT 5;


---=======================================================================
CREATE TABLE IF NOT EXISTS capacity_seasons (
    id INT64 NOT NULL,
    description VARCHAR NOT NULL
);

CREATE TEMPORARY TABLE tmp
AS (
    SELECT
        json_extract(rows, '$.id')::INT64 as id,
        trim(json_extract(rows, '$.description')::VARCHAR, '"') as description,
    FROM (
        SELECT unnest(rows)::JSON as rows
        FROM read_json('https://icappublic.nyiso.com/ucap/rest/seasons/public')
    )
);

INSERT INTO capacity_seasons
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM capacity_seasons d
        WHERE
            d.id = t.id
    )
);


        -- trim(json_extract(rows, '$.capabilityPeriodType')::VARCHAR, '"')::ENUM('WINTER', 'SUMMER') as capability_period_type,
        -- strptime(trim(json_extract(rows, '$.startDate')::VARCHAR, '"'), '%m/%d/%Y %H:%M:%S') as start_date,
        -- strptime(trim(json_extract(rows, '$.endDate')::VARCHAR, '"'), '%m/%d/%Y %H:%M:%S') as end_date,
