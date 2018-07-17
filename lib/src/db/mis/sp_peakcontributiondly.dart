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
  Future remove(DateTime maxVersion, List<String> days, List<num> assetIds) async {
    List<Future> futs = [];
    for(String date in days) {
      var selector = where
          .eq('Trading Date', date)
          .oneFrom('Asset ID', assetIds)
          .lte('version', maxVersion);
      futs.add(dbConfig.coll.remove(selector));
    }
    return Future.wait(futs);
  }

  @override
  insertTabData(List<Map> data, {int tab: 0}) async {
    List<String> days = data.map((e) => e['Trading Date']).toSet().toList();
    DateTime maxVersion = data.first['version'];
    List<num> assetIds = data.map((e) => e['Asset ID']).toSet().toList();
    try{
      await remove(maxVersion, days, assetIds);
      await dbConfig.coll.insertAll(data);
      print('--->  Inserted $reportName for ${data.first['Trading Date']}, version ${data.first['version']} successfully');
    } catch (e) {
      print('XXX ' + e.toString());
    }
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

