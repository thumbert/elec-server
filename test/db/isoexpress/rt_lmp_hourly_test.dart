library test.db.isoexpress.rt_lmp_hourly_test;

import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/rt_lmp_hourly.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

/// prepare data by downloading a few reports
prepareData() async {
  var archive = new RtLmpHourlyArchive();
  var days = [new Date(2017, 3, 12), new Date(2017, 11, 5)];
  await archive.downloadDays(days);
}

RtLmpHourlyTest() async {
  group('RT hourly lmp report', () {
    RtLmpHourlyArchive archive;
    setUp(() async {
      archive = new RtLmpHourlyArchive();
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });

//    test('RT hourly lmp report, DST day spring', () async {
//      File file = archive.getFilename(new Date(2017, 3, 12));
//      var res = await archive.processFile(file);
//      expect(res.first['hourBeginning'].length, 23);
//    });
//    test('RT hourly lmp report, DST day fall', () async {
//      File file = archive.getFilename(new Date(2017, 11, 5));
//      var res = await archive.processFile(file);
//      expect(res.first['hourBeginning'].length, 25);
//    });
    test('Insert one day', () async {
      await archive.downloadDay(new Date(2017, 1, 1));
      await archive.insertDay(new Date(2017, 1, 1));
    });
    test('insert several days', () async {
      List days =
          new Interval(new Date(2017, 1, 1).start, new Date(2017, 1, 5).start)
              .splitLeft((dt) => new Date(dt.year, dt.month, dt.day));
      for (var day in days) {
        await archive.downloadDay(day);
        await archive.insertDay(day);
      }
    });
  });
}

Future fillDb() async {
  var archive = new RtLmpHourlyArchive();
  await archive.dbConfig.db.open();
  List days = new Interval(new Date(2017,12,31).start, new Date(2018,1,1).start)
      .splitLeft((dt) => new Date(dt.year, dt.month, dt.day));
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

main() async {
  await initializeTimeZone(getLocationTzdb());
  // await new RtLmpHourlyArchive().setupDb();
  // await prepareData();

  await fillDb();

//  Db db = new Db('mongodb://localhost/isoexpress');
//  await new DaLmpHourlyArchive().updateDb(new DaLmp(db));

  //await soloTest();
}
