library test.api.mis.sd_rtncpcpymt;

import 'dart:io';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/src/db/mis/sd_rtncpcpymt.dart';

void tests() async {
  var archive = SdRtNcpcPymtArchive();
  group('MIS SD_RTNCPCPYMT report archive', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read report', () async {
      var file = File('test/_assets/sd_rtncpcpymt_000000001_2015100200_20141024155608.CSV');
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
  tests();
}
