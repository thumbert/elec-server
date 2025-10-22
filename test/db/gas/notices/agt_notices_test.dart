import 'package:elec_server/src/db/gas/notices/agt_notices.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  var archive = AgtNoticesArchive();
  group('AGT critical notices tests:', () {
    // setUp(() async => await archive.db.open());
    // tearDown(() async => await archive.db.close());
    test('read current critical ids', () async {
      var uris = await archive.getUris(pipeline: 'AG', type: 'CRI');
      print(uris);
      // await archive.saveUrisToDisk(uris); // not working correctly
      await archive.savePdfToDisk(Month.utc(2023, 7).upTo(Month.utc(2023, 8)));
      expect(uris.length > 12, true);
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  var rootUrl = 'http://127.0.0.1:8080';
  await tests(rootUrl);
}
