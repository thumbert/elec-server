import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;

class SrRegSummaryArchive extends mis.MisReportArchive {
  final DateFormat fmt = DateFormat('MM/dd/yyyy');

  SrRegSummaryArchive({ComponentConfig? dbConfig}) {
    reportName = 'SR_REGSUMMARY';
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'mis',
        collectionName: reportName.toLowerCase());
    this.dbConfig = dbConfig;
  }

//  /// Add the index labels, remove unneeded columns.
//  List<Map<String,dynamic>> addLabels(Iterable<Map<String,dynamic>> rows,
//      Map<String,dynamic> labels, List<String> removeColumns) {
//    return rows.map((e) {
//      for (var column in removeColumns) e.remove(column);
//      var out = <String,dynamic>{
//        ...labels,
//        ...e,
//      };
//      return out;
//    }).toList();
//  }

  Map<int, List<Map<String, dynamic>>> _processFile_21000101(File file) {
    var report = mis.MisReport(file);
    var account = report.accountNumber();
    var reportDate = report.forDate();
    var version = report.timestamp().toIso8601String();

    var labels = <String, dynamic>{
      'account': account,
      'tab': 0,
      'date': reportDate.toString(),
      'version': version,
    };

    var x0 = mis.readReportTabAsMap(file, tab: 0);
    var tab0 = mis.MisReport.addLabels([rowsToColumns(x0)], labels, ['H']);

    labels['tab'] = 1;
    var x1 = mis.readReportTabAsMap(file, tab: 1);
    var grp = groupBy(x1, (dynamic e) => e['Subaccount ID']);
    var tab1 = <Map<String, dynamic>>[];
    for (var entry in grp.entries) {
      labels['Subaccount ID'] = entry.key;
      tab1.addAll(mis.MisReport.addLabels([rowsToColumns(entry.value)], labels,
          ['H', 'Subaccount ID', 'Subaccount Name']));
    }

    return {
      0: tab0,
      1: tab1,
    };
  }

  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    var report = mis.MisReport(file);
    var reportDate = report.forDate();

    if (reportDate.isBefore(Date.utc(2017, 12, 1))) {
      return <int, List<Map<String, dynamic>>>{};
    } else {
      return _processFile_21000101(file);
    }
  }

  /// Only one tab at a time only!
  @override
  Future<int> insertTabData(List<Map<String, dynamic>> data,
      {int tab = 0}) async {
    if (data.isEmpty) return Future.value(-1);
    var tabs = data.map((e) => e['tab']).toSet();
    if (tabs.length != 1) {
      throw ArgumentError('Input data can\'t be for multiple tabs: $tabs');
    }
    await dbConfig.coll.remove({
      'account': data.first['account'],
      'tab': data.first['tab'],
      'date': data.first['date'],
      'version': data.first['version'],
    });
    await dbConfig.coll.insertAll(data);
    print('--->  Inserted $reportName for account ${data.first['account']},'
        ' ${data.first['date']}, tab $tab, version ${data.first['version']} successfully');
    return 0;
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'account': 1, 'tab': 1, 'date': 1, 'version': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'account': 1,
          'tab': 1,
          'date': 1,
          'version': 1,
          'Subaccount ID': 1,
        },
        unique: true,
        partialFilterExpression: {
          'Subaccount ID': {'\$exists': true},
          'tab': {'\$eq': 1},
        });
    await dbConfig.db.close();
  }
}
