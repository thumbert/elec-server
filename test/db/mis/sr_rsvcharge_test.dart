library test.mis.sr_rsvcharge_test;

import 'dart:io';
import 'package:elec_server/src/db/mis/sr_rsvcharge.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';

void tests() async {
  group('MIS report SR_RSVCHARGE archive', () {
    var dir = Directory('test/_assets');
    var file = dir
        .listSync()
        .where((e) => basename(e.path).startsWith('sr_rsvcharge_'))
        .first;
    var archive = SrRsvChargeArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
      //await archive.setupDb();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('read and insert report', () async {
      var data = archive.processFile(file as File);
      expect(data.length, 3);
      for (var tab in data.keys) {
        await archive.insertTabData(data[tab]!);
      }
    });
  });
//  group('MIS report SR_RSVCHARGE api', () async {
//
//  });
}

void main() async {
  initializeTimeZones();
  tests();
}
