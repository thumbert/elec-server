
SELECT * FROM tab0 LIMIT 3;



-- How to get different settlement versions
--=========================================
-- You need 3 selects.  This is what they do starting from the inner most one:
-- 1. get the variables you want and make sure the rows are ordered by (asset_id, hour_beginning, version)
-- 2. construct a list of share_of_load_reading for each (asset_id, hour_beginning).  The list elements 
--    are ordered by version
-- 3. get the share_of_load_reading for the version you want.  The version is determined by the variable
SET VARIABLE settlement = 1;
SELECT asset_id, hour_beginning, 
    versions[LEAST(len(versions), getvariable('settlement') + 1)] as version,
    slr[LEAST(len(slr), getvariable('settlement') + 1)] as share_of_load_reading
FROM (
    SELECT report_date, asset_id, hour_beginning, 
      array_agg(version) as versions,
      array_agg(share_of_load_reading) as slr
    FROM (
        SELECT report_date, asset_id, hour_beginning, version, share_of_load_reading,
        FROM tab0
        WHERE report_date == '2024-08-01'
        AND asset_id = 2481
        ORDER BY report_date, asset_id, hour_beginning, version
    )
    GROUP BY report_date, asset_id, hour_beginning
)
ORDER BY asset_id, hour_beginning;



--===============================================================================================
CREATE TABLE IF NOT EXISTS tab0 (
    account_id UINTEGER NOT NULL,
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    asset_name VARCHAR NOT NULL,
    asset_id UINTEGER NOT NULL,
    asset_subtype ENUM ('LOSSES', 'NORMAL', 'STATION SERVICE', 'ENERGY STORAGE', 'PUMP STORAGE'),
    location_id UINTEGER NOT NULL,
    location_name VARCHAR NOT NULL,
    location_type ENUM ('METERING DOMAIN', 'NETWORK NODE'),
    load_reading DOUBLE NOT NULL,
    ownership_share FLOAT NOT NULL,
    share_of_load_reading DOUBLE NOT NULL,
    subaccount_id UINTEGER,
    subaccount_name VARCHAR,
);
CREATE INDEX idx ON tab0 (report_date);


--- the column hour_beginning needs to be transformed from VARCHAR into TIMESTAMPTZ
---
INSERT INTO tab0 
SELECT account_id, report_date, version, 
    strptime(left(hour_beginning, 25), '%Y-%m-%dT%H:%M:%S%z') AS hour_beginning,
    asset_name,
    asset_id,
    asset_subtype,
    location_id,
    location_name,
    location_type,
    load_reading,
    ownership_share,
    share_of_load_reading,
    subaccount_id,
    subaccount_name
FROM read_csv(
    '/home/adrian/Downloads/Archive/Mis/SD_RTLOAD/tmp/tab0_*.CSV', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%SZ'
);






