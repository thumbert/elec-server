library db.isoexpress.zona_information;

import 'dart:io';
import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import '../converters.dart';
import '../lib_iso_express.dart';

class ZonalDemandArchive extends IsoExpressReport {
  ComponentConfig dbConfig;
  String dir;
  Location location = getLocation('America/New_York');

  ZonalDemandArchive({this.dbConfig, this.dir}) {
    if (dbConfig == null) {
      this.dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'zonal_demand';
    }
    if (dir == null)
      dir = baseDir + 'PricingReports/ZonalInformation/Raw/';
  }
  String reportName = 'Zonal information';
  File getFilename(int year) =>
      new File(dir + '${year.toString()}_smd_hourly.xlsx');

  /// not used
  Map<String,dynamic> converter(List<Map<String,dynamic>> rows) => rows.first;

  /// need to read all tabs
  List<Map<String,dynamic>> processFile(File file) {
    var bytes = file.readAsBytesSync();
    var decoder = new SpreadsheetDecoder.decodeBytes(bytes);
    var canonicalTabs = ['ISONE', 'ME', 'NH', 'VT', 'CT', 'RI', 'SEMA', 'WCMA',
      'NEMA'];
    List<Map> data = [];
    for (var zoneName in canonicalTabs) {
      data.addAll(_processTab(decoder, zoneName));
    }
    return data;
  }

  /// Return one document for each day.
  /// {'date': '2011-01-01', 'zoneName': 'ISONE',
  ///  'hourBeginning': [..24-element array..],
  ///  'DA_Demand': [..24-element array..], ...}
  List<Map> _processTab(SpreadsheetDecoder decoder, String zoneName) {
    /// tab names change from year to year, so normalize them
    var tabs = decoder.tables.keys;
    var tabName = tabs.firstWhere((t) => t.startsWith(zoneName.substring(0,2)));
    print('Reading tab $tabName');
    var table = decoder.tables[tabName];
    var keys = ['date', 'hourBeginning', 'DA_Demand', 'RT_Demand',
      'DryBulb', 'DewPoint', 'zoneName'];
    List<Map> aux = [];
    table.rows.skip(1).forEach((List row) {
      Date date;
      if (row[0] is int) {  // for years 2011-2016
        date = _convertXlsxDate(row[0]);
      } else { // for years 2017+
        date = Date.parse((row[0] as String).substring(0,10));
      }
      aux.add(new Map.fromIterables(keys, [
        date.toString(),
        parseHourEndingStamp(mmddyyyy(date), stringHourEnding(row[1])),
        row[2],
        row[3],
        row[12],
        row[13],
        zoneName,
      ]));
    });
    /// group the data by date and zone
    var byDay = _groupBy(aux, (Map x) => x['date']);
    var out = <Map>[];
    byDay.forEach((k, List<Map> v) {
      var one = {
        'date': v.first['date'],
        'zoneName': v.first['zoneName'],
        'hourBeginning': [],
        'DA_Demand': [],
        'RT_Demand': [],
        'DryBulb': [],
        'DewPoint': [],
      };
      v.forEach((Map e) {
        one['hourBeginning'].add(e['hourBeginning']);
        one['DA_Demand'].add(e['DA_Demand']);
        one['RT_Demand'].add(e['RT_Demand']);
        one['DryBulb'].add(e['DryBulb']);
        one['DewPoint'].add(e['DewPoint']);
      });
      out.add(one);
    });

    return out;
  }

  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'date': 1, 'zoneName': 1}, unique: true);
    await dbConfig.db.close();
  }

  /// When inserting the data in the collection, check if data for this day
  /// has already been inserted.  Don't reinsert it.
  Future insertData(List<Map> data) async {
    /// group data by day
    Map dayData = _groupBy(data, (Map x) => x['date']);
    for (String day in dayData.keys) {
      var yesNo = await isDayInserted(day);
      if (yesNo == false) {
        await dbConfig.coll.insertAll(dayData[day]);
      }
    }
  }

  /// Check if this day has been inserted already.  Should be a fast check.
  Future<bool> isDayInserted(String day) {
    return dbConfig.coll.count({'date': day}).then((res) {
      if (res == 0) return false;
      return true;
    });
  }

  Future downloadYear(int year) async {
    String url = _urls[year];
    await downloadUrl(url, getFilename(year));
  }

  updateDb() {}

  Map<dynamic,List<Map>> _groupBy(Iterable x, Function f) {
    Map result = new Map();
    x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));
    return result;
  }

  Map<int,String> _urls = {
    2018: 'https://www.iso-ne.com/static-assets/documents/2018/02/2018_smd_hourly.xlsx',
    2017: 'https://www.iso-ne.com/static-assets/documents/2017/02/2017_smd_hourly.xlsx',
  };

  Date _convertXlsxDate(num x) {
    var aux = new DateTime.fromMillisecondsSinceEpoch(((x - 25569) * 86400000).round(),
        isUtc: true);
    return new Date(aux.year, aux.month, aux.day, location: location);
  }

}

