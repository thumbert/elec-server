library test.db.isoexpress.rt_energy_offer_test;


import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> tests() async {
  final archive = getIsoneRtEnergyOfferArchive();
  group('ISONE RT energy offer tests:', () {
    test('read file for 2023-01-01', () async {
      var file = archive.getFilename(Date.utc(2023, 1, 1));
      var data = archive.processFile(file);
      expect(data.length, 22850);
      var columns = data.first.toJson().keys.toList();
      expect(columns.length, 17);
    });
    test('read file for 2024-06-30', () async {
      var file = archive.getFilename(Date.utc(2024, 6, 30));
      var data = archive.processFile(file);
      expect(data.length, 23462);
      var x0 = data.first;
      expect(x0.ecoMin, 47.5);
      expect(x0.ecoMax, 75.0);
      expect(x0.segment, 0);
      expect(x0.hour,
          Hour.beginning(TZDateTime(IsoNewEngland.location, 2024, 6, 30)));
      var columns = x0.toJson().keys.toList();
      expect(columns.length, 17);

      var x1 =
          data.firstWhere((e) => e.maskedAssetId == 91570 && e.segment == 2);
      expect(x1.price, 33.59);
      expect(x1.quantity, 6.9);
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
//   });
}

Future<void> main() async {
  initializeTimeZones();
  await tests();
}
