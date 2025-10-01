library db.isoexpress.morning_report;

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/client/isoexpress/morning_report.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

/// ISO-NE rolled out improvements to the Morning Report, including a “next day”
/// operational capacity report.  Starting December 19, 2024 for the December 20
/// operating day, ISO-NE began posting three “Morning Reports” for an
/// operating day: by 4pm on the day before and by 8 am and noon of the
/// operating day.
class IsoneMorningReportArchive {
  IsoneMorningReportArchive({required this.dir, required this.duckdbPath});

  final String dir;
  final String duckdbPath;
  static final log = Logger('Morning report');

  File getFilename(Date asOfDate) {
    return File("$dir/Raw/${asOfDate.year}/morning_report_$asOfDate.json");
  }

  String getUrl(Date asOfDate) =>
      "https://webservices.iso-ne.com/api/v1.1/morningreport/day/${yyyymmdd(asOfDate)}/all";

  /// ISO has not published data for these days
  static final missingDays = <Date>{};

  List<MorningReport> processFile(File file) {
    if (extension(file.path) != '.json') {
      throw ArgumentError('File needs to be a json file');
    }
    var str = file.readAsStringSync();
    var res = json.decode(str);
    // a day may not have a report yet, if too early
    if (res['MorningReports'] == '') return <MorningReport>[];
    if ((res['MorningReports'] as Map).isEmpty) return <MorningReport>[];
    var xs = res['MorningReports']['MorningReport'] as List;
    return xs.map((x) => MorningReport.fromJson(x)).toList();
  }

  /// File is in the long format, ready for duckdb to upload
  ///
  int makeGzFileForMonth(Month month) {
    assert(month.location == IsoNewEngland.location);
    var today = Date.today(location: IsoNewEngland.location);
    var days = month.days();
    var xs = <MorningReport>[];
    for (var day in days) {
      // each file usually contains 2 reports (Final and Preliminary)
      if (day.isAfter(today)) continue;
      if (missingDays.contains(day)) continue;
      var file = getFilename(day);
      xs.addAll(processFile(file));
      print('Processed day $day');
    }

    final converter = ListToCsvConverter();
    var sb = StringBuffer();
    sb.writeln(MorningReport.colnames.join(','));
    for (var x in xs) {
      var values = x.toJson().values.toList();
      assert(values.length == MorningReport.colnames.length);
      sb.writeln(converter.convert([values], convertNullTo: ''));
    }
    final file =
        File('$dir/month/morning_report_${month.toIso8601String()}.csv');
    file.writeAsStringSync(sb.toString());

    // gzip it!
    var res = Process.runSync('gzip', ['-f', file.path], workingDirectory: dir);
    if (res.exitCode != 0) {
      throw StateError('Gzipping ${basename(file.path)} has failed');
    }
    log.info('Gzipped file ${basename(file.path)}');

    return 0;
  }

  int updateDuckDb(Month month) {
    final con = Connection(duckdbPath);
    con.execute('''
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
''');
    con.execute('''
CREATE TEMPORARY TABLE tmp AS (
    SELECT *
    FROM read_csv(
    '$dir/month/morning_report_${month.toIso8601String()}.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z')
);
''');
    con.execute('''
INSERT INTO morning_report BY NAME
FROM tmp
EXCEPT
SELECT * FROM morning_report;
''');
    con.close();

    return 0;
  }
}
