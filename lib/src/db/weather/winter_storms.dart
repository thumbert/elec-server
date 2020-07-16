library db.weather.winter_storms;

import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';
import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import '../lib_iso_express.dart';

/// Go to https://www.weather.gov/box/pastevents#
List<String> winterStorms() {
  return [
    'Apr_19_2018',
    'Apr_16-17_2018',
    'Apr_06_2018',
    'Apr_02_2018',
    'Mar_25_2018',
    'Mar_21-22_2018',
    'Mar_13_2018',
    'Mar_07-08_2018',
    'Mar_05_2018',
    'Mar_02-03_2018',
    'Feb_17-18_2018',
    'Feb_12_2018',
    'Feb_10_2018',
    'Feb_07_2018',
    'Feb_04_2018',
    'Feb_02_2018',
    'Feb_01_2018',
    'Jan_29-30_2018',
    'Jan_17_2018',
    'Jan_15_2018',
    'Jan_12-13_2018',
    'Jan_04_2018',
    'Dec_30_2017',
    'Dec_25_2017',
    'Dec_25_2017',
    'Dec_15-16_2017',
    'Dec_14_2017',
    'Dec_12_2017',
    'Dec_09-10_2017',
    'Mar_31-Apr_01_2017',
    'Mar_14_2017',
    'Mar_10_2017',
    'Feb_15-16_2017',
    'Feb_12-13_2017',
    'Feb_11_2017',
    'Feb_09_2017',
    'Feb_07_2017',
    'Jan_23-24_2017',
    'Jan_17-18_2017',
    'Jan_07-08_2017',
    'Jan_06_2017',
    'Jan_04_2017',
    'Dec_31-Jan_01_2016-2017',
    'Dec_29_2016',
    'Dec_27_2016',
    'Dec_22_2016',
    'Dec_17_2016',
    'Dec_12_2016',
    'Dec_07_2016',
    'Dec_05_2016',
    'Nov_20-21_2016',
    'Nov_15-16_2016',
    'Nov_11_2016',
    'Oct_27-28_2016',
    'Apr_07_2016',
    'Apr_04_2016',
    'Apr_03_2016',
    'Mar_31_2016',
    'Mar_29_2016',
    'Mar_21_2016',
    'Mar_17_2016',
    'Mar_04_2016',
    'Feb_24-25_2016',
    'Feb_23-24_2016',
    'Feb_15_2016',
    'Feb_14_2016',
    'Feb_13_2016',
    'Feb_10_2016',
    'Feb_08_2016',
    'Feb_05_2016',
    'Jan_23-24_2016',
    'Jan_19_2016',
    'Jan_17-18_2016',
    'Jan_14_2016',
    'Jan_12_2016',
    'Jan_10_2016',
    'Jan_04-05_2016',
    'Dec_28-29_2015',
    'Apr_04_2015',
    'Apr_04_2015',
    'Mar_28_2015',
    'Mar_28_2015',
    'Mar_21-22_2015',
    'Mar_17-18_2015',
    'Mar_15_2015',
    'Mar_05_2015',
    'Mar_03-04_2015',
    'Mar_01-02_2015',
    'Feb_26_2015',
    'Feb_25_2015',
    'Feb_21-22_2015',
    'Feb_18-19_2015',
    'Feb_17_2015',
    'Feb_14-15_2015',
    'Feb_07-09_2015',
    'Feb_05_2015',
    'Feb_02_2015',
    'Jan_26-27_2015',
    'Jan_24_2015',
    'Jan_22_2015',
    'Jan_19_2015',
    'Jan_12_2015',
    'Jan_09_2015',
    'Jan_05_2015',
    'Jan_03-04_2015',
    'Dec_20-21_2014',
    'Dec_10_2014',
    'Dec_10_2014',
    'Nov_28_2014',
    'Nov_26-27_2014',
    'Mar_30_2014',
    'Mar_26_2014',
    'Mar_19-20_2014',
    'Mar_12-13_2014',
    'Mar_02-03_2014',
    'Feb_19_2014',
    'Feb_18_2014',
    'Feb_15_2014',
    'Feb_13-14_2014',
    'Feb_09-10_2014',
    'Feb_05_2014',
    'Feb_03_2014',
    'Jan_29_2014',
    'Jan_25_2014',
    'Jan_21-22_2014',
    'Jan_18-19_2014',
    'Jan_02-03_2014',
    'Dec_17-18_2013',
    'Dec_14-15_2013',
    'Dec_10_2013',
    'Dec_09_2013',
  ];
}

class WinterStormsArchive extends IsoExpressReport {
  ComponentConfig dbConfig;
  String dir;
  Location location = getLocation('America/New_York');
  var _fmt = new DateFormat('M/dd/yyyy h:mm a');

  WinterStormsArchive({this.dbConfig, this.dir}) {
    dir ??= env['HOME'] + '/Downloads/Archive/Weather/WinterStorms/Raw/';
    if (dbConfig == null) {
      this.dbConfig = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'weather'
        ..collectionName = 'winter_storms';
    }
  }

  Map<String,dynamic> converter(List<Map<String,dynamic>> rows) {}

  /// SNOW total accumulation, RAIN totals (inches), and wind speeds are reported.
  ///
  List<Map<String,dynamic>> processFile(File file) {
    print(file.path);
    var aux = file.readAsStringSync();

    /// keep only the metadata lines, which start with ':'
    var lines = aux.split('\n').where((String line) => line.startsWith(':'));
    var converter = new CsvToListConverter();
    var rows = lines.map((String row) => converter.convert(row).first).toList();
    List<Map> out = [];
    List keys = [
      'date',
      'timestamp',
      'state',
      'county',
      'location',
      'type',
      'total',
      'unit',
      'comments'
    ];
    for (List row in rows) {
      if (row.length == 14) {
        /// some of the total is entered 'T', I will ignore that
        if (row[10] == 'T') continue;
//        if ((row[11] as String).trim() != 'Inch')
//          throw new StateError('Unit is not Inch.  Do something! \n$row');
        var dt = parseTimestamp(row[0], row[1]);
        out.add(new Map.fromIterables(keys, [
          new Date.fromTZDateTime(dt).toString(),
          dt,
          (row[2] as String).trim(), // state
          (row[3] as String).trim(), // county
          (row[4] as String).trim(), // location
          row[7], // latitude
          row[8], // longitude
          (row[9] as String)
              .trim(), // type: SNOW, RAIN, TSTM (thunderstorm), NON-TSTM, SUST (sustained winds).
          row[10], // total
          (row[11] as String).trim(), // unit
          (row[12] as String).trim(), // comments
        ]));
      }
    }
    return out;
  }

  /// date is ":4/19/2018", time is " 700 AM"
  TZDateTime parseTimestamp(String date, String time) {
    // need to add a : between hours and minutes!
    time = time.substring(0, 3) + ':' + time.substring(3);
    time = time.trimLeft();
    date = date.substring(1);
    var dt = _fmt.parse('$date $time');
    return new TZDateTime.from(dt, location);
  }

  /// Check if this storm has been inserted already.  Should be a fast check.
  Future<bool> isStormInserted(String stormId) {
    return dbConfig.coll.count({'stormId': stormId}).then((res) {
      if (res == 0) return false;
      return true;
    });
  }

  Future<Null> setupDb() async {
    await dbConfig.db.open();
    List<String> collections = await dbConfig.db.getCollectionNames();
    if (collections.contains(dbConfig.collectionName))
      await dbConfig.coll.drop();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'stormId': 1}, unique: true);
    await dbConfig.db.close();
  }

  /// Update the db by going through the list of storms, downloading them and
  /// inserting them into the db.
  Future<Null> updateDb() async {
    List stormIds = winterStorms();
    for (String stormId in stormIds.take(3)) {
      bool inDb = await isStormInserted(stormId);
      if (!inDb) {
        var url = _makeUrl(stormId);
        var file = new File(_makeUrl(stormId, base: dir));
        if (!file.existsSync()) await downloadUrl(url, file);
        var rows = processFile(file);
        rows.forEach(print);
      }
    }
  }

  /// Construct the url to download from the stormId.  A stormId is the
  /// dates in the required format, as returned by winterStorms()
  String _makeUrl(String stormId, {String base}) {
    base ??=
        'https://www.weather.gov/source/box/ClimatePastWeather/pastevents/';
    return base + '$stormId/${stormId}_Text_Xml.xml';
  }
}

String url =
    'https://www.weather.gov/source/box/ClimatePastWeather/pastevents/Jan_12-13_2018/Jan_12-13_2018_Text_Xml.xml';
