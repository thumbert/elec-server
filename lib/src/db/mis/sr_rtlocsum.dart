library elec.load.sr_rtlocsum;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/utils/iso_timestamp.dart';

class SrRtLocSumArchive extends mis.MisReportArchive {
  ComponentConfig dbConfig;

  SrRtLocSumArchive({this.dbConfig}) {
    reportName = 'SR_RTLOCSUM';
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'mis';
    }
    dbConfig.collectionName = 'sr_rtlocsum';
  }

  /// for the first tab
  Map rowConverter0(List<Map> rows, Date reportDate, DateTime version) {
    Map row = {};
    row['tab'] = 0;
    row['date'] = reportDate.toString();
    row['version'] = version;
    row['Location ID'] = rows.first['Location ID'];
    row['hourBeginning'] = [];
    List excludeColumns = [
      'H',
      'Location ID',
      'Trading Interval',
      'Location Name',
      'Location Type',
      ''
    ];
    List keepColumns = rows.first.keys.toList();
    keepColumns.removeWhere((e) => excludeColumns.contains(e));
    keepColumns.forEach((column) {
      row[column] = [];
    });
    rows.forEach((e) {
      row['hourBeginning'].add(parseHourEndingStamp(
          mmddyyyy(reportDate), stringHourEnding(e['Trading Interval'])));
      keepColumns.forEach((column) {
        row[column].add(e[column]);
      });
    });
    return row;
  }

  @override
  List<Map> processFile(File file) {
    /// tab 0: company data
    List<Map> data = mis.readReportTabAsMap(file, tab: 0);
    var report = new mis.MisReport(file);
    var reportDate = report.forDate();
    var version = report.timestamp();
    Map dataById = _groupBy(data, (row) => row['Location ID']);
    var res0 = dataById.keys
        .map((assetId) => rowConverter0(dataById[assetId], reportDate, version))
        .toList();

    /// tab 1: subaccount data

    return res0;
  }

  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'tab': 1, 'Location ID': 1, 'date': 1, 'version': 1},
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
