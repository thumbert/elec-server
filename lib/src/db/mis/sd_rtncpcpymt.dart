library db.mis.sd_rtncpcpymt;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;

class SdRtNcpcPymtArchive extends mis.MisReportArchive {
  final DateFormat fmt = DateFormat('MM/dd/yyyy');

  SdRtNcpcPymtArchive({ComponentConfig? dbConfig}) {
    reportName = 'SD_RTNCPCPYMNT';
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'mis',
        collectionName: reportName.toLowerCase());
    this.dbConfig = dbConfig;
  }

  /// Add the index labels, remove unneeded columns.
  List<Map<String, dynamic>> addLabels(Iterable<Map<String, dynamic>> rows,
      Map<String, dynamic> labels, List<String> removeColumns) {
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

    /// tab 0, Settlement period summary section
    var x0 = mis.readReportTabAsMap(file, tab: 0);
    var tab0 = addLabels(x0, labels, ['H']);

    /// tab 1, Startup amortization summary section -- hourly
//    labels['tab'] = 1;
//    var x1 = mis.readReportTabAsMap(file, tab: 1);
//    var tab1 = addLabels(x1, labels, ['H']);

    /// tab 2, Generator credits section -- hourly
    labels['tab'] = 2;
    var x2 = mis.readReportTabAsMap(file, tab: 2);
    var grp = groupBy(x2, (dynamic e) => e['Asset ID']);
    var tab2 = <Map<String, dynamic>>[];
    for (var entry in grp.entries) {
      labels['Asset ID'] = entry.key;
      tab2.addAll(addLabels([rowsToColumns(entry.value)], labels,
          ['H', 'Asset ID', 'Asset Name']));
    }

    /// tab 3, External Node Credits section -- hourly
//    labels['tab'] = 3;
//    var x3 = mis.readReportTabAsMap(file, tab: 3);
//    var tab3 = addLabels(x3, labels, ['H']);

    return {
      0: tab0,
      2: tab2,
    };
  }

  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    var report = mis.MisReport(file);
    var reportDate = report.forDate();

    if (reportDate.isBefore(Date.utc(2014, 12, 3))) {
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
    print(
        '--->  Inserted $reportName for account ${data.first['account']}, ${data.first['date']}, tab $tab, version ${data.first['version']} successfully');
    return 0;
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    // List<String?> collections = await dbConfig.db.getCollectionNames();
    // if (collections.contains(dbConfig.collectionName))
    //   await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {
      'account': 1,
      'tab': 1,
      'date': 1,
      'version': 1,
      'Asset ID': 1,
    }, partialFilterExpression: {
      'Subaccount ID': {'\$exists': true},
      'tab': {'\$neq': 3},
    });
    await dbConfig.db.close();
  }

  Future<void> updateDb() async {
    // TODO: implement updateDb
    return null;
  }
}
