library db.nyiso.btm_solar_actual_mw;

/// http://mis.nyiso.com/public/P-70Alist.htm

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:elec/elec.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_nyiso_reports.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:elec_server/src/db/config.dart';
import 'package:tuple/tuple.dart';

class NyisoBtmSolarActualArchive extends DailyNysioCsvReport {
  /// Data is available only from 2020-11-17 forward.
  /// Occasionally, there are missing days for example the last 5 days of 2021
  /// are missing.
  NyisoBtmSolarActualArchive(
      {ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'nyiso', collectionName: 'btm_solar_mw');
    this.dbConfig = dbConfig;
    dir ??= '${super.dir}BtmSolarActualMw/Raw/';
    this.dir = dir;
    reportName = 'NYISO BTM Solar actual MW Report';
  }

  Db get db => dbConfig.db;


  /// For one day only, available for the latest 10 days
  /// Entire month is available at
  /// http://mis.nyiso.com/public/csv/btmactualforecast/20221001BTMEstimatedActual_csv.zip
  @override
  String getUrl(Date asOfDate) =>
      'http://mis.nyiso.com/public/csv/btmactualforecast/${yyyymmdd(asOfDate)}BTMEstimatedActual.csv';

  @override
  File getCsvFile(Date asOfDate) =>
      File('$dir${yyyymmdd(asOfDate)}BTMEstimatedActual.csv');

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    return <String, dynamic>{};
  }

  /// Input [file] is the daily CSV file,
  /// Encode the system value with ptid = -1.
  /// Return a list with each element of this form, ready for insertion.
  /// ```
  /// {
  ///   'type': 'estimatedActual',
  ///   'date': '2020-11-17'
  ///   'ptid': 61757,
  ///   'mw': [0, 0, ...],  // 24 hourly values
  /// }
  /// ```
  @override
  List<Map<String, dynamic>> processFile(File file) {
    var out = <Map<String, dynamic>>[];

    var nameToPtid = NewYorkIso().loadZoneNameToPtid;
    var date = getReportDate(file);
    var xs = readReport(date);
    if (xs.isEmpty) return out;

    var grp = groupBy(xs, (Map e) => e['Zone Name'] as String);

    for (var zoneName in grp.keys) {
      int ptid;
      if (nameToPtid.containsKey(zoneName)) {
        ptid = nameToPtid[zoneName]!;
      } else if (zoneName == 'SYSTEM') {
        ptid = -1;
      } else {
        throw StateError('Unknown NYISO zone name $zoneName');
      }
      out.add({
        'type': 'estimatedActual',
        'date': date.toString(),
        'ptid': ptid,
        'mw': grp[zoneName]!.map((e) => e['MW Value']).toList(),
      });
    }

    return out;
  }

  /// Insert data into db.  You can pass in several days at once.
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data');
      return Future.value(-1);
    }

    var groups = groupBy(data, (Map e) => Tuple2(e['type'], e['date']));
    try {
      for (var t2 in groups.keys) {
        await dbConfig.coll.remove({'type': t2.item1, 'date': t2.item2});
        await dbConfig.coll.insertAll(groups[t2]!);
        print(
            '--->  Inserted ${t2.item1} NYISO BTM solar MW for day ${t2.item2}');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx $e');
      return 1;
    }
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'type': 1, 'date': 1, 'ptid': 1});
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

  /// http://mis.nyiso.com/public/csv/btmactualforecast/20221001BTMEstimatedActual_csv.zip
  @override
  String getUrlForMonth(Month month) =>
      'http://mis.nyiso.com/public/csv/btmactualforecast/${month.startDate.toString().replaceAll('-', '')}BTMEstimatedActual_csv.zip';

  @override
  File getZipFileForMonth(Month month) {
    return File(
        '$dir${month.startDate.toString().replaceAll('-', '')}BTMEstimatedActual.csv.zip');
  }
}
