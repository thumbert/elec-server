

CREATE TABLE IF NOT EXISTS eod_settlements_views (
    user_id VARCHAR NOT NULL,
    view_name VARCHAR NOT NULL,
    source VARCHAR NOT NULL,
    row_id UINTEGER NOT NULL,
    ice_category VARCHAR,
    ice_hub VARCHAR,
    ice_product VARCHAR,
    endur_curve_name VARCHAR,
    as_of_date DATE NOT NULL,
    strip VARCHAR,
    unit_conversion VARCHAR,
    label VARCHAR,
);

INSERT INTO eod_settlements_views 
VALUES (
    'adrian', -- user_id
    'ny capacity', -- view_name
    'ice', -- source
    0, -- row_id
    'power', -- ice_category
    'NYISO Rest of State Calendar-Month', -- ice_hub
    'Capacity Futures', -- ice_product
    NULL, -- endur_curve_name
    '2026-01-15', -- as_of_date
    NULL, -- strip
    NULL, -- unit_conversion
);

INSERT INTO eod_settlements_views 
VALUES (
    'adrian', -- user_id
    'ny capacity', -- view_name
    'ice', -- source
    1, -- row_id
    'power', -- ice_category
    'NYISO Rest of State Calendar-Month', -- ice_hub
    'Capacity Futures', -- ice_product
    NULL, -- endur_curve_name
    '2026-03-20', -- as_of_date
    NULL, -- strip
    NULL, -- unit_conversion
);

INSERT INTO eod_settlements_views 
VALUES (
    'adrian', -- user_id
    'ny capacity', -- view_name
    'endur', -- source
    0, -- row_id
    NULL, -- ice_category
    NULL, -- ice_hub
    NULL, -- ice_product
    'PWR_NYISO_ROS_ICE_MWH_ICAP', -- endur_curve_name
    '2026-03-20', -- as_of_date
    NULL, -- strip
    NULL, -- unit_conversion
);
