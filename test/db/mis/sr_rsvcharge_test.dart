library test.mis.sr_rsvcharge_test;

import 'dart:io';
import 'package:elec_server/src/db/mis/sr_rsvcharge.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';

void srRsvChargeTest() async {
  var dir = Directory('test/_assets');
  var file = dir
      .listSync()
      .where((e) => basename(e.path).startsWith('sr_rsvcharge_'))
      .first;
  group('MIS report SR_RSVCHARGE', () {
    var archive = SrRsvChargeArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
      //await archive.setupDb();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('read and insert report', () async {
      var data = archive.processFile(file);
      expect(data.length, 3);
      for (var tab in data.keys) {
        await archive.insertTabData(data[tab]);
      }
    });
  });
}

void main() async {
  await initializeTimeZone();
  await srRsvChargeTest();
}
