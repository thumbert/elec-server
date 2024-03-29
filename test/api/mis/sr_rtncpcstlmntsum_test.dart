library test.api.mis.sr_rtncpcstlmntsum;

import 'dart:io';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/src/db/mis/sr_rtncpcstlmntsum.dart';

void tests() async {
  group('MIS SR_RTNCPCSTLMNTSUM report archive', () {
    var archive = SrRtNcpcStlmntSumArchive();
    test('read report', (){
      var file = File('test/_assets/sr_rtncpcstlmntsum_000000001_2015060200_20161221144539.csv');
      var data = archive.processFile(file);
      expect(data.keys.length, 2);
    });
  });
}



void main() async {
  initializeTimeZones();
  tests();
}
