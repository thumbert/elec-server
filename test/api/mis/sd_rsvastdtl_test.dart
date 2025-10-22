import 'dart:io';
import 'package:elec_server/src/db/mis/sd_rsvastdtl.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

void tests() async {
  var archive = SdRsvAstDtlArchive();
  group('MIS SD_RSVASTDTL report archive', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read report', () async {
      var file = File(
          'test/_assets/sd_rsvastdtl_000000002_2015060100_20161221131703.csv');
      var data = archive.processFile(file);
      expect(data.keys.toSet(), {0, 2});
      for (var tab in data.keys) {
        await archive.insertTabData(data[tab]!, tab: tab);
      }
    });
  });
}

void main() async {
  initializeTimeZones();
  //await SdRsvAstDtlArchive().setupDb();
  tests();
}
