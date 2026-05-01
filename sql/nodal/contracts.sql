SELECT * FROM contracts;

SELECT DISTINCT product_group 
FROM contracts
ORDER BY product_group;
-- ┌────────────────┐
-- │ product_group  │
-- │    varchar     │
-- ├────────────────┤
-- │ Environmental  │
-- │ Natural Gas    │
-- │ Power          │

SELECT * FROM contracts
WHERE product_group = 'Natural Gas';

SELECT * FROM contracts
WHERE physical_commodity_code = 'NGH';




---=================================================================================
CREATE TABLE IF NOT EXISTS contracts (
    physical_commodity_code VARCHAR NOT NULL,
    contract_long_name VARCHAR NOT NULL,
    contract_short_name VARCHAR NOT NULL,
    product_type VARCHAR NOT NULL,
    product_group VARCHAR NOT NULL,
    settlement_type VARCHAR NOT NULL,
    lot_limit_group VARCHAR NOT NULL,
    group_commodity_code VARCHAR NOT NULL,
    count_of_expiries INTEGER NOT NULL,
    block_exchange_fee DECIMAL(18,5) NOT NULL,
    screen_exchange_fee DECIMAL(18,5) NOT NULL,
    efp_exchange_fee DECIMAL(18,5),
    clearing_fee DECIMAL(18,5) NOT NULL,
    settlement_or_option_exercise_assignment_fee DECIMAL(18,5) NOT NULL,
    gmi_exch VARCHAR NOT NULL,
    gmi_fc VARCHAR NOT NULL,
    description VARCHAR NOT NULL,
    reporting_level VARCHAR,
    spot_month_position_limit_lots INTEGER NOT NULL,
    single_month_accountability_level_lots INTEGER NOT NULL,
    all_month_accountability_level_lots INTEGER NOT NULL,
    aggregation_group INTEGER,
    aggregation_group_type VARCHAR,
    parent_contract_flag BOOLEAN,
    cftc_referenced_contract BOOLEAN NOT NULL,
);


CREATE TEMPORARY TABLE tmp
AS 
    SELECT 
     "Physical Commodity Code" as physical_commodity_code,
     "Contract Long Name" as contract_long_name,
     "Contract Short Name" as contract_short_name,
     "Product Type" as product_type,
     trim("Product Group") as product_group,
     "Settlement Type" as settlement_type,
     "Lot Limit Group" as lot_limit_group,
     "Group Commodity Code" as group_commodity_code,
     "Count of Expiries"::INTEGER as count_of_expiries,
     trim("Block Exchange Fee", '$')::DECIMAL(18,5) as block_exchange_fee,
     trim("Screen Exchange Fee", '$')::DECIMAL(18,5) as screen_exchange_fee,
     trim("EFP Exchange Fee", '$')::DECIMAL(18,5) as efp_exchange_fee,
     trim("Clearing Fee", '$')::DECIMAL(18,5) as clearing_fee,
     trim("Settlement or Option Exercise/Assignment Fee", '$')::DECIMAL(18,5) as settlement_or_option_exercise_assignment_fee,
     "GMI Exch" as gmi_exch,
     "GMI FC" as gmi_fc,
     "Description" as description,
     "Reporting Level" as reporting_level,
     "Spot Month Position Limit / Spot Month Accountability Level (Lots)"::INTEGER as spot_month_position_limit_lots,
     "Single Month Accountability Level (Lots)"::INTEGER as single_month_accountability_level_lots,
     "All Month Accountability Level (Lots)"::INTEGER as all_month_accountability_level_lots,
     "Aggregation Group" as aggregation_group,
     "Aggregation Group Type" as aggregation_group_type,
     "Parent Contract Flag"::BOOLEAN as parent_contract_flag,
     "CFTC Referenced Contract"::BOOLEAN as cftc_referenced_contract
    FROM read_csv(
        '/home/adrian/Downloads/Archive/Nodal/Contracts/Nodal_Exchange_Contracts.CSV',
        header = true,
        delim = ',',
        strict_mode = false,
        store_rejects = true, 
        nullstr = ['NULL', 'null', '']
    )
;

INSERT INTO contracts 
    SELECT *
    FROM tmp
WHERE NOT EXISTS (
    SELECT * FROM contracts c
    WHERE
        c.physical_commodity_code = tmp.physical_commodity_code
) ORDER BY physical_commodity_code;       


