library db.isoexpress.monthly_wholesale_load_cost;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:tuple/tuple.dart';
import 'package:timezone/timezone.dart';
import '../lib_mis_reports.dart' as mis;
import '../converters.dart';
import '../lib_iso_express.dart';

class WholesaleLoadCostReportArchive extends IsoExpressReport {
  @override
  ComponentConfig dbConfig;
  String dir;
  @override
  final String reportName = 'Monthly Wholesale Load Cost Report';
  final _setEq = const SetEquality();
  static final location = getLocation('America/New_York');


  WholesaleLoadCostReportArchive({this.dbConfig, this.dir}) {
    dbConfig ??= ComponentConfig()
      ..host = '127.0.0.1'
      ..dbName = 'isoexpress'
      ..collectionName = 'wholesale_load_cost';
    dir ??= baseDir + 'WholesaleLoadCost/Raw/';
  }


  String getUrl(Month month, int ptid) =>
      'https://www.iso-ne.com/transform/csv/whlsecost/hourly?month='
          '${month.toIso8601String().replaceAll('-', '')}&locationId=$ptid';

  File getFilename(Month month, int ptid) =>
      File(dir + 'whlsecost_hourly_$ptid' + '_' +
          '${month.toIso8601String().replaceAll('-', '')}.csv');

  void downloadFile(Month month, int ptid) async =>
      await downloadUrl(getUrl(month, ptid), getFilename(month, ptid), overwrite: true);

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = rows.first;
    var date = formatDate(row['Local Date']);
    return <String,dynamic>{
      'date': date,
      'ptid': row['Location ID'],
      'rtLoad': rows.map((e) => e['RTLO'] as num).toList()
    };
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];
    var dataByDate = groupBy(data, (row) => row['Local Date']);
    var out = dataByDate.keys
        .map((date) => converter(dataByDate[date]))
        .toList();
    return out;
  }


  /// Can insert more than one zone and date at a time.
  @override
  Future insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(null);
    /// split data by ptid and date
    var groups = groupBy(data, (e) => Tuple2(e['ptid'] as int, e['date'] as String));
    try {
      for (var key in groups.keys) {
        await dbConfig.coll.remove({
          'ptid': key.item1,
          'date': key.item2,
        });
        await dbConfig.coll.insertAll(groups[key]);
      }
      var month = (data.first['date'] as String).substring(0,7);
      print('--->  Inserted $reportName for month '
          '${month}, ptid ${data.first['ptid']}');
    } catch (e) {
      print('XXX ' + e.toString());
    }
  }


  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'ptid': 1, 'date': 1,}, unique: true);
    await dbConfig.db.close();
  }
}
