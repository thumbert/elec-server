library db.nyiso.da_lmp_hourly;

/// Data from http://mis.nyiso.com/public/

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/src/db/lib_nyiso_reports.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:elec_server/src/db/config.dart';

class NyisoDaLmpHourlyArchive extends DailyNysioCsvReport {
  NyisoDaLmpHourlyArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'nyiso', collectionName: 'da_lmp_hourly');
    this.dbConfig = dbConfig;
    dir ??= super.dir + 'DaLmpHourly/Raw/';
    this.dir = dir;
    reportName = 'Day-Ahead Hourly LMP';
  }

  Db get db => dbConfig.db;
  late NodeType nodeType;

  /// Data available for the most 10 recent days only at this url.
  /// http://mis.nyiso.com/public/csv/damlbmp/20220113damlbmp_zone.csv
  /// Entire month is at
  /// http://mis.nyiso.com/public/csv/damlbmp/20211201damlbmp_zone_csv.zip
  /// http://mis.nyiso.com/public/csv/damlbmp/20211201damlbmp_gen_csv.zip
  @override
  String getUrl(Date asOfDate) =>
      'http://mis.nyiso.com/public/csv/damlbmp/' +
      yyyymmdd(asOfDate) +
      'damlbmp_${nodeType.toString()}.csv';

  @override
  File getCsvFile(Date asOfDate) =>
      File(dir + yyyymmdd(asOfDate) + 'damlbmp_${nodeType.toString()}.csv');

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    return <String, dynamic>{};
  }

  /// Return a list with each element of this form, ready for insertion
  /// into the Db.
  /// ```
  /// {
  ///   'date': '2020-01-01',
  ///   'ptid': 61757,
  ///   'congestion': <num>[...],
  ///   'lmp': <num>[...],
  ///   'losses': <num>[...],
  /// }
  /// ```
  List<Map<String, dynamic>> processDay(Date date) {
    var out = <Map<String, dynamic>>[];

    /// Get the both the zones and the gen nodes at once
    var nodeTypes = [NodeType.zone, NodeType.gen];
    for (var _nodeType in nodeTypes) {
      nodeType = _nodeType;
      var xs = readReport(date);
      if (xs.isEmpty) return out;
      var _date = parseMmddyyy(xs.first['Time Stamp']);

      // takes care of DST dates automatically as each day will contain 23, 24, 25
      // hours as needed for each ptid
      var groups = groupBy(xs, (Map e) => e['PTID'] as int);
      for (var group in groups.entries) {
        out.add({
          'date': _date.toString(),
          'ptid': group.key,
          'lmp': group.value.map((e) => e['LBMP (\$/MWHr)']).toList(),
          'congestion': group.value
              .map((e) => e['Marginal Cost Congestion (\$/MWHr)'])
              .toList(),
          'losses': group.value
              .map((e) => e['Marginal Cost Losses (\$/MWHr)'])
              .toList(),
        });
      }
    }

    return out;
  }

  /// Insert data into db.  You can pass in several days at once.
  /// Note: Input [data] needs to contain both the zone and the gen data
  /// because data is inserted by date.
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data');
      return Future.value(-1);
    }
    var groups = groupBy(data, (Map e) => e['date']);
    try {
      for (var date in groups.keys) {
        await dbConfig.coll.remove({'date': date});
        await dbConfig.coll.insertAll(groups[date]!);
        print('--->  Inserted NYISO DAM LMPs for day $date');
      }
      return 0;
    } catch (e) {
      print('xxxx ERROR xxxx ' + e.toString());
      return 1;
    }
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'ptid': 1,
          'date': 1,
        },
        unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'date': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'ptid': 1});
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
  List<Map<String, dynamic>> processFile(File file) {
    /// use processDay()
    throw UnimplementedError();
  }

  @override
  String getUrlForMonth(Month month) =>
      'http://mis.nyiso.com/public/csv/damlbmp/' +
      month.startDate.toString().replaceAll('-', '') +
      'damlbmp_${nodeType.toString()}_csv.zip';

  @override
  File getZipFileForMonth(Month month) {
    return File(dir +
        month.startDate.toString().replaceAll('-', '') +
        'damlbmp_${nodeType.toString()}.csv.zip');
  }
}
