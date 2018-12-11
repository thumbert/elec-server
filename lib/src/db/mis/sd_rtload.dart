library db.mis.sd_rtload;

import 'dart:async';
import 'dart:io';
import 'package:tuple/tuple.dart';
import 'package:date/date.dart';
import 'package:collection/collection.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/utils/iso_timestamp.dart';

class SdRtloadArchive extends mis.MisReportArchive {
  ComponentConfig dbConfig;

  SdRtloadArchive({this.dbConfig}) {
    reportName = 'SD_RTLOAD';
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'mis';
    }
    dbConfig.collectionName = 'sd_rtload';
  }

  Map<String,dynamic> rowConverter(List<Map> rows, Date reportDate, DateTime version) {
    var row = <String,dynamic>{};
    row['date'] = reportDate.toString();
    row['version'] = version;
    row['Asset ID'] = rows.first['Asset ID'];
    row['hourBeginning'] = [];
    row['Load Reading'] = [];
    row['Ownership Share'] = [];
    row['Share of Load Reading'] = [];
    rows.forEach((e) {
      row['hourBeginning'].add(
          parseHourEndingStamp(mmddyyyy(reportDate), e['Trading interval']));
      row['Load Reading'].add(e['Load Reading']);
      row['Ownership Share'].add(e['Ownership Share']);
      row['Share of Load Reading'].add(e['Share of Load Reading']);
    });
    return row;
  }

  @override
  Map<int,List<Map<String,dynamic>>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    var report = new mis.MisReport(file);
    var reportDate = report.forDate();
    var version = report.timestamp();
    var dataByAssetId = groupBy(data, (row) => row['Asset ID'] as int);
    var res = dataByAssetId.keys
        .map((assetId) =>
            rowConverter(dataByAssetId[assetId], reportDate, version))
        .toList();
    return {0: res};
  }

  @override
  Future<Null> insertTabData(List<Map<String,dynamic>> data, {int tab: 0}) async {
    if (data.isEmpty) return new Future.value(null);
    /// split the data by Asset ID, date, version
    var groups = groupBy(data, (Map e) =>
      new Tuple3(e['Asset ID'], e['date'], e['version']));
    try {
      for (Tuple3 key in groups.keys) {
        await dbConfig.coll.remove({
          'Asset ID': key.item1,
          'date': key.item2,
          'version': key.item3,
        });
        await dbConfig.coll.insertAll(groups[key]);
      }
      print('--->  Inserted $reportName for ${data.first['date']} tab $tab, version ${data.first['version']} successfully');
    } catch (e) {
      print('   ' + e.toString());
    }
  }
  
  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'Asset ID': 1, 'date': 1,  'version': 1},
        unique: true);
    await dbConfig.db.close();
  }

  @override
  Future<Null> updateDb() {
    // TODO: implement updateDb
  }
}
