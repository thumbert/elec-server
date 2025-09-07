
---===================================================================================
CREATE TABLE IF NOT EXISTS rt_gen (
    date DATE NOT NULL,
    generator_name VARCHAR NOT NULL,
    fuel_type VARCHAR NOT NULL,
    measurement ENUM('Capability', 'Output', 'Forecast', 'Available Capacity')
    mw_0 UINT16 NOT NULL,
    mw_1 UINT16 NOT NULL,
    mw_2 UINT16 NOT NULL,
    mw_3 UINT16 NOT NULL,
    mw_4 UINT16 NOT NULL,
    mw_5 UINT16 NOT NULL,
    mw_6 UINT16 NOT NULL,
    mw_7 UINT16 NOT NULL,
    mw_8 UINT16 NOT NULL,
    mw_9 UINT16 NOT NULL,
    mw_10 UINT16 NOT NULL,
    mw_11 UINT16 NOT NULL,
    mw_12 UINT16 NOT NULL,
    mw_13 UINT16 NOT NULL,
    mw_14 UINT16 NOT NULL,
    mw_15 UINT16 NOT NULL,
    mw_16 UINT16 NOT NULL,
    mw_17 UINT16 NOT NULL,
    mw_18 UINT16 NOT NULL,
    mw_19 UINT16 NOT NULL,
    mw_20 UINT16 NOT NULL,
    mw_21 UINT16 NOT NULL,
    mw_22 UINT16 NOT NULL,
    mw_23 UINT16 NOT NULL,
);


--- the file has an extra column full with nulls.  A pain in the fanny!
CREATE TEMPORARY TABLE tmp
AS
    SELECT 
      column00::DATE as "date",
      column01::VARCHAR as generator_name,
      column02::VARCHAR as fuel_type,
      column03::ENUM('Capability', 'Output', 'Forecast', 'Available Capacity') as measurement,
      COALESCE(TRY_CAST(column04 AS UINT16), 0) as mw_0,
      COALESCE(TRY_CAST(column05 AS UINT16), 0) as mw_1,
      COALESCE(TRY_CAST(column06 AS UINT16), 0) as mw_2,
      COALESCE(TRY_CAST(column07 AS UINT16), 0) as mw_3,
      COALESCE(TRY_CAST(column08 AS UINT16), 0) as mw_4,
      COALESCE(TRY_CAST(column09 AS UINT16), 0) as mw_5,
      COALESCE(TRY_CAST(column10 AS UINT16), 0) as mw_6,
      COALESCE(TRY_CAST(column11 AS UINT16), 0) as mw_7,
      COALESCE(TRY_CAST(column12 AS UINT16), 0) as mw_8,
      COALESCE(TRY_CAST(column13 AS UINT16), 0) as mw_9,
      COALESCE(TRY_CAST(column14 AS UINT16), 0) as mw_10,
      COALESCE(TRY_CAST(column15 AS UINT16), 0) as mw_11,
      COALESCE(TRY_CAST(column16 AS UINT16), 0) as mw_12,
      COALESCE(TRY_CAST(column17 AS UINT16), 0) as mw_13,
      COALESCE(TRY_CAST(column18 AS UINT16), 0) as mw_14,
      COALESCE(TRY_CAST(column19 AS UINT16), 0) as mw_15,
      COALESCE(TRY_CAST(column20 AS UINT16), 0) as mw_16,
      COALESCE(TRY_CAST(column21 AS UINT16), 0) as mw_17,
      COALESCE(TRY_CAST(column22 AS UINT16), 0) as mw_18,
      COALESCE(TRY_CAST(column23 AS UINT16), 0) as mw_19,
      COALESCE(TRY_CAST(column24 AS UINT16), 0) as mw_20,
      COALESCE(TRY_CAST(column25 AS UINT16), 0) as mw_21,
      COALESCE(TRY_CAST(column26 AS UINT16), 0) as mw_22,
      COALESCE(TRY_CAST(column27 AS UINT16), 0) as mw_23,
    FROM (
        SELECT *
        FROM read_csv('/home/adrian/Downloads/Archive/Ieso/RtGeneration/Raw/PUB_GenOutputCapabilityMonth_202508.csv',
        skip = 4)
    );
;
