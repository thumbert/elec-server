library db.isoexpress.zona_information;

import 'dart:io';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import '../converters.dart';
import '../lib_iso_express.dart';

class ZonalDemandArchive extends IsoExpressReport {

  ZonalDemandArchive({ComponentConfig? dbConfig, String? dir}) {
    dbConfig ??= ComponentConfig(
          host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'zonal_demand');
    this.dbConfig = dbConfig;
    dir ??= baseDir + 'PricingReports/ZonalInformation/Raw/';
    this.dir = dir;
  }
  @override
  String reportName = 'Zonal information';
  File getFilename(int year) =>
      File(dir + '${year.toString()}_smd_hourly.xlsx');

  /// not used
  @override
  Map<String,dynamic> converter(List<Map<String,dynamic>> rows) => rows.first;

  /// Read all tabs (all zones).  The output of this function gets inserted
  /// in the database.
  @override
  List<Map<String,dynamic>> processFile(File file) {
    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);
    var canonicalTabs = ['ISONE', 'ME', 'NH', 'VT', 'CT', 'RI', 'SEMA', 'WCMA',
      'NEMA'];
    var data = <Map<String,dynamic>>[];
    for (var zoneName in canonicalTabs) {
      data.addAll(_processTab(decoder, zoneName));
    }
    return data;
  }

  /// Return one document for each day.
  /// {'date': '2011-01-01', 'zoneName': 'ISONE',
  ///  'hourBeginning': [..24-element array..],
  ///  'DA_Demand': [..24-element array..], ...}
  List<Map<String,dynamic>> _processTab(SpreadsheetDecoder decoder, String zoneName) {
    /// tab names change from year to year, so normalize them
    var tabs = decoder.tables.keys;
    var tabName = tabs.firstWhere((t) => t.startsWith(zoneName.substring(0,2)));
    print('Reading tab $tabName');
    var table = decoder.tables[tabName]!;
    var keys = ['date', 'hourBeginning', 'DA_Demand', 'RT_Demand',
      'DryBulb', 'DewPoint', 'zoneName'];
    var aux = <Map<String,dynamic>>[];
    table.rows.skip(1).forEach((List row) {
      Date date;
      if (row[0] is int) {  // for years 2011-2016
        date = _convertXlsxDate(row[0]);
      } else { // for years 2017+
        date = Date.parse((row[0] as String).substring(0,10));
      }
      aux.add(Map.fromIterables(keys, [
        date.toString(),
        parseHourEndingStamp(mmddyyyy(date), stringHourEnding(row[1])!),
        row[2],
        row[3],
        row[12],
        row[13],
        zoneName,
      ]));
    });
    /// group the data by date and zone
    var byDay = groupBy(aux, (Map x) => x['date']);
    var out = <Map<String,dynamic>>[];
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

  @override
  Future<Null> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'zoneName': 1, 'date': 1}, unique: true);
    await dbConfig.db.close();
  }

  /// Remove data for existing day.  Input data should contain all zones for a
  /// given day, that is, don't try to insert one zone at a time.
  @override
  Future insertData(List<Map<String,dynamic>> data) async {
    /// group data by day
    var dayData = groupBy(data, (Map x) => x['date']);
    for (String? day in dayData.keys as Iterable<String?>) {
      await dbConfig.coll.remove({'date': day});
      await dbConfig.coll.insertAll(dayData[day]!);
      print('Inserted day $day successfully in isoexpress/zonal_demand');
    }
  }

  Future downloadYear(int year) async {
    var url = _urls[year];
    await downloadUrl(url, getFilename(year));
  }

  final _urls = <int,String>{
    2021: 'https://www.iso-ne.com/static-assets/documents/2020/02/2021_smd_hourly.xlsx',
    2020: 'https://www.iso-ne.com/static-assets/documents/2020/02/2020_smd_hourly.xlsx',
    2019: 'https://www.iso-ne.com/static-assets/documents/2019/02/2019_smd_daily.xlsx',
    2018: 'https://www.iso-ne.com/static-assets/documents/2018/02/2018_smd_hourly.xlsx',
    2017: 'https://www.iso-ne.com/static-assets/documents/2017/02/2017_smd_hourly.xlsx',
    2016: 'https://www.iso-ne.com/static-assets/documents/2016/02/smd_hourly.xls',
    2015: 'https://www.iso-ne.com/static-assets/documents/2015/02/smd_hourly.xls',
    2014: 'https://www.iso-ne.com/static-assets/documents/2015/05/2014_smd_hourly.xls',
    2013: 'https://www.iso-ne.com/static-assets/documents/markets/hstdata/znl_info/hourly/2013_smd_hourly.xls',
    2012: 'https://www.iso-ne.com/static-assets/documents/markets/hstdata/znl_info/hourly/2012_smd_hourly.xls',
    2011: 'https://www.iso-ne.com/static-assets/documents/markets/hstdata/znl_info/hourly/2011_smd_hourly.xls',
  };

  Date _convertXlsxDate(num x) {
    var aux = DateTime.fromMillisecondsSinceEpoch(((x - 25569) * 86400000).round(),
        isUtc: true);
    return Date(aux.year, aux.month, aux.day, location: location);
  }

}

