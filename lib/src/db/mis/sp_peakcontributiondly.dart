library db.mis.sp_peakcontributiondly;

import 'dart:async';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/converters.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;

class SpPeakContributionDlyArchive extends mis.MisReportArchive {
  ComponentConfig dbConfig;

  SpPeakContributionDlyArchive({this.dbConfig}) {
    reportName = 'SP_PEAKCONTRIBUTIONDLY';
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'mis';
    }
    dbConfig.collectionName = 'sp_peakcontributiondly';
  }

  Map rowConverter(Map row, DateTime version) {
    row['Trading Date'] = formatDate(row['Trading Date']);
    row['version'] = version;
    row.remove('H');
    return row;
  }

  @override
  Map<int,List<Map>> processFile(File file) {
    List<Map> data = mis.readReportTabAsMap(file, tab: 0);
    var report = new mis.MisReport(file);
    var version = report.timestamp();
    var res = data
        .map((Map row) => rowConverter(row, version))
        .toList();
    return {0: res};
  }

  /// Report publishes every day of the month all the previous days of the
  /// month, so it's best to
  /// remove documents that have Trading Date with a version earlier than a
  /// [maxVersion] is an UTC DateTime
  remove(DateTime maxVersion, List<String> days, List<num> assetIds) async {
    List<Future> futs = [];
    for(String date in days) {
      var selector = where
          .eq('Trading Date', date)
          .oneFrom('Asset ID', assetIds)
          .lt('version', maxVersion);
//      var N = await dbConfig.coll.count(selector);
//      print('number of docs to be removed: $N');
      futs.add(dbConfig.coll.remove(selector));
    }
    Future.wait(futs);
  }

  @override
  insertTabData(List<Map> data) {
    List<String> days = data.map((e) => e['Trading Date']).toSet().toList();
    DateTime maxVersion = data.first['version'];
    List<num> assetIds = data.map((e) => e['Asset ID']).toSet().toList();
//    print('days: $days, maxVersion: $maxVersion');
    return remove(maxVersion, days, assetIds).then((_) async {
      await super.insertTabData(data);
//      var N = await dbConfig.coll.count();
//      print('number of docs: $N');
    });
  }

  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'Trading Date': 1, 'Asset ID': 1, 'version': 1},
        unique: true);
    await dbConfig.db.close();
  }

  @override
  Future<Null> updateDb() {
    // TODO: implement updateDb
  }

}

