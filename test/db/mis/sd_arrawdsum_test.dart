library test.mis.sr_rtlocsum_test;

import 'dart:io';
import 'package:elec_server/src/db/mis/sd_arrawdsum.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/mis/sr_rtlocsum.dart';

void tests() async {
  var dir = Directory('test/_assets');
  var file = dir
      .listSync()
      .where((e) => basename(e.path).startsWith('sd_arrawdsum_'))
      .first;
  var archive = SdArrAwdSumArchive();

  group('MIS report sd_arrawdsum tests:', () {
    setUp(() async {
      await archive.dbConfig.db.open();
      //await archive.setupDb();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('read report', () async {
      var data = archive.processFile(file);
      expect(data.length, 2);
//      await archive.insertTabData(data[0]);
//      await archive.insertTabData(data[1]);
    });
  });
}

void main() async {
  await initializeTimeZones();
  await tests();
}
