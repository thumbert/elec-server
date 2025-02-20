library lib.db.ieso.rt_generation_archive;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:elec_server/db_isone.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

class IesoRtGenerationArchive extends IsoExpressReport {
  IesoRtGenerationArchive({ComponentConfig? dbConfig, String? dir}) {
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1', dbName: 'ieso', collectionName: 'rt_generation');
    this.dir = dir ??
        '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/Ieso/RtGeneration/Raw/';
  }

  final log = Logger('IESO RT Generation');

  ///
  String getUrl(Month month) {
    var yyyymm = month.toIso8601String().replaceAll('-', '');
    return 'https://reports-public.ieso.ca/public/GenOutputCapabilityMonth/'
        'PUB_GenOutputCapabilityMonth_$yyyymm.csv';
  }

  File getFilename(Month month, {String extension = 'zip'}) {
    var yyyymm = month.toIso8601String().replaceAll('-', '');
    return File('${dir}PUB_GenOutputCapabilityMonth_$yyyymm.$extension');
  }

  /// Insert this data into the database.  One month at a time.
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    var month = Month.parse((data.first['date'] as String).substring(0,7));
    try {
      for (var x in data) {
        await dbConfig.coll.remove({
          'name': x['name'],
          'date': x['date'],
        });
        await dbConfig.coll.insert(x);
      }
      log.info('--->  Inserted IESO rt generation data successfully for $month');
    } catch (e) {
      log.severe('XXX $e');
      return Future.value(1);
    }
    return Future.value(0);
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    if (!file.existsSync()) {
      return <Map<String, dynamic>>[];
    }
    late List<String> xs;
    if (extension(file.path) == '.zip') {
      final bytes = file.readAsBytesSync();
      var zipArchive = ZipDecoder().decodeBytes(bytes);
      var txtFile = zipArchive.first;
      var lines = txtFile.content as List<int>;
      var csv = utf8.decoder.convert(lines);
      xs = csv.split('\n');
    } else if (extension(file.path) == '.csv') {
      xs = file.readAsLinesSync();
    } else {
      throw StateError('Unsupported file extension ${extension(file.path)}');
    }

    final converter = CsvToListConverter();
    var rows = <Map<String, dynamic>>[];
    for (var x in xs.skip(4)) {
      if (x == '') continue;
      var es = converter.convert(x).first;
      var variable = switch (es[3]) {
        'Capability' => 'capability',
        'Output' => 'output',
        'Available Capacity' => 'capacity',
        'Forecast' => 'forecast',
        _ => throw StateError('Unknown measurement for $x'),
      };
      /// make sure the values are all ints.  Occasionally the spreadsheet
      /// contains ' '.  I replace that with 0's.
      var values = es.sublist(4, 28).map((e) => e is int ? e : 0).toList();
      rows.add({
        'date': es[0] as String,
        'name': es[1] as String,
        'fuel': (es[2] as String).toLowerCase(),
        'variable': variable,
        'values': values,
      });
    }

    // split the data by date, generator name
    var out = <Map<String, dynamic>>[];
    var groups =
        groupBy(rows, (e) => (e['date'] as String, e['name'] as String));
    for (var group in groups.keys) {
      var xs = groups[group]!;
      var one = <String, dynamic>{};
      for (var x in xs) {
        one[x['variable']] = x['values'];
      }
      out.add({
        'date': xs.first['date'],
        'name': xs.first['name'],
        'fuel': xs.first['fuel'],
        ...one,
      });
    }

    return out;
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'name': 1, 'date': 1}, unique: true);
    await dbConfig.db
        .createIndex(dbConfig.collectionName, keys: {'fuel': 1, 'date': 1});
    await dbConfig.db.close();
  }
}
