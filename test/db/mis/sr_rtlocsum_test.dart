library test.mis.sr_rtlocsum_test;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/mis/sr_rtlocsum.dart';

srRtLocSumTest() async{
  var dir = new Directory(
      Platform.environment['HOME'] + '/Downloads/Archive/mis/all_samples');
  var file =
      dir.listSync().where((e) => basename(e.path).startsWith('sr_rtlocsum_')).first;
  var archive = new SrRtLocSumArchive();
  //await archive.setupDb();

  setUp(() async {
    await archive.dbConfig.db.open();
  });
  tearDown(() async {
    await archive.dbConfig.db.close();
  });

  group('MIS report sr_rtlocsum', () {
    test('read report', () async {
      var data = archive.processFile(file);
      expect(data.length, 17);
      await archive.insertData(data);
    });

  });
}

main() async {
  await initializeTimeZone(getLocationTzdb());

  await srRtLocSumTest();
}
