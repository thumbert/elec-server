library test.db.isoexpress.rt_energy_offer_test;

import 'dart:io';

import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  final archive = getRtEnergyOfferArchive();
  group('ISONE RT energy offer tests:', () {
    test('read file for 2023-01-01', () async {
      var file = archive.getFilename(Date.utc(2023, 1, 1));
      var data = archive.processFile(file);
      expect(data.length, 22850);
      var columns = data.first.toJson().keys.toList();
      expect(columns.length, 17);
      print(columns.map((e) => "$e ,").join('\n'));
    });
  });
  //
  //
  test('duckdb test', () {
    final duckFile = File(
        '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/energy_offers.duckdb');
    if (duckFile.existsSync()) {
      final con = Connection(duckFile.path);
      final query = '''
SELECT * FROM rt_energy_offers
''';




      con.close();
    }
  });
}

Future<void> main() async {
  initializeTimeZones();
  await tests();
}
