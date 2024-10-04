library test.db.isoexpress.rt_lmp_5min_test;

// import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/elec.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';

Future<void> tests() async {
  var archive = getIsoneRtLmp5MinArchive();
  group('MRA BidOffer archive tests:', () {
    test('read file for Hub, 2024-01-01', () async {
      var file = archive.getFilename(
          Date(2024, 1, 1, location: IsoNewEngland.location),
          type: 'final',
          ptid: 4000);
      var data = archive.processFile(file);
      expect(data.length, 288);
      expect(data.first.keys.toList(),
          ['ptid', 'report', 'date', 'minuteOfDay', 'lmp', 'mcc', 'mlc']);
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  await tests();
}
