library test.db.isoexpress.da_lmp_hourly_test;

import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

/// prepare data by downloading a few reports
prepareData() async {
  var archive = new DaEnergyOfferArchive();
  var days = [new Date(2017, 3, 12), new Date(2017, 11, 5)];
  await archive.downloadDays(days);
}

DaEnergyOffersTest() async {
  group('DA energy offers report', () {
    var archive = new DaEnergyOfferArchive();
    test('DA energy offers report, DST day spring', () async {
      File file = archive.getFilename(new Date(2017, 3, 12));
      var res = await archive.processFile(file);
      expect(res.first['hours'].length, 23);
    });
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

Future soloTest() async {
  var archive = new DaEnergyOfferArchive();
  var data =
      await archive.processFile(archive.getFilename(new Date(2017, 3, 12)));
  print(data);
}

Future insertDays() async {
  var archive = new DaEnergyOfferArchive();
  List days = new Interval(new DateTime(2017, 1, 1), new DateTime(2017, 9, 30))
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
  //await new DaEnergyOfferArchive().setupDb();
  //await prepareData();

  //await DaEnergyOffersTest();

  //await new DaEnergyOfferArchive().updateDb();

  //await soloTest();

  await insertDays();
}
