library test.db.isoexpress.rt_lmp_hourly_test;

import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/rt_lmp_hourly.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

/// prepare data by downloading a few reports
Future<void> prepareData() async {
  var archive = RtLmpHourlyArchive();
  var days = [
    Date.utc(2017, 3, 12),
    Date.utc(2017, 11, 5),
    Date.utc(2022, 12, 22),
  ];
  await archive.downloadDays(days);
}

Future<void> tests() async {
  group('ISONE RT hourly lmp report', () {
    late RtLmpHourlyArchive archive;
    setUp(() async {
      archive = RtLmpHourlyArchive();
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
   test('RT hourly lmp report, DST day spring', () async {
     var file = archive.getFilename(Date.utc(2022, 12, 22));
     var res = archive.processFile(file);
     expect(res.first.keys.toSet(), {'date', 'ptid', 'congestion', 'lmp', 'marginal_loss'});
     var x321 = res.firstWhere((e) => e['ptid'] == 321);
     expect(x321['lmp'].first, 136.57);
   });
//    test('RT hourly lmp report, DST day spring', () async {
//      File file = archive.getFilename(new Date.utc(2017, 3, 12));
//      var res = await archive.processFile(file);
//      expect(res.first['hourBeginning'].length, 23);
//    });
//    test('RT hourly lmp report, DST day fall', () async {
//      File file = archive.getFilename(new Date.utc(2017, 11, 5));
//      var res = await archive.processFile(file);
//      expect(res.first['hourBeginning'].length, 25);
//    });
//     test('Insert one day', () async {
//       await archive.downloadDay(Date.utc(2017, 1, 1));
//       await archive.insertDay(Date.utc(2017, 1, 1));
//     });
//     test('insert several days', () async {
//       List days =
//           Interval(Date.utc(2017, 1, 1).start, Date.utc(2017, 1, 5).start)
//               .splitLeft((dt) => Date.utc(dt.year, dt.month, dt.day));
//       for (var day in days) {
//         await archive.downloadDay(day);
//         await archive.insertDay(day);
//       }
//     });
  });
}

Future<void> fillDb() async {
  var archive = RtLmpHourlyArchive();
  await archive.dbConfig.db.open();
  List days = Interval(Date.utc(2017, 12, 31).start, Date.utc(2018, 1, 1).start)
      .splitLeft((dt) => Date.utc(dt.year, dt.month, dt.day));
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');

  // await RtLmpHourlyArchive().setupDb();
  // await prepareData();
  await tests();

}
