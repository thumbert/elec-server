library db.mis.sr_rtncpcstlmntsum;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:intl/intl.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;

class SrRtNcpcStlmntSumArchive extends mis.MisReportArchive {
  final DateFormat fmt = DateFormat('MM/dd/yyyy');

  SrRtNcpcStlmntSumArchive({ComponentConfig? dbConfig}) {
    reportName = 'SR_RTNCPCSTLMNTSUM';
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'mis',
        collectionName: reportName.toLowerCase());
    this.dbConfig = dbConfig;
  }

  /// Add the index labels, remove unneeded columns.
  List<Map<String, dynamic>> addLabels(Iterable<Map<String, dynamic>> rows,
      Map<String, dynamic> labels, List<String> removeColumns) {
    if (rows.length == 1 && rows.first.isEmpty) return [];
    return rows.map((e) {
      for (var column in removeColumns) {
        e.remove(column);
      }
      var out = <String, dynamic>{
        ...labels,
        ...e,
      };
      return out;
    }).toList();
  }

  Map<int, List<Map<String, dynamic>>> _processFile_20190101(File file) {
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

    /// tab 0, NCPC Daily settlement section
    var x0 = mis.readReportTabAsMap(file, tab: 0);
    var tab0 = addLabels(x0, labels, ['H']);

    /// tab 1, Economic charges section
    labels['tab'] = 1;
    var x1 = mis.readReportTabAsMap(file, tab: 1);
    var tab1 = addLabels(x1, labels, ['H']);

    /// tab 2, Economic hourly charge section -- SKIP

    /// tab 3, LSCPR charges section
    labels['tab'] = 3;
    var x3 = mis.readReportTabAsMap(file, tab: 3);
    var tab3 = addLabels(x3, labels, ['H']);

    /// tab 4, Asset SCR charges section (hourly)
    labels['tab'] = 4;
    var x4 = mis.readReportTabAsMap(file, tab: 4);
    var tab4 = addLabels([rowsToColumns(x4)], labels, ['H']);

    /// tab 5, Performance audit charge section
    labels['tab'] = 5;
    var x5 = mis.readReportTabAsMap(file, tab: 5);
    var tab5 = addLabels(x5, labels, ['H']);

    /// tab 6, Min Gen Emergency charges section (prior to 1/1/2019)
    labels['tab'] = 6;
    var x6 = mis.readReportTabAsMap(file, tab: 6);
    var tab6 = addLabels(x6, labels, ['H']);

    /// tab 7, Posturing charges section
    labels['tab'] = 7;
    var x7 = mis.readReportTabAsMap(file, tab: 7);
    var tab7 = addLabels(x7, labels, ['H']);

    /// tab 8, Rapid Response Pricing Opportunity Cost charge section
    labels['tab'] = 8;
    var x8 = mis.readReportTabAsMap(file, tab: 8);
    var tab8 = addLabels(x8, labels, ['H']);

    /// tab 9, Dispatch Lost Opportunity charge section
    labels['tab'] = 9;
    var x9 = mis.readReportTabAsMap(file, tab: 9);
    var tab9 = addLabels(x9, labels, ['H']);

    /// tab 10, NCPC daily settlement info by subaccount
    labels['tab'] = 10;
    var x10 = mis.readReportTabAsMap(file, tab: 10);
    var tab10 = addLabels(x10, labels, ['H']);

    /// tab 10, Economic NCPC daily settlement info by subaccount
    labels['tab'] = 11;
    var x11 = mis.readReportTabAsMap(file, tab: 11);
    var tab11 = addLabels(x11, labels, ['H']);

    return {
      0: tab0,
      1: tab1,
      3: tab3,
      4: tab4,
      5: tab5,
      6: tab6,
      7: tab7,
      8: tab8,
      9: tab9,
      10: tab10,
      11: tab11,
    };
  }

  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    var report = mis.MisReport(file);
    var reportDate = report.forDate();

    if (reportDate.isBefore(Date.utc(2014, 12, 3))) {
      return <int, List<Map<String, dynamic>>>{};
    } else if (reportDate.isBefore(Date.utc(2019, 1, 1))) {
      return _processFile_20190101(file);
    } else {
      return _processFile_20190101(file);
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
    print(
        '--->  Inserted $reportName for account ${data.first['account']}, ${data.first['date']}, tab ${tabs.first}, version ${data.first['version']} successfully');
    return 0;
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'account': 1, 'tab': 1, 'date': 1, 'version': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {
      'account': 1,
      'tab': 1,
      'date': 1,
      'version': 1,
      'Subaccount ID': 1,
    }, partialFilterExpression: {
      'Subaccount ID': {'\$exists': true},
      //'tab': {'\$eq': 10},
    });
    await dbConfig.db.close();
  }
}
