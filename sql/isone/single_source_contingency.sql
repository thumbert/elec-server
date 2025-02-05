

CREATE TABLE ssc (
    InterfaceName VARCHAR,
    LocalTime DATETIME,
    ActualMargin FLOAT,
    AuthorizedMargin FLOAT,
    BaseLimit FLOAT,
    SingleSourceContingency FLOAT,
    LowestLimit FLOAT,
    Phase2RtFlow FLOAT,
);

DROP TABLE tmp;

-- Wow!  This is slick! 
CREATE TEMPORARY TABLE tmp
AS
    SELECT unnest(SingleSrcContingencyLimits.SingleSrcContingencyLimit, recursive := true)
    FROM read_json('~/Downloads/Archive/IsoExpress/SingleSourceContingency/Raw/2025/ssc_2025-01-10.json.gz')
;
SELECT * from tmp;




DESCRIBE TABLE tmp;

SELECT tmp.* 
FROM tmp;


SELECT a.* FROM (SELECT {'x':1, 'y':2, 'z':3} as a);


CREATE TEMPORARY TABLE limits
AS 
SELECT tmp.SingleSrcContingencyLimits FROM tmp
;




 
CREATE TEMPORARY TABLE tmp
AS
    SELECT InterfaceName, LocalTime, ActualMargin, AuthorizedMargin, BaseLimit, 
        SingleSourceContingency, LowestLimit, Phase2RtFlow  
    FROM read_csv(
        '~/Downloads/Archive/IsoExpress/SingleSourceContingency/Raw/ssc_20250110.csv', 
        header = true, 
        timestampformat = '%m/%d/%Y %H:%M:%S', 
        skip = 6,
        ignore_errors = true,
        columns = {
            'H': 'VARCHAR',
            'InterfaceName': 'VARCHAR',
            'LocalTime': 'DATETIME',
            'ActualMargin': 'FLOAT',
            'AuthorizedMargin': 'FLOAT',
            'BaseLimit': 'FLOAT',
            'SingleSourceContingency': 'FLOAT',
            'LowestLimit': 'FLOAT',
            'Phase2RtFlow': 'FLOAT',
        } 
    );

-- need to delete the data if it already exists for the day
DELETE FROM ssc
WHERE LocalTime >= '2025-01-10'
AND LocalTime < '2025-01-11';

-- 
INSERT INTO ssc
SELECT * FROM tmp
ORDER BY LocalTime;


SELECT * FROM ssc LIMIT 5;


