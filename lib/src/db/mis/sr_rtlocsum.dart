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

  /// Override the implementation.
  Future insertTabData(List<Map> data, {int tab: 0}) async {
    if (data.isEmpty) return new Future.value(null);
    if (tab == 0) await insertTabData0(data);
    else if (tab == 1) await insertTabData1(data);
    else
      throw new ArgumentError('Unsupported tab $tab for report ${reportName}');
  }

  Future<Null> insertTabData0(List<Map> data) async {
    if (data.isEmpty) return new Future.value(null);
    String account = data.first['account'];
    /// split the data by Location ID, date, version
    Map groups = _groupBy(data, (Map e) =>
    new Tuple3(e['Location ID'], e['date'], e['version']));
    try {
      for (Tuple3 key in groups.keys) {
        await dbConfig.coll.remove({
          'account': account,
          'tab': 0,
          'Location ID': key.item1,
          'date': key.item2,
          'version': key.item3,
        });
        await dbConfig.coll.insertAll(groups[key]);
      }
      print('--->  Inserted $reportName for ${data.first['date']}, version ${data.first['version']}, tab 0 successfully');
    } catch (e) {
      print('XXX ' + e.toString());
    }
  }

  Future<Null> insertTabData1(List<Map> data) async {
    if (data.isEmpty) return new Future.value(null);
    String account = data.first['account'];
    /// split the data by Asset ID, date, version
    Map groups = _groupBy(data, (Map e) =>
    new Tuple4(e['Subaccount ID'],  e['Location ID'], e['date'], e['version']));
    try {
      for (Tuple4 key in groups.keys) {
        await dbConfig.coll.remove({
          'account': account,
          'tab': 1,
          'Subaccount ID': key.item1,
          'Location ID': key.item2,
          'date': key.item3,
          'version': key.item4,
        });
        await dbConfig.coll.insertAll(groups[key]);
      }
      print('--->  Inserted $reportName for ${data.first['date']}, version ${data.first['version']}, tab 1 successfully');
    } catch (e) {
      print('XXX ' + e.toString());
    }
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
        keys: {
          'account': 1,
          'tab': 1,
          'Location ID': 1,
          'date': 1,
          'version': 1
        },
        unique: true,
        partialFilterExpression: {
          'tab': {'\$eq': 0},
        });
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'account': 1,
          'tab': 1,
          'Subaccount ID': 1,
          'Location ID': 1,
          'date': 1,
          'version': 1
        },
        unique: true,
        partialFilterExpression: {
          'Subaccount ID': {'\$exists': true},
          'tab': {'\$eq': 1},
        });
    
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
