library db.mis.sr_rtlocsum;

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:tuple/tuple.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/utils/iso_timestamp.dart';

class SrRtLocSumArchive extends mis.MisReportArchive {
  SrRtLocSumArchive({ComponentConfig? dbConfig}) {
    reportName = 'SR_RTLOCSUM';
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'mis',
        collectionName: reportName.toLowerCase());
    this.dbConfig = dbConfig;
  }

  /// Override the implementation.
  @override
  Future<int> insertTabData(List<Map<String, dynamic>> data,
      {int tab = 0}) async {
    if (data.isEmpty) return Future.value(-1);
    if (tab == 0) {
      return await insertTabData0(data);
    } else if (tab == 1) {
      return await insertTabData1(data);
    } else {
      throw ArgumentError('Unsupported tab $tab for report $reportName');
    }
  }

  Future<int> insertTabData0(List<Map<String, dynamic>> data) async {
    String? account = data.first['account'];

    /// split the data by Location ID, date, version
    var groups = groupBy(
        data, (Map e) => Tuple3(e['Location ID'], e['date'], e['version']));
    try {
      for (var key in groups.keys) {
        await dbConfig.coll.remove({
          'account': account,
          'tab': 0,
          'Location ID': key.item1,
          'date': key.item2,
          'version': key.item3,
        });
        await dbConfig.coll.insertAll(groups[key]!);
      }
      print(
          '--->  Inserted $reportName for ${data.first['date']}, version ${data.first['version']}, tab 0 successfully');
      return 0;
    } catch (e) {
      print('XXX $e');
      return 1;
    }
  }

  Future<int> insertTabData1(List<Map<String, dynamic>> data) async {
    String? account = data.first['account'];

    /// split the data by Asset ID, date, version
    var groups = groupBy(
        data,
        (Map e) => Tuple4(
            e['Subaccount ID'], e['Location ID'], e['date'], e['version']));
    try {
      for (var key in groups.keys) {
        await dbConfig.coll.remove({
          'account': account,
          'tab': 1,
          'Subaccount ID': key.item1,
          'Location ID': key.item2,
          'date': key.item3,
          'version': key.item4,
        });
        await dbConfig.coll.insertAll(groups[key]!);
      }
      print(
          '--->  Inserted $reportName for ${data.first['date']}, version ${data.first['version']}, tab 1 successfully');
      return 0;
    } catch (e) {
      print('XXX $e');
      return 1;
    }
  }

  /// for the first tab
  Map<String, dynamic> rowConverter0(List<Map<String, dynamic>> rows,
      String account, Date reportDate, DateTime version) {
    var row = <String, dynamic>{};
    row['account'] = account;
    row['tab'] = 0;
    row['date'] = reportDate.toString();
    row['version'] = version;
    row['Location ID'] = rows.first['Location ID'];
    row['hourBeginning'] = [];
    var excludeColumns = [
      'H',
      'Location ID',
      'Trading Interval',
      'Location Name',
      'Location Type',
      ''
    ];
    var keepColumns = rows.first.keys.toList();
    keepColumns.removeWhere((e) => excludeColumns.contains(e));
    for (var column in keepColumns) {
      row[mis.removeParanthesesEnd(column)] = [];
    }
    for (var e in rows) {
      row['hourBeginning'].add(parseHourEndingStamp(
          mmddyyyy(reportDate), stringHourEnding(e['Trading Interval'])!));
      for (var column in keepColumns) {
        row[mis.removeParanthesesEnd(column)].add(e[column]);
      }
    }
    return row;
  }

  /// for the second tab (subaccount info)
  Map<String, dynamic> rowConverter1(
      List<Map> rows, String account, Date reportDate, DateTime version) {
    var row = <String, dynamic>{};
    row['account'] = account;
    row['Subaccount ID'] = rows.first['Subaccount ID'].toString();
    row['tab'] = 1;
    row['date'] = reportDate.toString();
    row['version'] = version;
    row['Location ID'] = rows.first['Location ID'];
    row['hourBeginning'] = [];
    var excludeColumns = [
      'H',
      'Subaccount ID',
      'Subaccount Name',
      'Location ID',
      'Trading Interval',
      'Location Name',
      'Location Type',
      ''
    ];
    var keepColumns = rows.first.keys.toList();
    keepColumns.removeWhere((e) => excludeColumns.contains(e));
    for (var column in keepColumns) {
      row[mis.removeParanthesesEnd(column)] = [];
    }
    for (var e in rows) {
      row['hourBeginning'].add(parseHourEndingStamp(
          mmddyyyy(reportDate), stringHourEnding(e['Trading Interval'])!));
      for (var column in keepColumns) {
        row[mis.removeParanthesesEnd(column)].add(e[column]);
      }
    }
    return row;
  }

  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    /// tab 0: company data
    var data = mis.readReportTabAsMap(file, tab: 0);
    var report = mis.MisReport(file);
    var account = report.accountNumber();
    var reportDate = report.forDate();
    var version = report.timestamp();
    var dataById = groupBy(data, (dynamic row) => row['Location ID']);
    var res0 = dataById.keys
        .map((assetId) =>
            rowConverter0(dataById[assetId]!, account, reportDate, version))
        .toList();

    /// tab 1: subaccount data
    data = mis.readReportTabAsMap(file, tab: 1);
    var res1 = <Map<String, dynamic>>[];
    if (data.isNotEmpty) {
      var dataById = groupBy(data,
          (dynamic row) => Tuple2(row['Subaccount ID'], row['Location ID']));
      res1 = dataById.keys
          .map((tuple) =>
              rowConverter1(dataById[tuple]!, account, reportDate, version))
          .toList();
    }

    return {0: res0, 1: res1};
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    // var collections = await dbConfig.db.getCollectionNames();
    // if (collections.contains(dbConfig.collectionName)) {
    //   await dbConfig.coll.drop();
    // }
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'account': 1,
          'tab': 1,
          'Location ID': 1,
          'date': 1,
          'version': 1
        },
        unique: true,
        partialFilterExpression: {
          'tab': {'\$eq': 0},
        });
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'account': 1,
          'tab': 1,
          'Subaccount ID': 1,
          'Location ID': 1,
          'date': 1,
          'version': 1
        },
        unique: true,
        partialFilterExpression: {
          'Subaccount ID': {'\$exists': true},
          'tab': {'\$eq': 1},
        });

    await dbConfig.db.close();
  }
}
