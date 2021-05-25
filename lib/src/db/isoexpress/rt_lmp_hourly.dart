library db.isoexpress.rt_lmp_hourly;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:timezone/timezone.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class RtLmpHourlyArchive extends DailyIsoExpressReport {

  RtLmpHourlyArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
          host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'rt_lmp_hourly');
    this.dbConfig = dbConfig;
    dir ??= baseDir + 'PricingReports/RtLmpHourly/Raw/';
    this.dir = dir;
  }
  @override
  String reportName = 'Real-Time Energy Market Hourly LMP Report';
  @override
  String getUrl(Date? asOfDate) =>
      'https://www.iso-ne.com/static-transform/csv/histRpts/rt-lmp/'
          'lmp_rt_final_' +
      yyyymmdd(asOfDate) +
      '.csv';
  @override
  File getFilename(Date? asOfDate) =>
      File(dir + 'lmp_rt_final_' + yyyymmdd(asOfDate) + '.csv');

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = <String, dynamic>{};
    row['date'] = formatDate(rows.first['Date']);
    row['ptid'] = int.parse(rows.first['Location ID']);
    row['hourBeginning'] = [];
    row['congestion'] = [];
    row['lmp'] = [];
    row['marginal_loss'] = [];
    rows.forEach((e) {
      row['hourBeginning'].add(
          parseHourEndingStamp(e['Date'], stringHourEnding(e['Hour Ending'])!));
      row['lmp'].add(e['Locational Marginal Price']);
      row['congestion'].add(e['Congestion Component']);
      row['marginal_loss'].add(e['Marginal Loss Component']);
    });
    return row;
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];
    var dataByPtids = groupBy(data, (dynamic row) => row['Location ID']);
    return dataByPtids.keys
        .map((ptid) => converter(dataByPtids[ptid]!))
        .toList();
  }

  /// Check if this date is in the db already
  Future<bool> hasDay(Date date) async {
    var res = await dbConfig.coll.findOne({'date': date.toString()});
    if (res == null || res.isEmpty) return false;
    return true;
  }

  /// Recreate the collection from scratch.
  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    // List<String?> collections = await dbConfig.db.getCollectionNames();
    // if (collections.contains(dbConfig.collectionName))
    //   await dbConfig.coll.drop();

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {
          'ptid': 1,
          'date': 1,
        },
        unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'date': 1});
    await dbConfig.db.close();
  }

  Future<Map<String, String?>> lastDay() async {
    var pipeline = [];
    pipeline.add({
      '\$match': {
        'ptid': {'\$eq': 4000}
      }
    });
    pipeline.add({
      '\$group': {
        '_id': 0,
        'lastDay': {'\$max': '\$date'}
      }
    });
    Map res = await dbConfig.coll.aggregate(pipeline);
    return {'lastDay': res['result'][0]['lastDay']};
  }

  Date lastDayAvailable() => Date.today(location: UTC).next;
  Future<Null> deleteDay(Date day) async {
    return await (dbConfig.coll.remove(where.eq('date', day.toString()))
        as FutureOr<Null>);
  }
}
