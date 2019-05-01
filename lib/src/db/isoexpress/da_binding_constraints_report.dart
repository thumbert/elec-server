library db.isoexpress.da_binding_constraints_report;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:date/date.dart';
import 'package:table/table.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_mis_reports.dart' as mis;
import '../lib_iso_express.dart';
import '../converters.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

class DaBindingConstraintsReportArchive extends DailyIsoExpressReport {
  ComponentConfig dbConfig;
  String dir;
  static const _rowEquality = const MapEquality<String,dynamic>();

  DaBindingConstraintsReportArchive({this.dbConfig, this.dir}) {
    if (dbConfig == null) {
      dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'binding_constraints';
    }
    dir ??= baseDir + 'GridReports/DaBindingConstraints/Raw/';
  }
  String reportName =
      'Day-Ahead Energy Market Hourly Final Binding Constraints Report';

  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/hourlydayaheadconstraints?start=' +
      yyyymmdd(asOfDate) +
      '&end=' +
      yyyymmdd(asOfDate);
  File getFilename(Date asOfDate) => new File(
      dir + 'da_binding_constraints_final_' + yyyymmdd(asOfDate) + '.csv');

  Map<String,dynamic> converter(List<Map<String,dynamic>> rows) {
    var row = rows.first;
    var localDate = (row['Local Date'] as String).substring(0, 10);
    var hourEnding = row['Hour Ending'];
    row['hourBeginning'] = parseHourEndingStamp(localDate, hourEnding);
    row['market'] = 'DA';
    row['date'] = formatDate(localDate);
    row.remove('Local Date');
    row.remove('Hour Ending');
    row.remove('H');
    return row;
  }

  /// Need to take the unique rows.  On 2018-07-10, there were duplicates!
  List<Map<String,dynamic>> processFile(File file) {
    var data = mis.readReportTabAsMap(file, tab: 0);
    if (data.isEmpty) return <Map<String,dynamic>>[];
    data.forEach((row) => converter([row]));
    var uRows = unique(data).cast<Map<String,dynamic>>();
    return uRows;
  }

  /// Read the report from the disk, and insert the data into the database.
  /// If the processing of the file throws an IncompleteReportException
  /// delete the file associated with this day.
  Future<int> insertDay(Date day) async {
    File file = getFilename(day);
    var data;
    try {
      data = processFile(file);
      if (data.isEmpty) return new Future.value(null);
    } on mis.IncompleteReportException {
      file.delete();
      return new Future.value(null);
    }
    await dbConfig.coll.remove({'date': day.toString()});
    return dbConfig.coll
        .insertAll(data)
        .then((_) {
          print('--->  Inserted ${reportName} for day ${day}');
          return 0;
        })
        .catchError((e) {
          print('xxxx ERROR xxxx ' + e.toString());
          return 1;
    });
  }

  /// Check if this date is in the db already
  Future<bool> hasDay(Date date) async {
    var res = await dbConfig.coll.findOne({
      'date': date.toString(), 
      'market': 'DA'
    });
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
        keys: {'Constraint Name': 1, 'market': 1});
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'date': 1, 'market': 1});
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

  Date lastDayAvailable() => Date.today();
  Future<Null> deleteDay(Date day) async {
    return await dbConfig.coll.remove(where.eq('date', day.toString()));
  }
}
