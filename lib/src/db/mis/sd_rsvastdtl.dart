import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;

class SdRsvAstDtlArchive extends mis.MisReportArchive {
  final DateFormat fmt = DateFormat('MM/dd/yyyy');

  SdRsvAstDtlArchive({ComponentConfig? dbConfig}) {
    reportName = 'SD_RSVASTDTL';
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'mis',
        collectionName: reportName.toLowerCase());
    this.dbConfig = dbConfig;
  }

  @override
  Month get lastMonth => Month(2025, 2, location: IsoNewEngland.location);

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

    /// tab 1, Forward Reserves tab
    var labels = <String, dynamic>{
      'account': account,
      'tab': 1,
      'date': reportDate.toString(),
      'version': version,
    };
    var x1 = mis.readReportTabAsMap(file, tab: 1);

    /// keep only the rows when you have something assigned
    x1 = x1
        .where((e) =>
            e['Forward Reserve TMOR Assigned MWs'] != 0 ||
            e['Forward Reserve TMNSR Assigned MWs'] != 0)
        .toList();
    var grp1 = groupBy(x1, (dynamic e) => e['Asset ID']);
    var tab1 = <Map<String, dynamic>>[];
    for (var entry in grp1.entries) {
      labels['Asset ID'] = entry.key;
      labels['Subaccount ID'] = entry.value.first['Subaccount ID'];
      tab1.addAll(addLabels(
          [collapseListOfMap(entry.value)],
          labels,
          [
            'H',
            'Asset ID',
            'Asset Name',
            'Subaccount ID',
            'Subaccount Name',
            // 'Reserve Zone ID',
            'Reserve Zone Name',
            'Asset Type',
          ]));
    }

    /// tab 4, Asset detail RT reserves hourly
    labels = <String, dynamic>{
      'account': account,
      'tab': 4,
      'date': reportDate.toString(),
      'version': version,
    };
    var x4 = mis.readReportTabAsMap(file, tab: 4);
    var grp4 = groupBy(x4, (dynamic e) => e['Asset ID']);
    var tab4 = <Map<String, dynamic>>[];
    for (var entry in grp4.entries) {
      labels['Asset ID'] = entry.key;
      labels['Subaccount ID'] = entry.value.first['Subaccount ID'];
      tab4.addAll(addLabels(
          [collapseListOfMap(entry.value)],
          labels,
          [
            'H',
            'Asset ID',
            'Asset Name',
            'Subaccount ID',
            'Subaccount Name',
            'Reserve Zone ID',
            'Reserve Zone Name',
            'Asset Type',
          ]));
    }

    return {
      1: tab1,
      4: tab4,
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
    print('--->  Inserted $reportName for account ${data.first['account']}, '
        ' ${data.first['date']}, tab $tab, version ${data.first['version']} successfully');
    return 0;
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    var collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName)) {
      await dbConfig.coll.drop();
    }
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {
      'account': 1,
      'tab': 1,
      'date': 1,
      'version': 1,
      'Asset ID': 1,
    });
    await dbConfig.db.close();
  }

  Future<void> updateDb() async {
    return;
  }
}
