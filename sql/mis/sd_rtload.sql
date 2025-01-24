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

SELECT * FROM tab0 LIMIT 3;






INSERT INTO tab0
FROM read_csv(
    '/home/adrian/Downloads/Archive/Mis/SD_RTLOAD/tmp/tab0_*.CSV', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%SZ'
);


CREATE TEMP TABLE tbl AS
SELECT * 
FROM read_csv(
    '/home/adrian/Downloads/Archive/Mis/SD_RTLOAD/tmp/tab0_*.CSV', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%SZ'
);


.mode line  
.mode duckbox
SELECT * FROM tbl LIMIT 2; 



CREATE TEMP TABLE tbl2 AS




LIMIT 2;