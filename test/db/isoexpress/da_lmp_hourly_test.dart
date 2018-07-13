library test.db.isoexpress.da_lmp_hourly_test;

import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

/// prepare data by downloading a few reports
prepareData() async {
  var archive = new DaLmpHourlyArchive();
  var days = [new Date(2017, 3, 12), new Date(2017, 11, 5)];
  await archive.downloadDays(days);
}

DaLmpHourlyTest() async {
  Location location = getLocation('US/Eastern');
  group('DA hourly lmp report', () {
    var archive = new DaLmpHourlyArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('DA hourly lmp report, DST day spring', () async {
      File file = archive.getFilename(new Date(2017, 3, 12));
      var res = await archive.processFile(file);
      expect(res.first['hourBeginning'].length, 23);
    });
    test('DA hourly lmp report, DST day fall', () async {
      File file = archive.getFilename(new Date(2017, 11, 5));
      var res = await archive.processFile(file);
      expect(res.first['hourBeginning'].length, 25);
    });
    test('Insert one day', () async {
      var date = new Date(2017, 1, 1);
      if (!await archive.hasDay(date)) await archive.insertDay(date);
    });
    test('insert several days', () async {
      List days = new Interval(new TZDateTime(location, 2017, 1, 1),
              new TZDateTime(location, 2017, 1, 5))
          .splitLeft((dt) => new Date(dt.year, dt.month, dt.day));
      await for (var day in new Stream.fromIterable(days)) {
        if (!await archive.hasDay(day)) {
          await archive.downloadDay(day);
          await archive.insertDay(day);
        }
      }
    });
    test('hasDay', () async {
      var d1 = new Date(2017, 1, 1);
      var res = await archive.hasDay(d1);
      expect(res, true);
      var d2 = Date.today().next.next;
      res = await archive.hasDay(d2);
      expect(res, false);

    });
  });
}

Future soloTest() async {
  var archive = new DaLmpHourlyArchive();
  Location location = getLocation('US/Eastern');
  List days = new Interval(new TZDateTime(location, 2018, 1, 1),
      new TZDateTime(location, 2018, 5, 1))
      .splitLeft((dt) => new Date(dt.year, dt.month, dt.day));
  await archive.dbConfig.db.open();
  await for (var day in new Stream.fromIterable(days)) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  archive.dbConfig.db.close();
}

main() async {
  await initializeTimeZone(getLocationTzdb());
  // //await new DaLmpHourlyArchive().setupDb();
  // await prepareData();

  await DaLmpHourlyTest();

//  Db db = new Db('mongodb://localhost/isoexpress');
//  await new DaLmpHourlyArchive().updateDb(new DaLmp(db));

//  await soloTest();
}
