library test.db.isoexpress.mra_capacity_results_test;

import 'dart:io';

import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/client/isoexpress/mra_capacity_results.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  final archive = getIsoneMraResultsArchive();
  group('ISONE MRA results tests:', () {
    test('read file for 2024-01', () async {
      var file = archive.getFilename(Month.utc(2024, 1));
      var data = archive.processFile(file);
      expect(data.length, 9); // 4 zones + 5 interfaces
      final zones = data.whereType<MraCapacityZoneRecord>().toList();
      expect(zones.length, 4);
      final sene = zones
          .firstWhere((e) => e.capacityZoneName == 'Southeast New England');
      expect(sene.clearingPrice, 3.938);
      expect(sene.supplyOffersSubmitted, 428.687);
      expect(sene.demandBidsSubmitted, 3493.009);
      expect(sene.netCapacityCleared, -402.134);
      // and an interface
      final nb = data
          .whereType<MraCapacityInterfaceRecord>()
          .firstWhere((e) => e.externalInterfaceName == 'New Brunswick');
      expect(nb.clearingPrice, 3.938);
      expect(nb.supplyOffersSubmitted, 0);
      expect(nb.demandBidsSubmitted, 72);
      expect(nb.netCapacityCleared, -72);

      // to json
      // print(sene.toJson().keys.join(',\n'));
    });
    test('read 2024-08 (new format)', () {
      var file = archive.getFilename(Month.utc(2024, 8));
      var data = archive.processFile(file);
      expect(data.length, 9); // 4 zones + 5 interfaces
      final zones = data.whereType<MraCapacityZoneRecord>().toList();
      expect(zones.length, 4);
      final sene = zones
          .firstWhere((e) => e.capacityZoneName == 'Southeast New England');
      expect(sene.clearingPrice, 10.0);
      expect(sene.supplyOffersSubmitted, 173.028);
      expect(sene.demandBidsSubmitted, 1779.517);
      expect(sene.netCapacityCleared, 0);
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
