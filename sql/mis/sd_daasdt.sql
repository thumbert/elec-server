
SHOW TABLES;
SUMMARIZE tab0;
SUMMARIZE tab1;
SUMMARIZE tab6;
SUMMARIZE tab7;


SELECT * FROM tab0 LIMIT 3;


.mode line
SELECT * FROM tab6 LIMIT 1;

-- Get daily FRS credits to assets by type
SET VARIABLE settlement = 0;
SELECT report_date, 
    versions[LEAST(len(versions), getvariable('settlement') + 1)] as version,
    asset_id, product_type,
    credit[LEAST(len(credit), getvariable('settlement') + 1)] as customer_share_of_product_credit,
    closeout_charge[LEAST(len(closeout_charge), getvariable('settlement') + 1)] as customer_share_of_product_closeout_charge,
FROM (
    SELECT report_date, asset_id, product_type,
    array_agg(version) as versions,
    array_agg(customer_share_of_product_credit) as credit,
    array_agg(customer_share_of_product_closeout_charge) as closeout_charge,
    FROM (
        SELECT report_date, version, asset_id, product_type,  
            sum(customer_share_of_product_credit) as customer_share_of_product_credit,
            sum(customer_share_of_product_closeout_charge) as customer_share_of_product_closeout_charge,
        FROM tab0
        WHERE report_date >= '2024-11-15'
        AND report_date <= '2024-11-15'
        AND account_id = 2
        GROUP BY report_date, version, asset_id, product_type
        ORDER BY report_date, version
    )
    GROUP BY report_date, asset_id, product_type
)
ORDER BY report_date;

-- Get daily FER credit to assets
SET VARIABLE settlement = 0;
SELECT report_date, 
    versions[LEAST(len(versions), getvariable('settlement') + 1)] as version,
    asset_id, 
    credit[LEAST(len(credit), getvariable('settlement') + 1)] as customer_share_of_product_credit,
FROM (
    SELECT report_date, asset_id, 
    array_agg(version) as versions,
    array_agg(customer_share_of_product_credit) as credit,
    FROM (
        SELECT report_date, version, asset_id,  
            sum(customer_share_of_asset_fer_credit) as customer_share_of_product_credit,
        FROM tab1
        WHERE report_date >= '2024-11-15'
        AND report_date <= '2024-11-15'
        AND account_id = 2
        GROUP BY report_date, version, asset_id
        ORDER BY report_date, version
    )
    GROUP BY report_date, asset_id
)
ORDER BY report_date;






-- Get the daily FRS charges to load by type
SET VARIABLE settlement = 0;
UNPIVOT (
    SELECT report_date, 
        versions[LEAST(len(versions), getvariable('settlement') + 1)] as version,
        tmsr[LEAST(len(tmsr), getvariable('settlement') + 1)] as da_tmsr_charge,
        tmnsr[LEAST(len(tmnsr), getvariable('settlement') + 1)] as da_tmnsr_charge,
        tmor[LEAST(len(tmor), getvariable('settlement') + 1)] as da_tmor_charge,
        tmsr_co[LEAST(len(tmsr_co), getvariable('settlement') + 1)] as da_tmsr_closeout_credit,
        tmnsr_co[LEAST(len(tmnsr_co), getvariable('settlement') + 1)] as da_tmnsr_closeout_credit,
        tmor_co[LEAST(len(tmor_co), getvariable('settlement') + 1)] as da_tmor_closeout_credit,
    FROM (
        SELECT report_date, 
        array_agg(version) as versions,
        array_agg(da_tmsr_charge) as tmsr,
        array_agg(da_tmnsr_charge) as tmnsr,
        array_agg(da_tmor_charge) as tmor,
        array_agg(da_tmsr_closeout_credit) as tmsr_co,
        array_agg(da_tmnsr_closeout_credit) as tmnsr_co,
        array_agg(da_tmor_closeout_credit) as tmor_co,
        FROM (
            SELECT report_date, version,  
                sum(da_tmsr_charge) as da_tmsr_charge,
                sum(da_tmnsr_charge) as da_tmnsr_charge,
                sum(da_tmor_charge) as da_tmor_charge,
                sum(da_tmsr_closeout_credit) as da_tmsr_closeout_credit,
                sum(da_tmnsr_closeout_credit) as da_tmnsr_closeout_credit,
                sum(da_tmor_closeout_credit) as da_tmor_closeout_credit,
            FROM tab6
            WHERE report_date >= '2024-11-15'
            AND report_date <= '2024-11-15'
            AND account_id = 2
            GROUP BY report_date, version
            ORDER BY report_date, version
        )
        GROUP BY report_date
    )
    ORDER BY report_date
)
    ON
        da_tmnsr_charge,
        da_tmor_charge,
        da_tmsr_charge,
        da_tmnsr_closeout_credit,
        da_tmor_closeout_credit,
        da_tmsr_closeout_credit
    INTO
        NAME name
        VALUE value;

-- Get FER and EIR charges
UNPIVOT (
    SELECT report_date, 
        versions[LEAST(len(versions), getvariable('settlement') + 1)] as version,
        eir[LEAST(len(eir), getvariable('settlement') + 1)] as fer_and_da_eir_charge,
        eir_co[LEAST(len(eir_co), getvariable('settlement') + 1)] as da_eir_closeout_credit,
    FROM (
        SELECT report_date, 
        array_agg(version) as versions,
        array_agg(fer_and_da_eir_charge) as eir,
        array_agg(da_eir_closeout_credit) as eir_co,
        FROM (
            SELECT report_date, version,  
                sum(fer_and_da_eir_charge) as fer_and_da_eir_charge,
                sum(da_eir_closeout_credit) as da_eir_closeout_credit,
            FROM tab7
            WHERE report_date >= '2024-11-15'
            AND report_date <= '2024-11-15'
            AND account_id = 2
            GROUP BY report_date, version
            ORDER BY report_date, version
        )
        GROUP BY report_date
    )
    ORDER BY report_date
)
    ON
        fer_and_da_eir_charge,
        da_eir_closeout_credit,
    INTO
        NAME name
        VALUE value;





---=====================================================================================
CREATE TABLE IF NOT EXISTS tab0 (
    account_id UINTEGER NOT NULL,
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    asset_id UINTEGER NOT NULL,
    asset_name VARCHAR NOT NULL,
    subaccount_id UINTEGER,
    subaccount_name VARCHAR,
    asset_type ENUM ('GENERATOR', 'ASSET RELATED DEMAND', 'DEMAND RESPONSE RESOURCE'),
    ownership_share FLOAT NOT NULL,
    product_type ENUM ('DA_TMSR', 'DA_TMNSR', 'DA_TMOR', 'DA_EIR'),
    product_obligation DOUBLE,
    product_clearing_price DOUBLE,
    product_credit DOUBLE,
    customer_share_of_product_credit DOUBLE,
    strike_price DOUBLE,
    hub_rt_lmp DOUBLE,
    product_closeout_charge DOUBLE,
    customer_share_of_product_closeout_charge DOUBLE,
);
CREATE INDEX idx ON tab0 (report_date);

CREATE TABLE IF NOT EXISTS tab1 (
    account_id UINTEGER NOT NULL,
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    asset_id UINTEGER NOT NULL,
    asset_name VARCHAR NOT NULL,
    subaccount_id UINTEGER,
    subaccount_name VARCHAR,
    asset_type ENUM ('GENERATOR', 'ASSET RELATED DEMAND', 'DEMAND RESPONSE RESOURCE'),
    ownership_share FLOAT NOT NULL,
    da_cleared_energy DOUBLE,
    fer_price DOUBLE,
    asset_fer_credit DOUBLE,    
    customer_share_of_asset_fer_credit DOUBLE,
);
CREATE INDEX idx ON tab1 (report_date);

CREATE TABLE IF NOT EXISTS tab6 (
    account_id UINTEGER NOT NULL,
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    subaccount_id UINTEGER,
    subaccount_name VARCHAR,
    hour_beginning TIMESTAMPTZ NOT NULL,
    rt_load_obligation DOUBLE,
    rt_external_node_load_obligation DOUBLE,
    rt_dard_load_obligation_reduction DOUBLE,
    rt_load_obligation_for_frs_charge_allocation DOUBLE,
    pool_rt_load_obligation_for_frs_charge_allocation DOUBLE,
    pool_da_tmsr_credit DOUBLE,
    da_tmsr_charge DOUBLE,
    pool_da_tmnsr_credit DOUBLE,
    da_tmnsr_charge DOUBLE,
    pool_da_tmor_credit DOUBLE,
    da_tmor_charge DOUBLE,
    pool_da_tmsr_closeout_charge DOUBLE,
    da_tmsr_closeout_credit DOUBLE,
    pool_da_tmnsr_closeout_charge DOUBLE,
    da_tmnsr_closeout_credit DOUBLE,
    pool_da_tmor_closeout_charge DOUBLE,
    da_tmor_closeout_credit DOUBLE,
);
CREATE INDEX idx ON tab6 (report_date);

CREATE TABLE IF NOT EXISTS tab7 (
    account_id UINTEGER NOT NULL,
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    subaccount_id UINTEGER,
    subaccount_name VARCHAR,
    hour_beginning TIMESTAMPTZ NOT NULL,
    rt_load_obligation DOUBLE,
    rt_external_node_load_obligation DOUBLE,
    rt_dard_load_obligation_reduction DOUBLE,
    rt_load_obligation_for_da_eir_charge_allocation DOUBLE,
    pool_rt_load_obligation_for_da_eir_charge_allocation DOUBLE,
    pool_da_eir_credit DOUBLE,
    pool_fer_credit DOUBLE,
    pool_export_fer_charge DOUBLE,
    pool_fer_and_da_eir_net_credits DOUBLE,
    fer_and_da_eir_charge DOUBLE,
    pool_da_eir_closeout_charge DOUBLE,
    da_eir_closeout_credit DOUBLE,
);
CREATE INDEX idx ON tab7 (report_date);






--- the column hour_beginning needs to be transformed from VARCHAR into TIMESTAMPTZ
---
INSERT INTO tab0 
SELECT account_id, 
    report_date, 
    version, 
    strptime(left(hour_beginning, 25), '%Y-%m-%dT%H:%M:%S%z') AS hour_beginning,
    asset_id,
    asset_name,
    subaccount_id,
    subaccount_name,
    asset_type,
    ownership_share,
    product_type,
    product_obligation,
    product_clearing_price,
    product_credit,
    customer_share_of_product_credit,
    strike_price,
    hub_rt_lmp,
    product_closeout_charge,
    customer_share_of_product_closeout_charge,
FROM read_csv(
    '/home/adrian/Downloads/Archive/Mis/SD_DAASDT/tmp/tab0_*.CSV', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%SZ'
);


INSERT INTO tab1 
SELECT account_id, 
    report_date, 
    version, 
    strptime(left(hour_beginning, 25), '%Y-%m-%dT%H:%M:%S%z') AS hour_beginning,
    asset_id,
    asset_name,
    subaccount_id,
    subaccount_name,
    asset_type,
    ownership_share,
    da_cleared_energy,
    fer_price,
    asset_fer_credit,
    customer_share_of_asset_fer_credit,
FROM read_csv(
    '/home/adrian/Downloads/Archive/Mis/SD_DAASDT/tmp/tab1_*.CSV', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%SZ'
);


INSERT INTO tab6 
SELECT account_id, 
    report_date, 
    version, 
    subaccount_id,
    subaccount_name,
    strptime(left(hour_beginning, 25), '%Y-%m-%dT%H:%M:%S%z') AS hour_beginning,
    rt_load_obligation,
    rt_external_node_load_obligation,
    rt_dard_load_obligation_reduction,
    rt_load_obligation_for_frs_charge_allocation,
    pool_rt_load_obligation_for_frs_charge_allocation,
    pool_da_tmsr_credit,
    da_tmsr_charge,
    pool_da_tmnsr_credit,
    da_tmnsr_charge,
    pool_da_tmor_credit,
    da_tmor_charge,
    pool_da_tmsr_closeout_charge,
    da_tmsr_closeout_credit,
    pool_da_tmnsr_closeout_charge,
    da_tmnsr_closeout_credit,
    pool_da_tmor_closeout_charge,
    da_tmor_closeout_credit,
FROM read_csv(
    '/home/adrian/Downloads/Archive/Mis/SD_DAASDT/tmp/tab6_*.CSV', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%SZ'
);


INSERT INTO tab7 
SELECT account_id, 
    report_date, 
    version, 
    subaccount_id,
    subaccount_name,
    strptime(left(hour_beginning, 25), '%Y-%m-%dT%H:%M:%S%z') AS hour_beginning,
    rt_load_obligation,
    rt_external_node_load_obligation,
    rt_dard_load_obligation_reduction,
    rt_load_obligation_for_da_eir_charge_allocation,
    pool_rt_load_obligation_for_da_eir_charge_allocation,
    pool_da_eir_credit,
    pool_fer_credit,
    pool_export_fer_charge,
    pool_fer_and_da_eir_net_credits,
    fer_and_da_eir_charge,
    pool_da_eir_closeout_charge,
    da_eir_closeout_credit,
FROM read_csv(
    '/home/adrian/Downloads/Archive/Mis/SD_DAASDT/tmp/tab7_*.CSV', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%SZ'
);








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