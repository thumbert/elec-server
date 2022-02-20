library db.nyiso.da_energy_offer;

/// All data from ...
/// http://mis.nyiso.com/public/P-27list.htm
///

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:elec_server/src/db/lib_nyiso_report.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:timezone/timezone.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';

class NyisoDaEnergyOfferArchive extends DailyNysioCsvReport {
  static final List<String> _unitStates = [
    'UNAVAILABLE',
    'MUST_RUN',
    'ECONOMIC'
  ];

  NyisoDaEnergyOfferArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'nyiso', collectionName: 'da_energy_offer');
    this.dbConfig = dbConfig;
    dir ??= super.dir + 'DaEnergyOffer/Raw/';
    this.dir = dir;
    reportName = 'Day-Ahead Energy Market Historical Offer Report';
  }

  mongo.Db get db => dbConfig.db;


  /// [rows] has the data for all the hours of the day for one asset
  @override
  Map<String, dynamic> converter(List<Map> rows) {
    var row = <String, dynamic>{};

    // /// daily info
    // row['date'] = formatDate(rows.first['Day']);
    // row['Masked Lead Participant ID'] =
    //     rows.first['Masked Lead Participant ID'];
    // row['Masked Asset ID'] = rows.first['Masked Asset ID'];
    // row['Must Take Energy'] = rows.first['Must Take Energy'];
    // row['Maximum Daily Energy Available'] =
    //     rows.first['Maximum Daily Energy Available'];
    // row['Unit Status'] = rows.first['Unit Status'];
    // row['Claim 10'] = rows.first['Claim 10'];
    // row['Claim 30'] = rows.first['Claim 30'];
    //
    // /// hourly info
    // row['hours'] = [];
    // for (var hour in rows) {
    //   var aux = <String, dynamic>{};
    //   var utc = parseHourEndingStamp(hour['Day'], hour['Trading Interval']);
    //   aux['hourBeginning'] = TZDateTime.fromMicrosecondsSinceEpoch(
    //           location, utc.microsecondsSinceEpoch)
    //       .toIso8601String();
    //   aux['Economic Maximum'] = hour['Economic Maximum'];
    //   aux['Economic Minimum'] = hour['Economic Minimum'];
    //   aux['Cold Startup Price'] = hour['Cold Startup Price'];
    //   aux['Intermediate Startup Price'] = hour['Intermediate Startup Price'];
    //   aux['Hot Startup Price'] = hour['Hot Startup Price'];
    //   aux['No Load Price'] = hour['No Load Price'];
    //
    //   /// add the non empty price/quantity pairs
    //   var pricesHour = <num?>[];
    //   var quantitiesHour = <num?>[];
    //   for (var i = 1; i <= 10; i++) {
    //     if (hour['Segment $i Price'] is! num) break;
    //     pricesHour.add(hour['Segment $i Price']);
    //     quantitiesHour.add(hour['Segment $i MW']);
    //   }
    //   aux['price'] = pricesHour;
    //   aux['quantity'] = quantitiesHour;
    //   row['hours'].add(aux);
    // }
    // validateDocument(row);
    return row;
  }

  /// Insert data into db.
  @override
  Future insertData(List<Map<String, dynamic>> data) async {
    /// TODO: Make sure you overwrite the same (day,asset)
    return dbConfig.coll
        .insertAll(data)
        .then((_) => print('--->  Inserted successfully'))
        .catchError((e) => print('   ' + e.toString()));
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var out = <Map<String, dynamic>>[];

    var reportDate = getReportDate(file);
    var xs = readReport(getReportDate(file));
    if (xs.isEmpty) return out;

    var date = Date.fromTZDateTime(NyisoReport.parseTimestamp(
        xs.first['Time Stamp'], xs.first['Time Zone']))
        .toString();
    var groups =
    groupBy(xs, (Map e) => (e['Limiting Facility'] as String).trim());


    return out;
  }

  /// Recreate the collection from scratch.
  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'date': 1,
          'Masked Asset ID': 1,
          'Masked Lead Participant ID': 1,
        },
        unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'date': 1});
    await dbConfig.db.close();
  }

  @override
  Date getReportDate(File file) {
    var yyyymmdd = basename(file.path).substring(0, 8);
    return Date.utc(
        int.parse(yyyymmdd.substring(0, 4)),
        int.parse(yyyymmdd.substring(4, 6)),
        int.parse(yyyymmdd.substring(6, 8)));
  }

  @override
  File getZipFileForMonth(Month month) =>
      File(dir + yyyymmdd(month.startDate) + 'biddata_genbids_csv.zip');

  ///http://mis.nyiso.com/public/csv/biddata/20211001biddata_genbids_csv.zip
  @override
  String getUrlForMonth(Month month) =>
    'http://mis.nyiso.com/public/csv/biddata/' +
        yyyymmdd(month.startDate) +
        'biddata_genbids_csv.zip';

  @override
  File getCsvFile(Date asOfDate) {
    var month = Month.utc(asOfDate.year, asOfDate.month);
    var fileName = getZipFileForMonth(month).path;
    fileName = fileName.replaceAll('_csv.zip', '.csv');
    return File(fileName);
  }

  @override
  String getUrl(Date asOfDate) {
    throw StateError('Individual day url does not exist for this report');
  }
  
}


// /// Check if this document is OK.  Throws otherwise.  May not catch all
// /// issues.
// void validateDocument(Map row) {
//   if (row.containsKey('Unit Status') &&
//       !_unitStates.contains(row['Unit Status'])) {
//     throw StateError('Invalid unit state: ${row['Unit State']}.');
//   }
// }
