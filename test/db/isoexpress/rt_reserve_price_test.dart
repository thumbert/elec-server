library test.db.isoexpress.rt_reserve_price_test;


import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  final archive = getIsoneRtReservePriceArchive();
  group('ISONE RT reserve price tests:', () {
    test('read file for 2021-01-01', () async {
      var file = archive.getFilename(Date.utc(2021, 1, 1));
      var data = archive.processFile(file);
      expect(data.length, 288); // = 24 hours * 12 observations
      var columns = data.first.keys.toList();
      expect(columns.length, 31);
      print(columns.map((e) => "$e FLOAT,").join('\n'));
    });
  });
  //
  //
//   test('duckdb test', () {
//     final duckFile = File(
//         '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/energy_offers.duckdb');
//     if (duckFile.existsSync()) {
//       final con = Connection(duckFile.path);
//       final query = '''
// SELECT * FROM rt_energy_offers
// ''';

//       con.close();
//     }
  // });
}

Future<void> main() async {
  initializeTimeZones();
  await tests();
}
