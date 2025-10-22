import 'dart:async';
import 'dart:io';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:collection/collection.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class IsoneBtmSolarArchive {
  IsoneBtmSolarArchive({ComponentConfig? dbConfig, String? dir}) {
    var env = Platform.environment;
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1',
            dbName: 'isone',
            collectionName: 'hourly_btm_solar');
    this.dir = dir ??= '${env['HOME']!}/Downloads/Archive/Isone/Solar/BTM/Raw';
  }

  late final ComponentConfig dbConfig;
  late final String dir;

  /// Insert data into Mongo. All zones at once.
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);

    /// split the data by day and insert it
    var groups = groupBy(data, (e) => e['date']);
    for (var date in groups.keys) {
      await dbConfig.coll.remove({
        'date': date,
      });
      await dbConfig.coll.insertAll(groups[date]!);
    }
    print(
        '---> Inserted ISONE BTM solar data from ${data.first['date']} to ${data.last['date']}');
    return 0;
  }

  /// Data is from
  /// https://www.iso-ne.com/static-assets/documents/2020/07/btm_pv_data.xlsx
  /// ISO updates the file every few months.
  /// To get the link, search for 'behind-the-meter PV data' in the search box.
  /// Usually, it is the first link (a spreadsheet of more than 10 MB.)
  ///
  File getFile({required Date date}) {
    return File('$dir/btm_pv_data_${date.toString()}.xlsx');
  }

  List<Map<String, dynamic>> processFile(Date asOfDate) {
    final file = getFile(date: asOfDate);
    final bytes = file.readAsBytesSync();
    var decoder = SpreadsheetDecoder.decodeBytes(bytes);
    var table = decoder.tables['BTM PV'];
    if (table == null) {
      throw ArgumentError('Spreadsheet needs a tab called "BTM PV"');
    }
    assert(table.rows.first.length == 13);
    final zones = table.rows.first
        .sublist(4)
        .map((e) => (e as String).toUpperCase())
        .toList();
    if ({'CT', 'NEMA', 'SEMA', 'WCMA', 'ME', 'NH', 'RI', 'VT', 'ISONE'}
        .difference(zones.toSet())
        .isNotEmpty) {
      throw StateError('Zones have changed?!');
    }

    var groups = groupBy(table.rows.skip(1),
        (e) => Date(e[0], e[1], e[2], location: IsoNewEngland.location));

    var out = <Map<String, dynamic>>[];
    for (var date in groups.keys) {
      var xs = groups[date]!;
      var hours = date.hours();

      /// need to deal with the fact that the ISO data does not account correctly for the DST
      /// all days have 24 hours
      if (hours.length == 23 && xs.length == 24) {
        for (var i = 0; i < zones.length; i++) {
          out.add({
            'zone': zones[i],
            'date': date.toString(),
            'values': [0, 0, ...xs.skip(3).map((e) => e[i + 4])],
          });
        }
      } else if (hours.length == 25 && xs.length == 24) {
        for (var i = 0; i < zones.length; i++) {
          out.add({
            'zone': zones[i],
            'date': date.toString(),
            'values': [0, 0, 0, ...xs.skip(2).map((e) => e[i + 4])],
          });
        }
      } else {
        for (var i = 0; i < zones.length; i++) {
          out.add({
            'zone': zones[i],
            'date': date.toString(),
            'values': xs.map((e) => e[i + 4]).toList(),
          });
        }
      }
    }

    return out;
  }

  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(
      dbConfig.collectionName,
      keys: {'date': 1, 'zone': 1},
    );
    await dbConfig.db.close();
  }
}
