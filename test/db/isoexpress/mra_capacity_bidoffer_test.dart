library test.db.isoexpress.mra_capacity_bidoffer_test;

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/risk_system.dart';
import 'package:elec_server/src/db/isoexpress/mra_capacity_bidoffer.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';

Future<void> tests(String rootUrl) async {
  var archive = MraCapacityBidOfferArchive();
  group('Monthly NCPC by asset db tests:', () {
    // setUp(() async => await archive.db.open());
    // tearDown(() async => await archive.dbConfig.db.close());
    test('read file for 2024-01', () async {
      var file = archive.getFilename(Month.utc(2024, 1));
      var data = archive.processJsonFile(file);
      expect(data.length, 454);
      var xs = data.where((e) => e.maskedResourceId == 52995).toList();
      expect(xs.length, 5);
      var segments = xs.map((e) => e.segment).toList();
      segments.sort();
      expect(segments, [0, 1, 2, 3, 4]);
    });
  });
  // group('Monthly NCPC by asset API tests:', () {
  //   var api = ApiMonthlyAssetNcpc(archive.db);
  //   setUp(() async => await archive.db.open());
  //   tearDown(() async => await archive.db.close());
  //   test('Get NCPC for all assets Jan19-Mar19', () async {
  //     var res = await api.apiGetAllAssets('2019-01', '2019-03');
  //     expect(res.length, 1435);
  //     expect(res.first, {
  //       'month': '2019-01',
  //       'assetId': 321,
  //       'name': 'MANCHESTER 10/10A CC',
  //       'zoneId': 4005,
  //       'daNcpc': 0,
  //       'rtNcpc': 628.87,
  //     });
  //   });
  //   test('Get the monthly NCPC payments for one asset', () async {
  //     var res = await api.apiGetAsset('1616', '2019-01', '2021-06');
  //     expect(res.length, 30);
  //     expect(res.first, {
  //       'month': '2019-01',
  //       'daNcpc': 0,
  //       'rtNcpc': 9170.94,
  //     });
  //   });
  // });
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  DbProd();
  await tests(dotenv.env['ROOT_URL']!);
}
