library test.db.isoexpress.da_demand_bid_test;

import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_demand_bid.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

/// prepare data by downloading a few reports
prepareData() async {
  var archive = DaDemandBidArchive();
  var days = [Date(2017, 3, 12)];
  await archive.downloadDays(days);
}


DaEnergyOffersTest() async {
  group('DA energy offers report', () {
    var archive = DaDemandBidArchive();
//    test('DA energy offers report, DST day spring', () async {
//      File file = archive.getFilename(new Date(2017, 3, 12));
//      var res = await archive.processFile(file);
//      expect(res.first['hours'].length, 23);
//    });
//    test('DA hourly lmp report, DST day fall', () async {
//      File file = archive.getFilename(new Date(2017, 11, 5));
//      var res = await archive.processFile(file);
//      expect(res.first['hourBeginning'].length, 25);
//    });
    test('Insert one day', () async {
      await archive.dbConfig.db.open();
      await archive.insertDay(new Date(2017, 3, 12));
      await archive.dbConfig.db.close();
    });
//    test('insert several days', () async {
//      List days =
//      new Interval(new DateTime(2017, 1, 1), new DateTime(2017, 1, 5))
//          .splitLeft((dt) => new Date(dt.year, dt.month, dt.day));
//      await archive.dbConfig.db.open();
//      await for (var day in new Stream.fromIterable(days)) {
//        await archive.downloadDay(day);
//        await archive.insertDay(day);
//      }
//      archive.dbConfig.db.close();
//    });
  });
}


Future insertDays() async {
  var location = getLocation('America/New_York');
  var archive = DaDemandBidArchive();
  var days = Interval(TZDateTime(location, 2019, 2, 1),
      TZDateTime(location, 2019, 2, 28))
      .splitLeft((dt) => Date(dt.year, dt.month, dt.day)).cast<Date>();
  await archive.dbConfig.db.open();

  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }

//  await for (var day in new Stream.fromIterable(days)) {
//    await archive.downloadDay(day);
//    await archive.insertDay(day);
//  }
  archive.dbConfig.db.close();
}


Future soloTest() async {
  var archive = DaDemandBidArchive();
  var data = await archive.processFile(archive.getFilename(Date(2017,3,12)));
  print(data);
}


main() async {
  await initializeTimeZone();
  //await new DaDemandBidArchive().setupDb();
//  await prepareData();

  //await DaEnergyOffersTest();

  await insertDays();

  //await new DaDemandBidArchive().updateDb();

  //await soloTest();
}

