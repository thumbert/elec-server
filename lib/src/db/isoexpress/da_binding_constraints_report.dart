library db.isoexpress.da_binding_constraints_report;

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


class DaBindingConstraintsReportArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;
  String dir;

  DaBindingConstraintsReportArchive({this.dbConfig, this.dir}) {
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'binding_constraints';
    }
    if (dir == null)
      dir = baseDir + 'GridReports/DaBindingConstraints/Raw/';
  }
  String reportName =
      'Day-Ahead Energy Market Hourly Final Binding Constraints Report';
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/hourlydayaheadconstraints?start=' +
          yyyymmdd(asOfDate) +
          '&end=' +
          yyyymmdd(asOfDate);
  File getFilename(Date asOfDate) => new File(dir +
      'da_binding_constraints_final_' + yyyymmdd(asOfDate) +
      '.csv');

  Func1<List<Map>,Map> converter = (List<Map> rows) {
    Map row = rows.first;
    var localDate = (row['Local Date'] as String).substring(0,10);
    var hourEnding = row['Hour Ending'];
    row['hourBeginning'] = parseHourEndingStamp(localDate, hourEnding);
    row['market'] = 'DA';
    row['date'] = formatDate(localDate);
    row.remove('Local Date');
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
        keys: {'hourBeginning': 1, 'Constraint Name': 1, 'Contingency Name': 1, 'market': 1}, unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'Constraint Name': 1, 'market': 1});
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'date': 1, 'market': 1});
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