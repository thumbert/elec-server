library test.mis.sr_rtlocsum_test;

import 'dart:io';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/mis/sr_rtlocsum.dart';

void srRtLocSumTest() async{
  var dir = Directory(
      Platform.environment['HOME'] + '/Downloads/Archive/mis/all_samples');
  var file =
      dir.listSync().where((e) => basename(e.path).startsWith('sr_rtlocsum_')).first;
  var archive = SrRtLocSumArchive();

  setUp(() async {
    await archive.dbConfig.db.open();
    //await archive.setupDb();
  });
  tearDown(() async {
    await archive.dbConfig.db.close();
  });

  group('MIS report sr_rtlocsum', () {
    test('read report', () async {
      var data = archive.processFile(file);
      expect(data.length, 17);
      await archive.insertTabData(data[0]);
    });

  });
}

void main() async {
  await initializeTimeZone();

  await srRtLocSumTest();
}
