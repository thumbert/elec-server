library db.mis.sr_rsvcharge;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:tuple/tuple.dart';

class SrRsvChargeArchive extends mis.MisReportArchive {
  final DateFormat fmt = DateFormat('MM/dd/yyyy');

  SrRsvChargeArchive({ComponentConfig? dbConfig}) {
    reportName = 'SR_RSVCHARGE';
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'mis',
        collectionName: reportName.toLowerCase());
    this.dbConfig = dbConfig;
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

    /// tab 0, forward reserve market -- pool section
    /// tab 1, reserve zone section
    /// tab 2, reserve market - load zone section
    /// tab 3, rt reserve - load zone details section

    /// tab 4, participant account section
    labels['tab'] = 4;
    var x4 = mis.readReportTabAsMap(file, tab: 4);
    var grp4 = groupBy(x4, (dynamic e) => e['Load Zone ID'] as int?);
    var tab4 = <Map<String, dynamic>>[];
    for (var entry in grp4.entries) {
      labels['Load Zone ID'] = entry.key;
      tab4.addAll(mis.MisReport.addLabels(
          [collapseListOfMap(entry.value)],
          labels,
          [
            'H',
            'Trading Interval',
            'Load Zone Name',
            'Load Zone ID',
          ]));
    }

    /// tab 5, rt reserve - participant detail section

    /// tab 6, subaccount section
    labels['tab'] = 6;
    var x6 = mis.readReportTabAsMap(file, tab: 6);
    var grp6 = groupBy(
        x6, (dynamic e) => Tuple2(e['Subaccount ID'], e['Load Zone ID']));
    var tab6 = <Map<String, dynamic>>[];
    for (var entry in grp6.entries) {
      labels['Subaccount ID'] = entry.key.item1;
      labels['Load Zone ID'] = entry.key.item2;
      tab6.addAll(mis.MisReport.addLabels(
          [collapseListOfMap(entry.value)],
          labels,
          [
            'H',
            'Subaccount ID',
            'Subaccount Name',
            'Trading Interval',
            'Load Zone Name',
            'Load Zone ID',
          ]));
    }

    return {
      4: tab4,
      6: tab6,
    };
  }

  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    var report = mis.MisReport(file);
    var reportDate = report.forDate();

    if (reportDate.isBefore(Date.utc(2017, 3, 1))) {
      return <int, List<Map<String, dynamic>>>{};
    } else if (reportDate.isBefore(Date.utc(2100, 1, 1))) {
      return _processFile_21000101(file);
    } else {
      return _processFile_21000101(file);
    }
  }

  /// Only one tab at a time only!
  @override
  Future<Null> insertTabData(List<Map<String, dynamic>> data,
      {int tab = 0}) async {
    if (data.isEmpty) return Future.value(null);
    var tabs = data.map((e) => e['tab']).toSet();
    if (tabs.length != 1) {
      throw ArgumentError('Input data can\'t be for multiple tabs: $tabs');
    }
    try {
      await dbConfig.coll.remove({
        'account': data.first['account'],
        'tab': data.first['tab'],
        'date': data.first['date'],
        'version': data.first['version'],
      });
      await dbConfig.coll.insertAll(data);
      print(
          '--->  Inserted $reportName for account ${data.first['account']}, ${data.first['date']}, tab ${tabs.first}, version ${data.first['version']} successfully');
    } catch (e) {
      print('XXX ' + e.toString());
    }
  }

  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'account': 1, 'tab': 1, 'date': 1, 'version': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {
      'account': 1,
      'tab': 1,
      'date': 1,
      'version': 1,
      'Subaccount ID': 1,
    });
    await dbConfig.db.close();
  }
}
