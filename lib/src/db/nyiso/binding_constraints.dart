library db.nyiso.binding_constraints;

/// Data from http://mis.nyiso.com/public/

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_nyiso_report.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';

class NyisoDaBindingConstraintsReportArchive extends DailyNysioCsvReport {
  NyisoDaBindingConstraintsReportArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'nyiso',
        collectionName: 'binding_constraints');
    this.dbConfig = dbConfig;
    dir ??= super.dir + 'DaBindingConstraints/Raw/';
    this.dir = dir;
    reportName = 'Day-Ahead Binding Constraints Report';
  }

  Db get db => dbConfig.db;

  /// Data available for the most 10 recent days only at this url.
  /// http://mis.nyiso.com/public/csv/DAMLimitingConstraints/20220116DAMLimitingConstraints.csv
  /// Entire month is at
  /// http://mis.nyiso.com/public/csv/DAMLimitingConstraints/20220101DAMLimitingConstraints_csv.zip
  @override
  String getUrl(Date asOfDate) =>
      'http://mis.nyiso.com/public/csv/DAMLimitingConstraints/' +
          yyyymmdd(asOfDate) + 'DAMLimitingConstraints.csv';

  @override
  File getFilename(Date asOfDate) => File(
      dir + yyyymmdd(asOfDate) + 'DAMLimitingConstraints.csv');

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var constraints = <Map<String, dynamic>>[];
    for (var row in rows) {
      constraints.add({
        'Constraint Name': row['ConstraintName'],
        'Contingency Name': row['ContingencyName'],
        'Interface Flag': row['InterfaceFlag'],
        'Marginal Value': row['MarginalValue'],
        'hourBeginning': TZDateTime.parse(location, row['BeginDate']).toUtc(),
      });
    }

    /// Need to take the unique rows.  On 2018-07-10, there were duplicates!
    var uConstraints = unique(constraints);

    return {
      'market': 'DA',
      'date': (rows.first['BeginDate'] as String).substring(0, 10),
      'constraints': uConstraints,
    };
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var aux = json.decode(file.readAsStringSync());
    late var xs;
    if ((aux as Map).containsKey('DayAheadConstraints')) {
      if (aux['DayAheadConstraints'] == '') return <Map<String, dynamic>>[];
      xs = (aux['DayAheadConstraints']['DayAheadConstraint'] as List)
          .cast<Map<String, dynamic>>();
    } else {
      throw ArgumentError('Can\'t find key DayAheadConstraints.  Check file!');
    }

    return [converter(xs)];
  }

  /// Insert data into db
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) {
      print('--->  No data');
      return Future.value(-1);
    }
    var groups = groupBy(data, (dynamic e) => e['date']);
    try {
      for (var date in groups.keys) {
        await dbConfig.coll.remove({'date': date});
        await dbConfig.coll.insertAll(groups[date]!);
        print('--->  Inserted DA binding constraints for day $date');
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
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'market': 1, 'date': 1});
    await dbConfig.db.close();
  }
}
