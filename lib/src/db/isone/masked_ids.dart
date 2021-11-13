library db.isone.masked_ids;

import 'dart:async';
import 'dart:io';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/config.dart';

class IsoNeMaskedIdsArchive {
  ComponentConfig? config;
  String? dir;

  IsoNeMaskedIdsArchive({this.config, this.dir}) {
    Map env = Platform.environment;
    config ??= ComponentConfig(
        host: '127.0.0.1', dbName: 'isone', collectionName: 'masked_ids');
    dir ??= env['HOME'] + '/Downloads/Archive/Assets/Raw/';
  }

  Db get db => config!.db;

  /// Insert [data] into Mongo.  Update the existing entries.
  Future<int> insertMongo(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(-99);
    try {
      await config!.coll.remove(<String, dynamic>{});
      await config!.coll.insertAll(data);
    } catch (e) {
      print('XXXX ' + e.toString());
      return Future.value(1);
    }
    print('--->  Updated masked ids successfully');
    return Future.value(0);
  }

  /// Read the master xlsx file.
  List<Map<String, dynamic>> readXlsx({File? file}) {
    file ??= File(dir! + 'unmasked.xlsx');
    if (!file.existsSync()) throw 'File ${file.path} does not exist!';

    var res = <Map<String, dynamic>>[];
    var bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);

    var table = decoder.tables['Location']!;
    for (var row in table.rows.skip(1)) {
      if (row[0] is num) {
        res.add(<String, dynamic>{
          'type': 'location',
          'Masked Location ID': (row[1] as num).toInt(),
          'ptid': (row[0] as num).toInt(),
        });
      }
    }

    table = decoder.tables['Participant']!;
    for (var row in table.rows.skip(1)) {
      if (row[0] is num && row[1] != null) {
        res.add(<String, dynamic>{
          'type': 'participant',
          'Masked Participant ID': (row[0] as num).toInt(),
          'name': row[1],
        });
      }
    }

    table = decoder.tables['asset ID']!;
    for (var row in table.rows.skip(1)) {
      if (row[0] is num && row[3] != null) {
        res.add(<String, dynamic>{
          'type': 'generator',
          'Masked Asset ID': (row[3] as num).toInt(),
          'ptid': (row[0] as num).toInt(),
          'name': row[1],
        });
      }
    }

    return res;
  }

  /// Setup of the collection
  Future<void> setup() async {
    if (!Directory(dir!).existsSync()) {
      Directory(dir!).createSync(recursive: true);
    }
    // await config!.db.open();

    /// Create the index, 3 types: 'asset', 'participant', 'location'
    await config!.db.createIndex(config!.collectionName, keys: {'type': 1});
    // await config!.db.close();
  }
}
