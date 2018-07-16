library db.mis.sd_rtload;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
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

  Map rowConverter(List<Map> rows, Date reportDate, DateTime version) {
    Map row = {};
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
  List<List<Map>> processFile(File file) {
    List<Map> data = mis.readReportTabAsMap(file, tab: 0);
    var report = new mis.MisReport(file);
    var reportDate = report.forDate();
    var version = report.timestamp();
    Map dataByAssetId = _groupBy(data, (row) => row['Asset ID']);
    var res = dataByAssetId.keys
        .map((assetId) =>
            rowConverter(dataByAssetId[assetId], reportDate, version))
        .toList();
    return [res];
  }

  @override
  Future<Null> insertTabData(List<Map> data) async {
    if (data.isEmpty) return new Future.value(null);
    /// split the data by Asset ID, date, version
    Map groups = _groupBy(data, (Map e) =>
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
      print('--->  Inserted $reportName for ${data.first['date']}, version ${data.first['version']} successfully');
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

  Map _groupBy(Iterable x, Function f) {
    Map result = new Map();
    x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));
    return result;
  }
}
