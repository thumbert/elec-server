
SELECT * FROM views_asof_date
WHERE user_id = 'adrian'
LIMIT 5;


SELECT DISTINCT user_id, view_name
FROM views_asof_date
ORDER BY user_id, view_name;



---========================================================================
CREATE TABLE IF NOT EXISTS views_asof_date (
    user_id VARCHAR NOT NULL,
    view_name VARCHAR NOT NULL,
    row_id UINTEGER NOT NULL,
    source VARCHAR NOT NULL,
    ice_category VARCHAR,
    ice_hub VARCHAR,
    ice_product VARCHAR,
    endur_curve_name VARCHAR,
    nodal_contract_name VARCHAR,
    as_of_date DATE NOT NULL,
    strip VARCHAR,
    unit_conversion VARCHAR,
    label VARCHAR,
);

CREATE TEMPORARY TABLE tmp
AS 
    SELECT *
    FROM read_csv(
        '/home/adrian/Downloads/Archive/UI/eod_settlements/views_asof_date.csv',
        header = true,
        nullstr = ['NULL', 'null', '']
    )
    ORDER BY user_id, view_name, row_id;

INSERT INTO views_asof_date 
SELECT *
FROM tmp;       

