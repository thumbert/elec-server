import 'dart:async';
import 'dart:io';
import 'package:tuple/tuple.dart';
import 'package:date/date.dart';
import 'package:collection/collection.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/utils/iso_timestamp.dart';

class SdRtloadArchive extends mis.MisReportArchive {
  SdRtloadArchive({ComponentConfig? dbConfig}) {
    reportName = 'SD_RTLOAD';
    if (dbConfig == null) {
      this.dbConfig = ComponentConfig(
          host: '127.0.0.1', dbName: 'mis', collectionName: 'sd_rtload');
    } else {
      this.dbConfig = dbConfig;
    }
  }

  Map<String, dynamic> rowConverter(
      List<Map> rows, Date reportDate, DateTime version) {
    var row = <String, dynamic>{};
    row['date'] = reportDate.toString();
    row['version'] = version;
    row['Asset ID'] = rows.first['Asset ID'];
    row['hourBeginning'] = [];
    row['Load Reading'] = [];
    row['Ownership Share'] = [];
    row['Share of Load Reading'] = [];
    for (var e in rows) {
      if (e['Trading interval'] is num) {
        e['Trading interval'] =
            e['Trading interval'].toString().padLeft(2, '0');
      }
      row['hourBeginning'].add(
          parseHourEndingStamp(mmddyyyy(reportDate), e['Trading interval']));
      row['Load Reading'].add(e['Load Reading']);
      row['Ownership Share'].add(e['Ownership Share']);
      row['Share of Load Reading'].add(e['Share of Load Reading']);
    }
    return row;
  }

  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    var report = mis.MisReport(file);
    var reportDate = report.forDate();
    var version = report.timestamp();
    var dataByAssetId = groupBy(data, (dynamic row) => row['Asset ID'] as int?);
    var res = dataByAssetId.keys
        .map((assetId) =>
            rowConverter(dataByAssetId[assetId]!, reportDate, version))
        .toList();
    return {0: res};
  }

  @override
  Future<int> insertTabData(List<Map<String, dynamic>> data,
      {int tab = 0}) async {
    if (data.isEmpty) return Future.value(-1);

    /// split the data by Asset ID, date, version
    var groups = groupBy(
        data, (Map e) => Tuple3(e['Asset ID'], e['date'], e['version']));
    for (var key in groups.keys) {
      await dbConfig.coll.remove({
        'Asset ID': key.item1,
        'date': key.item2,
        'version': key.item3,
      });
      await dbConfig.coll.insertAll(groups[key]!);
    }
    print(
        '--->  Inserted $reportName for ${data.first['date']} tab $tab, version ${data.first['version']} successfully');

    return 0;
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'Asset ID': 1, 'date': 1, 'version': 1}, unique: true);
    await dbConfig.db.close();
  }
}
