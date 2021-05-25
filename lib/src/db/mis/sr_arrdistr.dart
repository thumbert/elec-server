library db.mis.sr_arrdistr;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;

class SrArrDistrArchive extends mis.MisReportArchive {
  SrArrDistrArchive({ComponentConfig? dbConfig}) {
    reportName = 'SR_ARRDISTR';
    if (dbConfig == null) {
      this.dbConfig = ComponentConfig(
          host: '127.0.0.1', dbName: 'mis', collectionName: reportName.toLowerCase());
    }
  }

  /// the entire tab is one document
  Map<String, dynamic> rowConverter(
      List<Map> rows, Date reportDate, DateTime version, int tab) {
    var document = <String, dynamic>{};
    document['month'] = reportDate.toString().substring(0,7);  /// yyyy-mm
    document['version'] = version.toIso8601String();
    document['tab'] = tab;
    var columns = rows.first.keys.skip(1);
    for (var column in columns) document[column] = [];

    rows.forEach((e) {
      for (var column in columns) document[column].add(e[column]);
    });
    return document;
  }

  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    var report = mis.MisReport(file);
    var reportDate = report.forDate();
    var version = report.timestamp();

    var out = <int,List<Map<String, dynamic>>>{};
    for (var tab in [0,1,2]) {
      var rows = mis.readReportTabAsMap(file, tab: tab);
      if (rows.isNotEmpty) {
        var aux = rowConverter(rows, reportDate, version, tab);
        out[tab] = [aux];
      }
    }

    return out;
  }

  Future<int> insertTabData(List<Map<String,dynamic>> data, {int tab: 0}) async {
    if (data.isEmpty) return Future.value(null);
    var date = data.first['month'];
    var version = data.first['version'];
    try {
      await dbConfig.coll.remove({
        'month': date,
        'version': version,
        'tab': tab,
      });
      await dbConfig.coll.insertAll(data);
      print('--->  Inserted $reportName for $date, version $version, tab $tab successfully');
      return Future.value(0);
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
  }


  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'month': 1, 'tab': 1, 'version': 1}, unique: true);
    await dbConfig.db.close();
  }

}
