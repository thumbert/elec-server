library db.mis.sd_datransact;

import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart' as mis;
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'package:timezone/timezone.dart';

class SdDaTransactArchive extends mis.MisReportArchive {
  SdDaTransactArchive({ComponentConfig? dbConfig}) {
    reportName = 'SD_DATRANSACT';
    dbConfig ??= ComponentConfig(
        host: '127.0.0.1',
        dbName: 'mis',
        collectionName: reportName.toLowerCase());
    this.dbConfig = dbConfig;
  }

  @override
  Future<int> insertTabData(List<Map<String, dynamic>> data,
      {int tab = 0}) async {
    if (data.isEmpty) return Future.value(null);
    var account = data.first['account'];
    var tab = data.first['tab'];
    var date = data.first['date'];
    var version = data.first['version'];
    try {
      await dbConfig.coll.remove({
        'account': account,
        'tab': tab,
        'date': date,
        'version': version,
      });
      await dbConfig.coll.insertAll(data);
      print(
          '--->  Inserted $reportName for $date, version $version, tab $tab successfully');
      return Future.value(0);
    } catch (e) {
      print('XXX ' + e.toString());
      return Future.value(1);
    }
  }

  /// keep each row as a document, mostly as is
  List<Map<String, dynamic>> rowConverter0(
      List<Map> rows, String account, Date reportDate, String version) {
    var out = <Map<String, dynamic>>[];
    var columns = <String>[
      'ISO-NE Schedule ID',
      'Transaction Type',
      'Originating Location ID',
      'Destination Location ID',
      'Delivered Amount',
      'Up To Congestion',
      'Subaccount Name'
    ];
    for (var row in rows) {
      var aux = <String, dynamic>{};
      aux['account'] = account; // index
      aux['tab'] = 0; // index
      aux['date'] = reportDate.toString(); // index
      aux['version'] = version;
      var _hb =
          parseHourEndingStamp(mmddyyyy(reportDate), row['Trading Interval']);
      var hbL = TZDateTime.fromMillisecondsSinceEpoch(
          location, _hb.millisecondsSinceEpoch);
      aux['hourBeginning'] = hbL.toIso8601String();
      for (var column in columns) {
        aux[column] = row[column];
      }
      out.add(aux);
    }
    return out;
  }

  List<Map<String, dynamic>> rowConverter1(
      List<Map> rows, String account, Date reportDate, String version) {
    var out = <Map<String, dynamic>>[];
    var columns = <String>[
      'Transaction Number',
      'Reference ID',
      'Transaction Type',
      'Other Party',
      'Settlement Location ID',
      'Amount',
      'Impacts Marginal Loss Revenue Allocation',
      'Subaccount Name',
    ];
    for (var row in rows) {
      var aux = <String, dynamic>{};
      aux['account'] = account;
      aux['tab'] = 1;
      aux['date'] = reportDate.toString();
      aux['version'] = version;
      var _hb =
          parseHourEndingStamp(mmddyyyy(reportDate), row['Trading Interval']);
      var hbL = TZDateTime.fromMillisecondsSinceEpoch(
          location, _hb.millisecondsSinceEpoch);
      aux['hourBeginning'] = hbL.toIso8601String();
      for (var column in columns) {
        aux[column] = row[column];
      }
      out.add(aux);
    }
    return out;
  }

  /// Tab 0 is for external transactions
  /// Tab 1 is for internal bilateral transactions
  @override
  Map<int, List<Map<String, dynamic>>> processFile(File file) {
    var report = mis.MisReport(file);
    var account = report.accountNumber();
    var reportDate = report.forDate();
    var version = report.timestamp().toIso8601String();

    var aux0 = mis.readReportTabAsMap(file, tab: 0);
    var data0 = rowConverter0(aux0, account, reportDate, version).toList();

    var aux1 = mis.readReportTabAsMap(file, tab: 1);
    var data1 = rowConverter1(aux1, account, reportDate, version).toList();

    return {0: data0, 1: data1};
  }

  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'account': 1, 'tab': 1, 'date': 1, 'version': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {
      'account': 1,
      'tab': 1,
      'date': 1,
      'referenceId': 1
    }, partialFilterExpression: {
      'referenceId': {'\$exists': true},
      'tab': {'\$eq': 1}
    });
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {
      'account': 1,
      'tab': 1,
      'date': 1,
      'otherParty': 1
    }, partialFilterExpression: {
      'otherParty': {'\$exists': true},
      'tab': {'\$eq': 1}
    });
    await dbConfig.db.close();
  }

  Future<Null> updateDb() async {
    return null;
  }
}
