library db.isoexpress.rt_system_demand_hourly;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class RtSystemDemandReportArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;
  String dir;
  var location = getLocation('US/Eastern');

  RtSystemDemandReportArchive({this.dbConfig, this.dir}) {
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'system_demand';
    }
    if (dir == null) dir = baseDir + 'EnergyReports/RtHourlyDemand/Raw/';
  }
  String reportName = 'Real-Time Hourly System Load Report';
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/hourlysystemdemand?start=' +
      yyyymmdd(asOfDate) +
      '&end=' +
      yyyymmdd(asOfDate);
  File getFilename(Date asOfDate) =>
      new File(dir + 'rt_hourlydemand_' + yyyymmdd(asOfDate) + '.csv');

  /// File may be incomplete if downloaded during the day ...
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = <String, dynamic>{};
    var localDate = (rows.first['Date'] as String).substring(0, 10);
    int numberOfHours = Date.parse(formatDate(localDate), location: location)
        .splitLeft((dt) => new Hour.beginning(dt))
        .length;
    if (rows.length != numberOfHours)
      throw new mis.IncompleteReportException('$reportName for $localDate');

    row['date'] = formatDate(localDate);
    row['market'] = 'RT';

    row['hourBeginning'] = [];
    row['Total Load'] = <num>[];
    rows.forEach((e) {
//      var hb = parseHourEndingStamp(localDate, e['Hour Ending']);
//      row['hourBeginning'].add(TZDateTime.fromMillisecondsSinceEpoch(
//              location, hb.millisecondsSinceEpoch)
//          .toIso8601String());
      row['hourBeginning'].add(parseHourEndingStamp(localDate, e['Hour Ending']));
      row['Total Load'].add(e['Total Load']);
    });
    return row;
  }

  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];
    return [converter(data)];
  }

  /// Check if this date is in the db already
  Future<bool> hasDay(Date date) async {
    var res =
        await dbConfig.coll.findOne({'market': 'RT', 'date': date.toString()});
    if (res == null || res.isEmpty) return false;
    return true;
  }

  /// Recreate the collection from scratch.
  setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'market': 1, 'date': 1}, unique: true);
    await dbConfig.db.close();
  }

  Future<Map<String, String>> lastDay() async {
    List pipeline = [];
    pipeline.add({
      '\$group': {
        '_id': 0,
        'lastDay': {'\$max': '\$date'}
      }
    });
    Map res = await dbConfig.coll.aggregate(pipeline);
    return {'lastDay': res['result'][0]['lastDay']};
  }

  Date lastDayAvailable() => Date.today().subtract(2);
  Future<Null> deleteDay(Date day) async {
    return await dbConfig.coll.remove(where.eq('date', day.toString()));
  }
}
