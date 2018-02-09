library elec.load.sr_rtlocsum;

import 'dart:async';
import 'dart:io';
import 'package:tuple/tuple.dart';
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
  Map rowConverter0(List<Map> rows, String account, Date reportDate, DateTime version) {
    Map row = {};
    row['account'] = account;
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
      row[mis.removeParanthesesEnd(column)] = [];
    });
    rows.forEach((e) {
      row['hourBeginning'].add(parseHourEndingStamp(
          mmddyyyy(reportDate), stringHourEnding(e['Trading Interval'])));
      keepColumns.forEach((column) {
        row[mis.removeParanthesesEnd(column)].add(e[column]);
      });
    });
    return row;
  }

  /// for the second tab (subaccount info)
  Map rowConverter1(List<Map> rows, String account, Date reportDate, DateTime version) {
    Map row = {};
    row['account'] = account;
    row['Subaccount ID'] = rows.first['Subaccount ID'];
    row['tab'] = 1;
    row['date'] = reportDate.toString();
    row['version'] = version;
    row['Location ID'] = rows.first['Location ID'];
    row['hourBeginning'] = [];
    List excludeColumns = [
      'H',
      'Subaccount ID',
      'Subaccount Name',
      'Location ID',
      'Trading Interval',
      'Location Name',
      'Location Type',
      ''
    ];
    List keepColumns = rows.first.keys.toList();
    keepColumns.removeWhere((e) => excludeColumns.contains(e));
    keepColumns.forEach((column) {
      row[mis.removeParanthesesEnd(column)] = [];
    });
    rows.forEach((e) {
      row['hourBeginning'].add(parseHourEndingStamp(
          mmddyyyy(reportDate), stringHourEnding(e['Trading Interval'])));
      keepColumns.forEach((column) {
        row[mis.removeParanthesesEnd(column)].add(e[column]);
      });
    });
    return row;
  }


  @override
  List<List<Map>> processFile(File file) {
    /// tab 0: company data
    List<Map> data = mis.readReportTabAsMap(file, tab: 0);
    var report = new mis.MisReport(file);
    var account = report.accountNumber();
    var reportDate = report.forDate();
    var version = report.timestamp();
    Map dataById = _groupBy(data, (row) => row['Location ID']);
    var res0 = dataById.keys
        .map((assetId) => rowConverter0(dataById[assetId], account, reportDate, version))
        .toList();

    /// tab 1: subaccount data
    data = mis.readReportTabAsMap(file, tab: 1);
    List res1 = [];
    if (data.isNotEmpty) {
      Map dataById = _groupBy(data, (row) => new Tuple2(row['Subaccount ID'],row['Location ID']));
      res1 = dataById.keys
          .map((tuple) => rowConverter1(dataById[tuple], account, reportDate, version))
          .toList();
    }

    return [res0, res1];
  }

  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'account': 1, 'tab': 1, 'Location ID': 1, 'date': 1, 'version': 1},
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
