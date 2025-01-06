library lib.db.ieso.rt_zonal_demand_archive;

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:elec_server/db_isone.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

class IesoRtZonalDemandArchive extends IsoExpressReport {
  IesoRtZonalDemandArchive({ComponentConfig? dbConfig, String? dir}) {
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1',
            dbName: 'ieso',
            collectionName: 'rt_zonal_demand');
    this.dir = dir ??
        '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/Ieso/RtZonalDemand/Raw/';
  }

  final log = Logger('IESO RT Zonal Demand');

  /// days with missing data
  static Set<String> problemDays = {
    '2024-10-18',
  };

  ///
  String getUrl(int year) {
    return 'http://reports-public.ieso.ca/public/DemandZonal/PUB_DemandZonal_$year.csv';
  }

  File getFilename(int year) => File('$dir${basename(getUrl(year))}');

  /// Insert this data into the database.
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    try {
      for (var x in data) {
        await dbConfig.coll.remove({
          'zone': x['zone'],
          'date': x['date'],
        });
        await dbConfig.coll.insert(x);
      }
      log.info('--->  Inserted IESO rt zonal demand data successfully');
    } catch (e) {
      log.severe('XXX $e');
      return Future.value(1);
    }
    return Future.value(0);
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var converter = CsvToListConverter();
    var lines = file.readAsLinesSync();

    final keys = converter.convert(lines[3]).first.cast<String>();
    if (!ListEquality().equals(keys, [
      'Date',
      'Hour',
      'Ontario Demand',
      'Northwest',
      'Northeast',
      'Ottawa',
      'East',
      'Toronto',
      'Essa',
      'Bruce',
      'Southwest',
      'Niagara',
      'West',
      'Zone Total',
      'Diff',
    ])) {
      throw StateError('File format has changed');
    }

    var aux = <Map<String, dynamic>>[];
    for (var line in lines.skip(4)) {
      var data = converter.convert(line).first;
      if (data.length != 15) continue;
      aux.add(Map.fromIterables(keys, data));
    }

    // split the data by date
    var groups = groupBy(aux, (e) => e['Date'] as String);
    var out = <Map<String, dynamic>>[];
    for (var date in groups.keys) {
      var xs = groups[date]!;
      if (!problemDays.contains(date)) {
        if (xs.length != 24) {
          throw StateError('Every day should have 24 hours.  '
              '${xs.first['Date']} doesn\'t.');
        }
      }
      for (var key in keys.skip(2)) {
        if (key == 'Diff') continue;
        out.add({
          'date': xs.first['Date'],
          'zone': key.replaceAll(' Demand', ''),
          'values': xs.map((e) => e[key]).toList(),
        });
      }
    }

    return out;
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'zone': 1, 'date': 1}, unique: true);
    await dbConfig.db.close();
  }
}
