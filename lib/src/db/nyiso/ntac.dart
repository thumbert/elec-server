/// To get the data, go to nyiso page,
/// click on Markets > Reports & Info > General Information > External Transaction TSC- Summary & Details
/// takes you to http://mis.nyiso.com/public/P-62list.htm
///
/// Data is published for one month ahead, usually on the 15th of the
/// previous month

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_nyiso_reports.dart';
import 'package:mongo_dart/mongo_dart.dart' hide Month;
import 'package:elec_server/src/db/config.dart';
import 'package:tuple/tuple.dart';

class NyisoNtacReportArchive extends DailyNysioCsvReport {
  NyisoNtacReportArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'nyiso', collectionName: 'ancillaries');
    this.dbConfig = dbConfig;
    dir ??= '${super.dir}Ntac/Raw/';
    this.dir = dir;
    reportName = 'TSC Rates and NTAC Report';
  }

  Db get db => dbConfig.db;

  /// Data usually available on the 15th of the month for next month
  @override
  String getUrl(Date asOfDate) =>
      'http://mis.nyiso.com/public/TSCCalc/tsc_ntac_${yyyymmdd(asOfDate)}.pdf';

  @override
  File getCsvFile(Date asOfDate) =>
      File('$dir${yyyymmdd(asOfDate)}DAMLimitingConstraints.csv');

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    return <String, dynamic>{};
  }

  /// Input [file] is the daily CSV file,
  ///
  /// Return a list with each element of this form, ready for insertion
  /// into the Db.
  /// ```
  /// {
  ///   'date': '2020-01-01',
  ///   'market': 'DA',
  ///   'limitingFacility': 'CENTRAL EAST-VC',
  ///   'hours': [
  ///      {
  ///        'hourBeginning': TZDateTime.utc(...),
  ///        'Contingency': 'BASE CASE',
  ///        'Constraint Cost($)': 20.26,
  ///      },
  ///      ...
  ///   ],
  /// }
  /// ```
  @override
  List<Map<String, dynamic>> processFile(File file) {
    var out = <Map<String, dynamic>>[];

    var xs = readReport(getReportDate(file));
    if (xs.isEmpty) return out;

    var date = Date.fromTZDateTime(NyisoReport.parseTimestamp(
            xs.first['Time Stamp'], xs.first['Time Zone']))
        .toString();
    var groups =
        groupBy(xs, (Map e) => (e['Limiting Facility'] as String).trim());

    for (var group in groups.entries) {
      var _hours = group.value
          .map((e) => {
                'hourBeginning':
                    NyisoReport.parseTimestamp(e['Time Stamp'], e['Time Zone']),
                'contingency': (e['Contingency'] as String).trim(),
                'cost': e['Constraint Cost(\$)'],
              })
          .toList();
      // Rarely, the entries are not time-sorted correctly
      // see for example 2019-12-15 for 'E13THSTA 345 FARRAGUT 345 1'
      // because there are different contingencies for this limitingFacility
      // so I will sort them here before storing
      _hours.sort((a, b) => a['hourBeginning'].compareTo(b['hourBeginning']));
      out.add({
        'date': date,
        'market': 'DA',
        'limitingFacility': group.key,
        'hours': _hours,
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
    var groups = groupBy(data, (Map e) => Tuple2(e['market'], e['date']));
    try {
      for (var t2 in groups.keys) {
        await dbConfig.coll.remove({'market': t2.item1, 'date': t2.item2});
        await dbConfig.coll.insertAll(groups[t2]!);
        print(
            '--->  Inserted ${t2.item1} binding constraints for day ${t2.item2}');
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
        .createIndex(dbConfig.collectionName, keys: {'market': 1, 'date': 1});
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
      'http://mis.nyiso.com/public/csv/DAMLimitingConstraints/${month.startDate.toString().replaceAll('-', '')}DAMLimitingConstraints_csv.zip';

  @override
  File getZipFileForMonth(Month month) {
    return File('$dir${month.startDate.toString().replaceAll('-', '')}DAMLimitingConstraints.csv.zip');
  }
}
