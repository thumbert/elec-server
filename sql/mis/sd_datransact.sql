


--==============================================================
CREATE TABLE IF NOT EXISTS tab1 (
    account_id UINTEGER NOT NULL,
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    transaction_number UINTEGER NOT NULL,
    reference_id VARCHAR,
    transaction_type ENUM ('IBM') NOT NULL,
    other_party UINTEGER NOT NULL,
    settlement_location_id UINTEGER NOT NULL,
    location_name VARCHAR NOT NULL,
    location_type ENUM ('HUB', 'LOAD ZONE', 'NETWORK NODE', 'DRR AGGREGATION ZONE') NOT NULL,
    amount DECIMAL(9,4) NOT NULL,
    impacts_marginal_loss_revenue_allocation BOOLEAN NOT NULL,
    subaccount_id VARCHAR NOT NULL,
);
CREATE INDEX idx ON tab1 (report_date);


INSERT INTO tab1 
SELECT 
    account_id::UINTEGER,
    report_date::DATE,
    version::TIMESTAMP,
    strptime(left(hour_beginning, 25), '%Y-%m-%dT%H:%M:%S%z')::TIMESTAMPTZ,
    transaction_number::UINTEGER,
    reference_id::VARCHAR,
    transaction_type::ENUM ('IBM'),
    other_party::UINTEGER,
    settlement_location_id::UINTEGER,
    location_name::VARCHAR,
    location_type::ENUM ('HUB', 'LOAD ZONE', 'NETWORK NODE', 'DRR AGGREGATION ZONE'),
    amount::DECIMAL(9,4),
    impacts_marginal_loss_revenue_allocation::BOOLEAN,
    subaccount_id::VARCHAR
FROM read_csv(
    'C:/Temp/MIS/SD_DATRANSACT/tmp/tab1_*.CSV', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%SZ'
);
