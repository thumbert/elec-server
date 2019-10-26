library test.api.mis.sd_rtncpcpymt;

import 'dart:io';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/mis/sd_rtncpcpymt.dart';

tests() async {
  group('MIS SD_RTNCPCPYMT report archive', () {
    var archive = SdRtNcpcPymtArchive();
    test('read report', () {
      print(Directory.current);
      var file = File('test/_assets/sd_rtncpcpymt_000000001_2015100200_20141024155608.CSV');
      var data = archive.processFile(file);
      expect(data.keys.toSet(), {0, 2});
    });
  });
}



main() async {
  await initializeTimeZone();
  await tests();
}