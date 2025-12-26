LOAD icu; SET TimeZone = 'America/Los_Angeles';

SELECT MIN(hour_beginning), MAX(hour_beginning), COUNT(*) FROM public_bids_da;



---========================================================================
CREATE TABLE IF NOT EXISTS public_bids_da (
    hour_beginning TIMESTAMPTZ NOT NULL,
    resource_type ENUM('GENERATOR', 'INTERTIE', 'LOAD') NOT NULL,
    scheduling_coordinator_seq UINTEGER NOT NULL,
    resource_bid_seq UINTEGER NOT NULL,
    time_interval_start TIMESTAMPTZ,
    time_interval_end TIMESTAMPTZ,
    product_bid_desc VARCHAR,
    product_bid_mrid VARCHAR,
    market_product_desc VARCHAR,
    market_product_type VARCHAR,
    self_sched_mw DECIMAL(9,4),
    sch_bid_time_interval_start TIMESTAMPTZ,
    sch_bid_time_interval_end TIMESTAMPTZ,
    sch_bid_xaxis_data DECIMAL(9,4),
    sch_bid_y1axis_data DECIMAL(9,4),
    sch_bid_y2axis_data DECIMAL(9,4),
    sch_bid_curve_type ENUM('BIDPRICE'),
    min_eoh_state_of_charge DECIMAL(9,4),
    max_eoh_state_of_charge DECIMAL(9,4),
);

LOAD icu; SET TimeZone = 'America/Los_Angeles';
CREATE TEMPORARY TABLE tmp 
AS 
    SELECT 
        "STARTTIME" AS hour_beginning,
        "RESOURCE_TYPE"::ENUM('GENERATOR','INTERTIE', 'LOAD') AS resource_type,
        "SCHEDULINGCOORDINATOR_SEQ"::UINTEGER AS scheduling_coordinator_seq,
        "RESOURCEBID_SEQ"::UINTEGER AS resource_bid_seq,
        "TIMEINTERVALSTART" AS time_interval_start,
        "TIMEINTERVALEND" AS time_interval_end,
        "PRODUCTBID_DESC" AS product_bid_desc,
        "PRODUCTBID_MRID" AS product_bid_mrid,
        "MARKETPRODUCT_DESC" AS market_product_desc,
        "MARKETPRODUCTTYPE" AS market_product_type,
        "SELFSCHEDMW"::DECIMAL(9,4) AS self_sched_mw,
        "SCH_BID_TIMEINTERVALSTART" AS sch_bid_time_interval_start,
        "SCH_BID_TIMEINTERVALSTOP" AS sch_bid_time_interval_end,
        "SCH_BID_XAXISDATA"::DECIMAL(9,4) AS sch_bid_xaxis_data,
        "SCH_BID_Y1AXISDATA"::DECIMAL(9,4) AS sch_bid_y1axis_data,
        "SCH_BID_Y2AXISDATA"::DECIMAL(9,4) AS sch_bid_y2axis_data,
        "SCH_BID_CURVETYPE"::ENUM('BIDPRICE') AS sch_bid_curve_type,
        "MINEOHSTATEOFCHARGE"::DECIMAL(9,4) AS min_eoh_state_of_charge,
        "MAXEOHSTATEOFCHARGE"::DECIMAL(9,4) AS max_eoh_state_of_charge
    FROM read_csv(
        '/home/adrian/Downloads/Archive/Caiso/PublicBids/Raw/2025/20250101_20250101_PUB_BID_DAM_v3.csv.gz',
        header = true,
        timestampformat = 'YYYY-MM-DD HH:MM:SS.000'
    )
    ORDER BY hour_beginning, resource_bid_seq 
;

INSERT INTO public_bids_da
(
    SELECT * FROM tmp
    WHERE NOT EXISTS (
        SELECT 1 FROM public_bids_da AS pb
        WHERE pb.hour_beginning = tmp.hour_beginning
          AND pb.resource_bid_seq = tmp.resource_bid_seq
          AND pb.scheduling_coordinator_seq = tmp.scheduling_coordinator_seq
    )
);


-- SELECT hour_beginning, resource_bid_seq, product_bid_mrid FROM tmp;