
SELECT * from ssc LIMIT 3;

-- What months are in the table
-- SELECT DISTINCT DATE_TRUNC('month', LocalTime) as month
SELECT DISTINCT strftime(LocalTime, '%Y-%m') as month
FROM ssc
ORDER BY month;

SELECT min(LocalTime) as min_date, max(LocalTime) as max_date
FROM ssc; 


SELECT InterfaceName, LocalTime, ActualMargin
FROM ssc
WHERE LocalTime >= '2025-01-10 00:00:00'
AND LocalTime < '2025-01-11'
AND InterfaceName = 'PJM West';


---=======================================================================

CREATE TABLE IF NOT EXISTS ssc (
    begin_date TIMESTAMPTZ NOT NULL,
    rt_flow_mw DOUBLE NOT NULL,
    lowest_limit_mw DOUBLE NOT NULL,
    distribution_factor DOUBLE NOT NULL,
    interface_name VARCHAR NOT NULL,
    actual_margin_mw DOUBLE NOT NULL,
    authorized_margin_mw DOUBLE NOT NULL,
    base_limit_mw DOUBLE NOT NULL,
    single_source_contingency_limit_mw DOUBLE NOT NULL
);

CREATE TEMPORARY TABLE IF NOT EXISTS tmp AS
    SELECT 
        make_timestamptz(epoch_us(BeginDate)) as begin_date,
        RtFlowMw::DOUBLE as rt_flow_mw,
        LowestLimitMw::DOUBLE as lowest_limit_mw,
        DistributionFactor::DOUBLE as distribution_factor,
        InterfaceName::VARCHAR as interface_name,
        ActMarginMw::DOUBLE as actual_margin_mw,
        AuthorizedMarginMw::DOUBLE as authorized_margin_mw,
        BaseLimitMw::DOUBLE as base_limit_mw,
        SingleSrcContingencyMw::DOUBLE as single_source_contingency_limit_mw
    FROM (
        SELECT unnest(SingleSrcContingencyLimits.SingleSrcContingencyLimit, recursive := true)
        FROM read_json('~/Downloads/Archive/IsoExpress/SingleSourceContingency/Raw/2025/ssc_2025-01-01.json.gz')
    )
;

INSERT INTO ssc BY NAME
(
    SELECT * FROM tmp t
    WHERE NOT EXISTS (
        SELECT * FROM ssc s
        WHERE s.begin_date = t.begin_date
        AND s.interface_name = t.interface_name
    )
);






