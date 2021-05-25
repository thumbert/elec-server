library db.mis.sd_rsvastdtl;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;

class SdRsvAstDtlArchive extends mis.MisReportArchive {
  late ComponentConfig dbConfig;
  final DateFormat fmt = DateFormat('MM/dd/yyyy');

  SdRsvAstDtlArchive({ComponentConfig? dbConfig}) {
    reportName = 'SD_RSVASTDTL';
    if (dbConfig == null) {
      this.dbConfig = ComponentConfig(
          host: '127.0.0.1', dbName: 'mis', collectionName: reportName.toLowerCase());
    }
  }

  /// Add the index labels, remove unneeded columns.
  List<Map<String,dynamic>> addLabels(Iterable<Map<String,dynamic>> rows,
      Map<String,dynamic> labels, List<String> removeColumns) {
    return rows.map((e) {
      for (var column in removeColumns) {
        e.remove(column);
      }
      var out = <String,dynamic>{
        ...labels,
        ...e,
      };
      return out;
    }).toList();
  }

  Map<int,List<Map<String,dynamic>>> _processFile_21000101(File file) {
    var report = mis.MisReport(file);
    var account = report.accountNumber();
    var reportDate = report.forDate();
    var version = report.timestamp().toIso8601String();

    /// tab 4, Asset detail RT reserves hourly
    var labels = <String,dynamic>{
      'account': account,
      'tab': 4,
      'date': reportDate.toString(),
      'version': version,
    };
    var x4 = mis.readReportTabAsMap(file, tab: 4);
    var grp = groupBy(x4, (dynamic e) => e['Asset ID']);
    var tab4 = <Map<String,dynamic>>[];
    for (var entry in grp.entries) {
      labels['Asset ID'] = entry.key;
      labels['Subaccount ID'] = entry.value.first['Subaccount ID'];
      tab4.addAll(addLabels([rowsToColumns(entry.value)], labels,
          ['H', 'Asset ID', 'Asset Name', 'Subaccount ID', 'Subaccount Name',
          'Reserve Zone ID', 'Reserve Zone Name', 'Asset Type']));
    }

    return {
      4: tab4,
    };
  }

  @override
  Map<int,List<Map<String,dynamic>>> processFile(File file) {
    var report = mis.MisReport(file);
    var reportDate = report.forDate();

    if (reportDate.isBefore(Date.utc(2014, 12, 3))) {
      return <int,List<Map<String,dynamic>>>{};
    } else {
      return _processFile_21000101(file);
    }
  }


  /// Only one tab at a time only!
  Future<Null> insertTabData(List<Map<String,dynamic>> data, {int tab: 0}) async {
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
      print('--->  Inserted $reportName for account ${data.first['account']}, ${data.first['date']}, tab $tab, version ${data.first['version']} successfully');
    } catch (e) {
      print('XXX ' + e.toString());
    }
  }


  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String?> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'account': 1,
          'tab': 1,
          'date': 1,
          'version': 1,
          'Asset ID': 1,
        });
    await dbConfig.db.close();
  }


  Future<Null> updateDb() async {
    // TODO: implement updateDb
    return null;
  }
}
