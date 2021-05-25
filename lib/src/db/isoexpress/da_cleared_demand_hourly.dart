library db.isoexpress.da_clearead_demand_hourly;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class DaClearedDemandReportArchive extends DailyIsoExpressReport {

  DaClearedDemandReportArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
          host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'system_demand');
    this.dbConfig = dbConfig;
    dir ??= baseDir + 'EnergyReports/DaHourlyDemand/Raw/';
    this.dir = dir;
  }
  @override
  String reportName = 'Day-Ahead Energy Market Hourly Demand Report';
  @override
  String getUrl(Date? asOfDate) =>
      'https://www.iso-ne.com/transform/csv/hourlydayaheaddemand?start=' +
      yyyymmdd(asOfDate) +
      '&end=' +
      yyyymmdd(asOfDate);
  @override
  File getFilename(Date? asOfDate) =>
      File(dir + 'da_hourlydemand_' + yyyymmdd(asOfDate) + '.csv');

  @override
  Map<String,dynamic> converter(List<Map<String,dynamic>> rows) {
    var row = <String,dynamic>{};
    var localDate = (rows.first['Date'] as String).substring(0, 10);
    row['date'] = formatDate(localDate);
    row['market'] = 'DA';
    row['hourBeginning'] = [];
    row['Day-Ahead Cleared Demand'] = [];
    rows.forEach((e) {
      row['hourBeginning'].add(parseHourEndingStamp(localDate,
        e['Hour Ending']));
      row['Day-Ahead Cleared Demand'].add(e['Day-Ahead Cleared Demand']);
    });
    return row;
  }

  @override
  List<Map<String,dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String,dynamic>>[];
    return [converter(data)];
  }

  /// Check if this date is in the db already
  Future<bool> hasDay(Date date) async {
    var res = await dbConfig.coll.findOne({
      'market': 'DA',
      'date': date.toString()});
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
        keys: {'market': 1, 'date': 1}, unique: true);
    await dbConfig.db.close();
  }

  Future<Map<String, String?>> lastDay() async {
    var pipeline = [];
    pipeline.add({
      '\$group': {
        '_id': 0,
        'lastDay': {'\$max': '\$date'}
      }
    });
    Map res = await dbConfig.coll.aggregate(pipeline);
    return {'lastDay': res['result'][0]['lastDay']};
  }

  // Date lastDayAvailable() => Date.today().next;

  Future<Null> deleteDay(Date day) async {
    return await (dbConfig.coll.remove(where.eq('date', day.toString())) as FutureOr<Null>);
  }
}

