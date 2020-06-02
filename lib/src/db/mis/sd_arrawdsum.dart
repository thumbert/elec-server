library db.mis.sd_arrawdsum;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;

class SdArrAwdSumArchive extends mis.MisReportArchive {
  @override
  ComponentConfig dbConfig;

  SdArrAwdSumArchive({this.dbConfig}) {
    reportName = 'SD_ARRAWDSUM';
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'mis';
    dbConfig.collectionName = reportName.toLowerCase();
  }

  /// the entire tab is one document
  Map<String, dynamic> rowConverter(
      List<Map> rows, String account, Date reportDate, String version) {
    var document = <String, dynamic>{};
    document['account'] = account;
    document['month'] = reportDate.toString().substring(0,7);  /// yyyy-mm
    document['version'] = version;
    var columns = rows.first.keys.skip(1);
    for (var column in columns) {
      document[column] = [];
    }

    rows.forEach((e) {
      for (var column in columns) {
        document[column].add(e[column]);
      }
    });
    return document;
  }

  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    var report = mis.MisReport(file);
    var account = report.accountNumber();
    var reportDate = report.forDate();
    var version = report.timestamp().toIso8601String();
    var rows = mis.readReportTabAsMap(file, tab: 0);
    var data0 = rowConverter(rows, account, reportDate, version);
    return {
      0: [data0]
    };
  }

  @override
  Future<int> insertTabData(List<Map<String,dynamic>> data, {int tab = 0}) async {
    if (data.isEmpty) return Future.value(null);
    var account = data.first['account'];
    var date = data.first['month'];
    var version = data.first['version'];
    try {
      await dbConfig.coll.remove({
        'account': account,
        'month': date,
        'version': version,
      });
      await dbConfig.coll.insertAll(data);
      print('--->  Inserted $reportName for account $account, month $date, version $version, tab $tab successfully');
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
        keys: {'account': 1,
      'month': 1, 'Location ID': 1, 'version': 1});
    await dbConfig.db.close();
  }

  @override
  Future<Null> updateDb() {
    // TODO: implement updateDb
  }
}
