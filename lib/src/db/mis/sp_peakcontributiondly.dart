library db.mis.sp_peakcontributiondly;

import 'dart:async';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/converters.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;

class SpPeakContributionDlyArchive extends mis.MisReportArchive {
  SpPeakContributionDlyArchive({ComponentConfig? dbConfig}) {
    reportName = 'SP_PEAKCONTRIBUTIONDLY';
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'mis',
        collectionName: reportName.toLowerCase());
    this.dbConfig = dbConfig;
  }

  Map<String, dynamic> rowConverter(
      Map<String, dynamic> row, DateTime version) {
    row['Trading Date'] = formatDate(row['Trading Date']);
    row['version'] = version;
    row.remove('H');
    return row;
  }

  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    var report = mis.MisReport(file);
    var version = report.timestamp();
    var res = data
        .map((Map row) => rowConverter(row as Map<String, dynamic>, version))
        .toList();
    return {0: res};
  }

  /// Report publishes every day of the month all the previous days of the
  /// month, so it's best to
  /// remove documents that have Trading Date with a version earlier than a
  /// [maxVersion] is an UTC DateTime
  Future remove(
      DateTime? maxVersion, List<String?> days, List<num?> assetIds) async {
    var futs = <Future>[];
    for (var date in days) {
      var selector = where
          .eq('Trading Date', date)
          .oneFrom('Asset ID', assetIds)
          .lte('version', maxVersion);
      futs.add(dbConfig.coll.remove(selector));
    }
    return Future.wait(futs);
  }

  @override
  Future<int> insertTabData(List<Map> data, {int tab = 0}) async {
    if (data.isEmpty) return Future.value(-1);
    var days = data.map((e) => e['Trading Date'] as String?).toSet().toList();
    var maxVersion = data.first['version'];
    var assetIds = data.map((e) => e['Asset ID'] as num?).toSet().toList();
    await remove(maxVersion, days, assetIds);
    await dbConfig.coll.insertAll(data as List<Map<String, dynamic>>);
    print('--->  Inserted $reportName for ${data.first['Trading Date']}'
        ' tab $tab, version ${data.first['version']} successfully');
    return 0;
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'Trading Date': 1, 'Asset ID': 1, 'version': 1}, unique: true);
    await dbConfig.db.close();
  }
}
