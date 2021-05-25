library test.db.isoexpress.da_regulation_offer_test;

import 'dart:io';
import 'dart:async';
import 'package:elec_server/api/isoexpress/api_isone_regulationoffers.dart';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/src/db/isoexpress/da_regulation_offer.dart';

tests() async {
  group('Regulation offers archive test:', () {
    var archive = RegulationOfferArchive();
    setUp(() async {
      await archive.setupDb();
      await archive.dbConfig.db.open();
    });
    tearDown(() async => await archive.dbConfig.db.close());
    test('download 2017-01-01 and insert it', () async {
      var date = Date.utc(2017, 1, 1);
//      await archive.downloadDay(date);
      var res = await archive.insertDay(date);
      expect(res, 0);
    });
  });
  group('DA regulation offers API test', () {
    var db = Db('mongodb://localhost/isoexpress');
    var api = DaRegulationOffers(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
  });
}


Future insertDays() async {
  var location = getLocation('America/New_York');
  var archive = RegulationOfferArchive();
  //await archive.setupDb();
  var days = Interval(TZDateTime(location, 2019, 7),
      TZDateTime(location, 2019, 8))
      .splitLeft((dt) => Date.fromTZDateTime(dt));
  await archive.dbConfig.db.open();
  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  archive.dbConfig.db.close();
}

main() async {
  await initializeTimeZone();
//  await DaRegulationOfferArchive().setupDb();

//  await tests();

//    await insertDays();
}
