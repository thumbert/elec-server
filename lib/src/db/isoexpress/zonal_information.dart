library db.isoexpress.zona_information;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import '../converters.dart';
import '../lib_iso_express.dart';

class ZonalInformationArchive extends IsoExpressReport {
  ComponentConfig dbConfig;
  String dir;

  ZonalInformationArchive({this.dbConfig, this.dir}) {
    if (dbConfig == null) {
      this.dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'zonal_load';
    }
    if (dir == null)
      dir = baseDir + 'ZonalInformation/Raw/';
  }
  String reportName = 'Zonal information';
  File getFilename(int year) =>
      new File(dir + '${year.toString()}_smd_hourly.xlsx');

  /// not used
  Map converter(List<Map> rows) => rows.first;

  /// need to read all tabs
  List<Map> processFile(File file) {
    var bytes = file.readAsBytesSync();
    var decoder = new SpreadsheetDecoder.decodeBytes(bytes);
    var tabs = ['ISO NE CA', 'ME', 'NH', 'VT', 'CT', 'RI', 'SEMA', 'WCMA',
      'NEMA'];
    List<Map> data = [];
    for (var tabName in tabs) {
      print('Reading tab $tabName');
      data.addAll(_processTab(decoder, tabName));
    }
    return data;
  }

  ///
  List<Map> _processTab(SpreadsheetDecoder decoder, String tabName) {
    var table = decoder.tables[tabName];
    var keys = ['date', 'hourBeginning', 'DA_Demand', 'RT_Demand',
      'Dry_Bulb', 'Dew_Point', 'zoneName'];
    List<Map> aux = [];
    table.rows.skip(1).forEach((List row) {
      var date = Date.parse((row[0] as String).substring(0,10));
      aux.add(new Map.fromIterables(keys, [
        date.toString(),
        parseHourEndingStamp(mmddyyyy(date), row[1]),
        row[2],
        row[3],
        row[12],
        row[13],
        tabName,
      ]));
    });
    return aux;
  }

  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'zoneName': 1, 'date': 1}, unique: true);
    await dbConfig.db.close();
  }

  /// When inserting the data in the collection, check if the day has already
  /// been inserted.
  Future insertData(List<Map> data) async {
    /// group data by day
    Map dayData = _groupBy(data, (Map x) => x['date']);
    dayData.keys.forEach((String day) async {
      /// check if the day is in the db already
      if (!(await _isDayInserted(day))) {
        await dbConfig.coll.insertAll(dayData[day]);
      }
    });
  }

  /// TODO: fix me
  Future<bool> _isDayInserted(String yyyymmdd) async {
    return new Future.value(false);
  }

//  Future<Map<String, String>> lastDay() async {
//    List pipeline = [];
//    pipeline.add({
//      '\$group': {
//        '_id': 0,
//        'lastDay': {'\$max': '\$Operating Day'}
//      }
//    });
//    Map res = await dbConfig.coll.aggregate(pipeline);
//    return {'lastDay': res['result'][0]['lastDay']};
//  }

//  Date lastDayAvailable() => Date.today().subtract(4);
//  /// delete all rows for a given day
//  Future<Null> deleteDay(Date day) async {
//    return await dbConfig.coll
//        .remove(where.eq('date', day.toString()));
//  }
  updateDb() {}

  Map _groupBy(Iterable x, Function f) {
    Map result = new Map();
    x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));
    return result;
  }

}
