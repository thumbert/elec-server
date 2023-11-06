library db.utilities.maine.load_cmp;

import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:elec_server/client/utilities/cmp/cmp.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

import 'package:elec_server/src/utils/iso_timestamp.dart';

import 'package:elec_server/src/db/config.dart';

class MaineCmpLoadArchive {
  MaineCmpLoadArchive({ComponentConfig? dbConfig, String? dir}) {
    var env = Platform.environment;
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1', dbName: 'utility', collectionName: 'load_cmp');
    this.dir =
        dir ??= '${env['HOME']!}/Downloads/Archive/Utility/Maine/CMP/Load/Raw/';
  }

  late final ComponentConfig dbConfig;
  late final String dir;
  late SpreadsheetDecoder _decoder;

  /// insert data into Mongo
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    try {
      for (var e in data) {
        await dbConfig.coll.remove({
          'settlement': e['settlement'],
          'class': e['class'],
          'date': e['date'],
        });
        await dbConfig.coll.insertOne(e);
      }
      print(
          '---> Inserted CMP load data from ${data.first['date']} to ${data.last['date']}');
    } catch (e) {
      print('XXX $e');
    }
    return 0;
  }

  /// Utility publishes a file per year for each customer class
  File getFile(
      {required int year,
      required CmpCustomerClass customerClass,
      String settlementType = 'final'}) {
    final directory = switch (settlementType) {
      'final' => Directory('$dir/Resettled/$year'),
      _ => throw ArgumentError('Unknown settlementType $settlementType'),
    };

    var files = directory.listSync().whereType<File>().toList();
    final id = switch (customerClass) {
      CmpCustomerClass.large => 'cmp_large',
      CmpCustomerClass.medium => 'cmp_medium',
      CmpCustomerClass.residentialAndSmallCommercial => 'cmp_resi',
    };
    var i = files
        .map((e) => basename(e.path).toLowerCase())
        .toList()
        .indexWhere((filename) => filename.contains(id));
    if (i == -1) {
      throw StateError('Can\t find file!');
    }
    return files[i];
  }

  List<Map<String, dynamic>> processFile(
      {required int year,
      required CmpCustomerClass customerClass,
      String settlementType = 'final'}) {
    var file = getFile(
      year: year,
      customerClass: customerClass,
      settlementType: settlementType,
    );

    var converter = const CsvToListConverter();
    var lines = file.readAsLinesSync();
    var data = lines.map((line) => converter.convert(line).first);
    // group by date
    var groups = groupBy(data.skip(1), (List row) => row[1]);

    final fmt = DateFormat('M/d/yyyy');
    var out = <Map<String, dynamic>>[];
    for (String key in groups.keys) {
      // key is in mm/dd/yyyy format
      var dt = fmt.parse(key.trim(), true);
      late List<num> mwh;
      if (groups[key]!.length == 25) {
        var aux = groups[key]!.map((xs) => xs[3] as num).toList();
        // sometimes it's "2*" or "02*"
        var i2 = groups[key]!
            .map((xs) => xs[2])
            .toList()
            .indexWhere((e) => e.toString().contains('2*'));
        if (i2 == -1) {
          throw StateError('There is no hour with value "2*"!');
        }
        var v2 = aux.removeAt(i2);
        aux.insert(2, v2);
        mwh = [...aux];
      } else {
        mwh = groups[key]!.map((xs) {
          num value;
          if (xs[3] is num) {
            value = xs[3];
          } else if (xs[3] is String) {
            var v = num.tryParse((xs[3] as String).replaceAll(',', ''));
            if (v == null) {
              throw StateError('Can\'t parse ${xs[3]} into a number!');
            }
            value = v;
          } else {
            throw StateError('Expecting a number, got ${xs[3]}!');
          }
          return value;
        }).toList();
      }
      out.add({
        'date': dt.toIso8601String().substring(0, 10),
        'class': customerClass.name,
        'settlement': settlementType,
        'mwh': mwh,
      });
    }

    return out;
  }

  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'settlement': 1, 'class': 1, 'date': 1}, unique: true);
    await dbConfig.db.close();
  }
}
