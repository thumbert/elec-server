library db.isoexpress.da_clearead_demand_hourly;

import 'dart:io';
import 'dart:async';
import 'package:func/func.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';


class DaClearedDemandReportArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;

  DaClearedDemandReportArchive({this.dbConfig}) {
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'system_demand'
        ..DIR = baseDir + 'EnergyReports/DaHourlyDemand/Raw/';
    }
  }
  String reportName =
      'Day-Ahead Energy Market Hourly Demand Report';
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/hourlydayaheaddemand?start=' +
          yyyymmdd(asOfDate) +
          '&end=' +
          yyyymmdd(asOfDate);
  File getFilename(Date asOfDate) => new File(dbConfig.DIR +
      'da_hourlydemand_' +
      yyyymmdd(asOfDate) +
      '.csv');

  Func1<List<Map>,Map> converter = (List<Map> rows) {
    Map row = rows.first;
    var localDate = (row['Date'] as String).substring(0,10);
    var hourEnding = row['Hour Ending'];
    row['hourBeginning'] = parseHourEndingStamp(localDate, hourEnding);
    row['date'] = formatDate(localDate);
    row['market'] = 'DA';
    row.remove('Date');
    row.remove('Hour Ending');
    row.remove('H');
    return row;
  };
  List<Map> processFile(File file) {
    List<Map> data = mis.readReportTabAsMap(file, tab: 0);
    data.forEach((row) => converter([row]));
    return data;
  }

  /// Recreate the collection from scratch.
  setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName)) await dbConfig.coll.drop();

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'market': 1, 'hourBeginning': 1}, unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1, 'market': 1});
    await dbConfig.db.close();
  }

  Future<Map<String,String>> lastDay() async {
    List pipeline = [];
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
