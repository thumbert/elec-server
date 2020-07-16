library test.db.isoexpress.da_lmp_hourly_test;

import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

/// prepare data by downloading a few reports
/// Missing 9/29/2018 and 9/30/2018 !!!
void prepareData() async {
  var archive = DaLmpHourlyArchive();
  var days = [Date(2018, 9, 26), Date(2018, 9, 29), Date(2018, 9, 30),];
  await archive.downloadDays(days);
}

void tests() async {
  var location = getLocation('America/New_York');
  group('DA hourly lmp report', () {
    var archive = DaLmpHourlyArchive();
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('DA hourly lmp report, DST day spring', () async {
      var file = archive.getFilename(Date(2017, 3, 12));
      var res = await archive.processFile(file);
      expect(res.first['hourBeginning'].length, 23);
    });
    test('DA hourly lmp report, DST day fall', () async {
      var file = archive.getFilename(Date(2017, 11, 5));
      var res = await archive.processFile(file);
      expect(res.first['hourBeginning'].length, 25);
    });
    test('Insert one day', () async {
      var date = Date(2017, 1, 1);
      if (!await archive.hasDay(date)) await archive.insertDay(date);
    });
    test('insert several days', () async {
      var days = Interval(TZDateTime(location, 2017, 1, 1),
              TZDateTime(location, 2017, 1, 5))
          .splitLeft((dt) => Date(dt.year, dt.month, dt.day));
      await for (var day in Stream.fromIterable(days)) {
        if (!await archive.hasDay(day)) {
          await archive.downloadDay(day);
          await archive.insertDay(day);
        }
      }
    });
    test('hasDay', () async {
      var d1 = Date(2017, 1, 1);
      var res = await archive.hasDay(d1);
      expect(res, true);
      var d2 = Date.today().next.next;
      res = await archive.hasDay(d2);
      expect(res, false);
    });
  });
}

Future soloTest() async {
  var archive = DaLmpHourlyArchive();
//  await archive.setupDb();
  var location = getLocation('America/New_York');
  var days = Interval(
          TZDateTime(location, 2017, 1, 1), TZDateTime(location, 2017, 9, 1))
      .splitLeft((dt) => Date.fromTZDateTime(dt));
  await archive.dbConfig.db.open();
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

void main() async {
  await initializeTimeZone();
  // await DaLmpHourlyArchive().setupDb();
  // await prepareData();

  //await DaLmpHourlyTest();

//  Db db = new Db('mongodb://localhost/isoexpress');
//  await new DaLmpHourlyArchive().updateDb(new DaLmp(db));

   await soloTest();
}
