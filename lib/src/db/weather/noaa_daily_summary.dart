import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:elec_server/src/db/config.dart';
import 'package:collection/collection.dart';

class NoaaDailySummaryArchive extends IsoExpressReport {
  NoaaDailySummaryArchive({ComponentConfig? dbConfig, String? dir}) {
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1',
            dbName: 'weather',
            collectionName: 'noaa_daily_summary');
    this.dir = dir ??
        '${Platform.environment['HOME']}/Downloads/Archive/Weather/Noaa/DailySummary/Raw/';
  }

  mongo.Db get db => dbConfig.db;

  /// Get the url to download daily min/max temperatures for a given station.
  /// Boston: USW00014739
  /// If units = 'metric', return the data in Celsius, if units = 'standard'
  /// return the data in Fahrenheit.
  /// https://www.ncei.noaa.gov/support/access-data-service-api-user-documentation
  /// An example of how to get temperature for BOS
  /// https://www.ncei.noaa.gov/access/services/data/v1?dataset=daily-summaries&dataTypes=TMIN,TMAX&stations=USW00014739&startDate=2021-01-01&endDate=2021-12-31&format=csv&units=standard&includeStationName=false
  /// https://www.ncei.noaa.gov/access/services/data/v1?dataset=global-summaries&dataTypes=TMIN,TMAX&stations=USW00014739&startDate=2021-01-01&endDate=2021-12-31&includeAttributes=true&format=json
  String getUrl(String stationId, Date start, Date end) {
    return 'https://www.ncei.noaa.gov/access/services/data/v1?dataset=daily-summaries&dataTypes=TMIN,TMAX&stations=$stationId&startDate=$start&endDate=$end&format=csv&units=standard&includeStationName=false';
  }

  File getFilename(String stationId) => File('$dir$stationId.csv');

  /// Insert/Update a list of documents into the db.
  /// Input [data] should contain entire years only except for current year
  /// Only ONE stationId at a time!
  /// One document for stationId, year.  For example:
  /// ```
  ///   {
  ///     'stationId': 'USW00014739',
  ///     'year': 2021,
  ///     'tMin': [-1.6, 0, -1.6, -0.5, ...],  // one entry per day
  ///     'tMax': [2.2, 5.6, 2.2, 3.9, ...],
  ///   }
  /// ```
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    try {
      var stationId = data.first['stationId'] as String;
      for (var x in data) {
        if (x['stationId'] != stationId) {
          throw StateError('Only one stationId is allowed at a time!');
        }
        await dbConfig.coll.remove({
          'stationId': x['stationId'],
          'year': x['year'],
        });
        await dbConfig.coll.insert(x);
      }
      print('--->  Inserted stationId $stationId successfully');
    } catch (e) {
      print('XXX $e');
      return Future.value(1);
    }
    return Future.value(0);
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var converter = CsvToListConverter();
    var lines = file.readAsLinesSync();
    var columnNames = converter.convert(lines.first).first;
    if (!ListEquality()
        .equals(columnNames, ['STATION', 'DATE', 'TMAX', 'TMIN'])) {
      throw StateError('File format has changed');
    }
    var stationId = converter.convert(lines[1]).first[0] as String;
    var aux = <Map<String, dynamic>>[];
    for (var line in lines.skip(1)) {
      var data = converter.convert(line).first;
      var tMin = num.tryParse(data[3]);
      var tMax = num.tryParse(data[2]);
      if (tMin != null && tMax != null) {
        aux.add({
          'date': data[1] as String,
          'tMin': num.parse(data[3]),
          'tMax': num.parse(data[2]),
        });
      }
    }

    // split the data by year
    var groups = groupBy(aux, (Map e) => (e['date'] as String).substring(0, 4));
    var out = <Map<String, dynamic>>[];
    for (var year in groups.keys) {
      out.add({
        'stationId': stationId,
        'year': int.parse(year),
        'tMin': groups[year]!.map((e) => e['tMin']).toList(),
        'tMax': groups[year]!.map((e) => e['tMax']).toList(),
      });
    }

    return out;
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'stationId': 1});
    await dbConfig.db.close();
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    // TODO: implement converter
    throw UnimplementedError();
  }
}
