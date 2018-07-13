library db.isoexpress.da_lmp_hourly;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class DaLmpHourlyArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;
  String dir;

  DaLmpHourlyArchive({this.dbConfig, this.dir}) {
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'da_lmp_hourly';
    }
    if (dir == null)
      dir = baseDir + 'PricingReports/DaLmpHourly/Raw/';

  }
  String reportName = 'Day-Ahead Energy Market Hourly LMP Report';
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/static-transform/csv/histRpts/da-lmp/' +
      'WW_DALMP_ISO_' + yyyymmdd(asOfDate) + '.csv';
  File getFilename(Date asOfDate) =>
      new File(dir + 'WW_DALMP_ISO_' + yyyymmdd(asOfDate) + '.csv');

  Map converter(List<Map> rows) {
    Map row = {};
    row['date'] = formatDate(rows.first['Date']);
    row['ptid'] = int.parse(rows.first['Location ID']);
    row['hourBeginning'] = [];
    row['congestion'] = [];
    row['lmp'] = [];
    row['marginal_loss'] = [];
    rows.forEach((e) {
      row['hourBeginning'].add(parseHourEndingStamp(e['Date'], e['Hour Ending']));
      row['lmp'].add(e['Locational Marginal Price']);
      row['congestion'].add(e['Congestion Component']);
      row['marginal_loss'].add(e['Marginal Loss Component']);
    });
    return row;
  }

  List<Map> processFile(File file) {
    List<Map> data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return [];
    Map dataByPtids = _groupBy(data, (row) => row['Location ID']);
    return dataByPtids.keys.map((ptid) => converter(dataByPtids[ptid])).toList();
  }

  /// Check if this date is in the db already
  Future<bool> hasDay(Date date) async {
    var res = await dbConfig.coll.findOne({'date': date.toString()});
    if (res == null || res.isEmpty) return false;
    return true;
  }


  /// Recreate the collection from scratch.
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'ptid': 1,
          'date': 1,
        },
        unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1});
    await dbConfig.db.close();
  }

  Future<Map<String,String>> lastDay() async {
    List pipeline = [];
    pipeline.add({'\$match': {'ptid': {'\$eq': 4000}}});
    pipeline.add({'\$group': {
      '_id': 0,
      'lastDay': {'\$max': '\$date'}}});
    Map res = await dbConfig.coll.aggregate(pipeline);
    return {'lastDay': res['result'][0]['lastDay']};
  }

  Date lastDayAvailable() => Date.today().next;
  Future<Null> deleteDay(Date day) async {
    return await dbConfig.coll.remove(where.eq('date', day.toString()));
  }


}


Map _groupBy(Iterable x, Function f) {
  Map result = new Map();
  x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));
  return result;
}
