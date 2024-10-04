library test.db.isoexpress.mra_capacity_bidoffer_test;

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';

Future<void> tests(String rootUrl) async {
  var archive = getIsoneMraBidOfferArchive();
  group('MRA BidOffer archive tests:', () {
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
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  DbProd();
  await tests(dotenv.env['ROOT_URL']!);
}
