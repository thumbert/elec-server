
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


CREATE TABLE IF NOT EXISTS ssc (
        BeginDate TIMESTAMPTZ NOT NULL,
        RtFlowMw DOUBLE NOT NULL,
        LowestLimitMw DOUBLE NOT NULL,
        DistributionFactor DOUBLE NOT NULL,
        InterfaceName VARCHAR NOT NULL,
        ActualMarginMw DOUBLE NOT NULL,
        AuthorizedMarginMw DOUBLE NOT NULL,
        BaseLimitMw DOUBLE NOT NULL,
        SingleSourceContingencyLimitMw DOUBLE NOT NULL,
);


CREATE TEMPORARY TABLE tmp AS
    SELECT unnest(SingleSrcContingencyLimits.SingleSrcContingencyLimit, recursive := true)
    FROM read_json('~/Downloads/Archive/IsoExpress/SingleSourceContingency/Raw/2025/ssc_2025-*.json.gz')
;
SELECT * from tmp;


INSERT INTO ssc
    SELECT 
        BeginDate::TIMESTAMPTZ as LocalTime,
        RtFlowMw::DOUBLE,
        LowestLimitMw::DOUBLE,
        DistributionFactor::DOUBLE,
        InterfaceName::VARCHAR,
        ActMarginMw::DOUBLE as ActualMarginMw,
        AuthorizedMarginMw::DOUBLE,
        BaseLimitMw::DOUBLE,
        SingleSrcContingencyMw::DOUBLE as SingleSourceContingencyLimitMw,
    FROM tmp
EXCEPT 
    SELECT * FROM ssc;        









-- need to delete the data if it already exists for the day
DELETE FROM ssc
WHERE LocalTime >= '2025-01-10'
AND LocalTime < '2025-01-11';

-- 
INSERT INTO ssc
SELECT * FROM tmp
ORDER BY LocalTime;


SELECT * FROM ssc LIMIT 5;


