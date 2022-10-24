library db.nyiso.rt_zonal_load_hourly;

/// Data from http://mis.nyiso.com/public/P-58Clist.htm

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_nyiso_reports.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:elec_server/src/db/config.dart';
import 'package:tuple/tuple.dart';

class NyisoHourlyRtZonalLoadReportArchive extends DailyNysioCsvReport {
  NyisoHourlyRtZonalLoadReportArchive(
      {ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'nyiso', collectionName: 'rtload_zonal_ts');
    this.dbConfig = dbConfig;
    dir ??= '${super.dir}HourlyRtZonalLoad/Raw/';
    this.dir = dir;
    reportName = 'NYISO RT Hourly Zonal Load Report';
  }

  Db get db => dbConfig.db;

  /// For one day only, available for the latest 10 days
  /// Entire month is available at
  /// http://mis.nyiso.com/public/csv/palIntegrated/20221001palIntegrated_csv.zip
  @override
  String getUrl(Date asOfDate) =>
      'http://mis.nyiso.com/public/csv/palIntegrated/${yyyymmdd(asOfDate)}palIntegrated.csv';

  @override
  File getCsvFile(Date asOfDate) =>
      File('$dir${yyyymmdd(asOfDate)}palIntegrated.csv');

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    return <String, dynamic>{};
  }

  /// Input [file] is the daily CSV file,
  ///
  /// Return a list with each element of this form, ready for insertion.
  /// ```
  /// {
  ///   'date': '2020-01-01'
  ///   'ptid': 61757,
  ///   'mw': [1115.4148, ...],  // 24 values
  /// }
  /// ```
  @override
  List<Map<String, dynamic>> processFile(File file) {
    var out = <Map<String, dynamic>>[];

    var date = getReportDate(file);
    var xs = readReport(date);
    if (xs.isEmpty) return out;


    var grp = groupBy(xs, (Map e) => e['PTID'] as int);

    for (var ptid in grp.keys) {
      out.add({
        'date': date.toString(),
        'ptid': ptid,
        'mw': grp[ptid]!.map((e) => e['Integrated Load']).toList(),
      });
    }

    // out = xs
    //     .map((e) => {
    //           'metadata': {'ptid': e['PTID'] as int},
    //           'timestamp': NyisoReport.parseTimestamp(
    //                   xs.first['Time Stamp'], xs.first['Time Zone'])
    //               .toUtc(),
    //           'mw': e['Integrated Load'] as num,
    //         })
    //     .toList();

    return out;
  }

  /// Insert data into db.  You can pass in several days at once.
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data');
      return Future.value(-1);
    }

    await dbConfig.coll.insertAll(data);

    return 0;
    // var groups = groupBy(data, (Map e) => Tuple2(e['market'], e['date']));
    // try {
    //   for (var t2 in groups.keys) {
    //     await dbConfig.coll.remove({'market': t2.item1, 'date': t2.item2});
    //     await dbConfig.coll.insertAll(groups[t2]!);
    //     print(
    //         '--->  Inserted ${t2.item1} binding constraints for day ${t2.item2}');
    //   }
    //   return 0;
    // } catch (e) {
    //   print('xxxx ERROR xxxx $e');
    //   return 1;
    // }
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    // await dbConfig.db.createCollection('rtload_zonal_ts', rawOptions: {
    //   'timeseries': {
    //     'timeField': 'timestamp',
    //     'metaField': 'metadata',
    //     'granularity': 'hours',
    //   }
    // });
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'date': 1, 'ptid': 1});
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
  String getUrlForMonth(Month month) =>
      'http://mis.nyiso.com/public/csv/palIntegrated/${month.startDate.toString().replaceAll('-', '')}palIntegrated_csv.zip';

  @override
  File getZipFileForMonth(Month month) {
    return File(
        '$dir${month.startDate.toString().replaceAll('-', '')}palIntegrated.csv.zip');
  }
}
