

SELECT * FROM morning_report LIMIT 1;

SELECT MIN(MarketDate), MAX(MarketDate) FROM morning_report;

SELECT MarketDate, TieFlowNececMw
FROM morning_report
ORDER BY MarketDate;

-- Look at days when 
SELECT ReportType, MarketDate, GenPlannedOutagesReductionMw, GenForcedOutagesReductionMw, GenOutagesReductionMw
FROM morning_report
WHERE MarketDate >= '2025-07-01'
AND ReportType = 'Morning Report'
ORDER BY MarketDate;


-- Look at the days when the Excess Commitment Surplus/Deficiency was the lowest
SELECT MarketDate, ExcessCommitMw
FROM morning_report
WHERE ReportType = 'Final'
ORDER BY ExcessCommitMw ASC
LIMIT 30;



SELECT MarketDate, ReportType, ExcessCommitMw
FROM morning_report
WHERE MarketDate > '2024-06-01';


SELECT MarketDate, ReportType, TieFlowHighgateMw
FROM morning_report;


---==================================================================================================================
CREATE TABLE IF NOT EXISTS morning_report (
  ReportType VARCHAR,
  MarketDate DATE,
  CreationDateTime DATETIME,
  PeakLoadYesterdayHour DATETIME,
  PeakLoadYesterdayMw FLOAT,
  CsoMw FLOAT,
  CapAdditionsMw FLOAT,
  GenOutagesReductionMw FLOAT,
  UncommittedAvailGenMw FLOAT,
  DrrCapacityMw FLOAT,
  UncommittedAvailableDrrGenMw FLOAT,
  NetCapacityDeliveryMw FLOAT,
  TotalAvailableCapacityMw FLOAT,
  PeakLoadTodayHour DATETIME,
  PeakLoadTodayMw FLOAT,
  TotalOperatingReserveRequirementsMw FLOAT,
  CapacityRequiredMw FLOAT,
  SurplusDeficiencyMw FLOAT,
  ReplacementReserveRequirementMw FLOAT,
  ExcessCommitMw FLOAT,
  LargestFirstContingencyMw FLOAT,
  AmsPeakLoadExpMw FLOAT,
  IsNyisoSarAvailable BOOL,
  TenMinReserveReqMw FLOAT,
  TenMinReserveEstMw FLOAT,
  ThirtyMinReserveReqMw FLOAT,
  ThirtyMinReserveEstMw FLOAT,
  ExpectedActOp4Mw FLOAT,
  AddlCapAvailOp4ActMw FLOAT,
  ImportLimitInHighgateMw FLOAT,
  ExportLimitOutHighgateMw FLOAT,
  ScheduledHighgateMw FLOAT,
  TieFlowHighgateMw FLOAT,
  ImportLimitInNbMw FLOAT,
  ExportLimitOutNbMw FLOAT,
  ScheduledNbMw FLOAT,
  TieFlowNbMw FLOAT,
  ImportLimitInNyisoAcMw FLOAT,
  ExportLimitOutNyisoAcMw FLOAT,
  ScheduledNyisoAcMw FLOAT,
  TieFlowNyisoAcMw FLOAT,
  ImportLimitInNyisoCscMw FLOAT,
  ExportLimitOutNyisoCscMw FLOAT,
  ScheduledNyisoCscMw FLOAT,
  TieFlowNyisoCscMw FLOAT,
  ImportLimitInNyisoNncMw FLOAT,
  ExportLimitOutNyisoNncMw FLOAT,
  ScheduledNyisoNncMw FLOAT,
  TieFlowNyisoNncMw FLOAT,
  ImportLimitInPhase2Mw FLOAT,
  ExportLimitOutPhase2Mw FLOAT,
  ScheduledPhase2Mw FLOAT,
  TieFlowPhase2Mw FLOAT,
  ImportLimitInNececMw FLOAT,
  ExportLimitOutNececMw FLOAT,
  ScheduledNececMw FLOAT,
  TieFlowNececMw FLOAT,
  HighTemperatureBoston FLOAT,
  WeatherConditionsBoston VARCHAR,
  WindDirSpeedBoston VARCHAR,
  HighTemperatureHartford FLOAT,
  WeatherConditionsHartford VARCHAR,
  WindDirSpeedHartford VARCHAR,
  NonCommUnitsCapMw FLOAT,
  UnitsCommMinOrrCount UTINYINT,
  UnitsCommMinOrrMw FLOAT,
  GeoMagDistIsoAction VARCHAR,
  GeoMagDistOtherCentralAction VARCHAR,
  GeoMagDistIntensity VARCHAR,
  GeoMagDistObsActivity VARCHAR,
);

CREATE TEMPORARY TABLE tmp AS (
    SELECT *
    FROM read_csv(
    '~/Downloads/Archive/IsoExpress/MorningReport/month/morning_report_2020-01.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z')
);

INSERT INTO morning_report BY NAME
FROM tmp
EXCEPT
SELECT * FROM morning_report;

