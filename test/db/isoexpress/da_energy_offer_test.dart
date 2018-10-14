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

tests() async {
  group('DA energy offers report', () {
    var archive = new DaEnergyOfferArchive();
    setUp(() async {
      //await archive.setupDb();
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('download 2018-01-01 and insert it', () async {
      var date = Date(2018, 1, 1);
      //await archive.downloadDay(date);
      //await archive.insertDay(date);
      var data = archive.processFile(archive.getFilename(date));
      await archive.dbConfig.coll.insertAll(data);
    });
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
//    test('Insert one day', () async {
//      await archive.dbConfig.db.open();
//      await archive.insertDay(new Date(2017, 3, 12));
//      await archive.dbConfig.db.close();
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
  Location location = getLocation('US/Eastern');
  var archive = new DaEnergyOfferArchive();
  List days = new Interval(new TZDateTime(location, 2018, 1, 1),
      new TZDateTime(location,2018, 2, 1))
      .splitLeft((dt) => new Date(dt.year, dt.month, dt.day));
  await archive.dbConfig.db.open();
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  archive.dbConfig.db.close();
}

main() async {
  await initializeTimeZone();
  //await new DaEnergyOfferArchive().setupDb();
  //await prepareData();

  await tests();

  //await new DaEnergyOfferArchive().updateDb();

  //await soloTest();

//  await insertDays();
}
