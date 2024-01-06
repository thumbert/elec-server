library db.isoexpress.rt_system_demand_hourly;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class RtSystemDemandReportArchive extends DailyIsoExpressReport {
  // @override
  // var location = getLocation('America/New_York');

  RtSystemDemandReportArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
          host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'system_demand');
    this.dbConfig = dbConfig;
    dir ??= '${baseDir}EnergyReports/RtHourlyDemand/Raw/';
    this.dir = dir;
    reportName = 'Real-Time Hourly System Load Report';
  }
  
  
  @override
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/hourlysystemdemand?start=${yyyymmdd(asOfDate)}&end=${yyyymmdd(asOfDate)}';

  @override
  File getFilename(Date asOfDate) =>
      File('${dir}rt_hourlydemand_${yyyymmdd(asOfDate)}.csv');


  /// File may be incomplete if downloaded during the day ...
  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    var row = <String, dynamic>{};
    var localDate = (rows.first['Date'] as String).substring(0, 10);
    int numberOfHours = Date.parse(formatDate(localDate), location: location)
        .splitLeft((dt) => Hour.beginning(dt))
        .length;
    if (rows.length != numberOfHours) {
      throw mis.IncompleteReportException('$reportName for $localDate');
    }

    row['date'] = formatDate(localDate);
    row['market'] = 'RT';

    row['hourBeginning'] = [];
    row['Total Load'] = <num>[];
    for (var e in rows) {
      row['hourBeginning'].add(parseHourEndingStamp(localDate, e['Hour Ending']));
      row['Total Load'].add(e['Total Load']);
    }
    return row;
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String, dynamic>>[];
    return [converter(data)];
  }

  /// Recreate the collection from scratch.
  @override
  setupDb() async {
    await dbConfig.db.open();
    List<String?> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName)) {
      await dbConfig.coll.drop();
    }

    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'market': 1, 'date': 1}, unique: true);
    await dbConfig.db.close();
  }
}
