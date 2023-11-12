library db.mis.sd_arrawdsum;

import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:table/table.dart';

class SdArrAwdSumArchive extends mis.MisReportArchive {
  SdArrAwdSumArchive({ComponentConfig? dbConfig}) {
    reportName = 'SD_ARRAWDSUM';
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

  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    var report = mis.MisReport(file);
    var account = report.accountNumber();
    var reportDate = report.forDate();
    var version = report.timestamp().toIso8601String();
    var rows = mis.readReportTabAsMap(file, tab: 0);
    var labels = <String, dynamic>{
      'account': account,
      'tab': 0,
      'month': reportDate.toString().substring(0, 7),
      'version': version,
    };
    var tab0 =
        addLabels([collapseListOfMap(rows)], labels, ['H', 'Location Name']);

    /// tab 1, data by subaccount
    labels['tab'] = 1;
    rows = mis.readReportTabAsMap(file, tab: 1);
    var grp = groupBy(rows, (dynamic e) => (e['Subaccount ID']).toString());
    var tab1 = <Map<String, dynamic>>[];
    for (var entry in grp.entries) {
      labels['Subaccount ID'] = entry.value.first['Subaccount ID'].toString();
      tab1.addAll(addLabels([collapseListOfMap(entry.value)], labels,
          ['H', 'Subaccount ID', 'Subaccount Name', 'Location Name']));
    }
    return {
      0: tab0,
      1: tab1,
    };
  }

  @override
  Future<int> insertTabData(List<Map<String, dynamic>> data,
      {int tab = 0}) async {
    if (data.isEmpty) return Future.value(-1);
    var account = data.first['account'];
    var date = data.first['month'];
    var version = data.first['version'];
    var tab = data.first['tab'];
    try {
      await dbConfig.coll.remove({
        'account': account,
        'month': date,
        'version': version,
        'tab': tab,
      });
      await dbConfig.coll.insertAll(data);
      print(
          '--->  Inserted $reportName for account $account, month $date, version $version, tab $tab successfully');
      return Future.value(0);
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
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
    });
    await dbConfig.db.close();
  }
}
