library test.db.isoexpress.da_demand_bid_test;

import 'package:dotenv/dotenv.dart' as dotenv;
import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_demand_bid.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

void tests() async {
  group('DA demand bid report (masked bids)', () {
    var archive = DaDemandBidArchive();
    test('process file 2019-02-28.csv', () {
      var file = File(archive.dir + 'hbdayaheaddemandbid_20190228.csv');
      var aux = archive.processCsvFile(file);
      var aux0 = aux.first;
      expect(aux0.keys.toSet(), {
        'date', 'Masked Lead Participant ID', 'Masked Location ID',
        'Location Type', 'Bid Type', 'Bid ID', 'hours',
      });
      expect(aux0['date'], '2019-02-28');
      expect(aux0['Masked Lead Participant ID'], 110487);
      expect(aux0['Masked Location ID'], 41756);
      expect(aux0['Location Type'], 'LOAD ZONE');
      expect(aux0['Bid Type'], 'FIXED');  // can also be DEC, INC, PRICE
      expect(aux0['Bid ID'], '16403780');  // this should be an integer!
      expect((aux0['hours'] as List).length, 24);
      var h0 = (aux0['hours'] as List).first as Map<String,dynamic>;
      expect(h0, {
        'hourBeginning': '2019-02-28T00:00:00.000-0500',
        'quantity': [6.8],  // only one segment therefore only one element
        // 'price': [...],  // can have a price array too if bid type is not fixed
      });
      expect(aux.length, 791);
    });
    test('read 2020-09-01 from webservices', () async {
      var asOfDate = Date.utc(2020, 9, 1);
      var file = archive.getFilename(asOfDate);
      if (!file.existsSync()) {
        await archive.downloadDay(asOfDate);
      }
      var data = archive.processFile(file);
      expect(data.length, 749);
      var aux0 = data.first;
      expect(aux0.keys.toSet(), {
        'date', 'Masked Lead Participant ID', 'Masked Location ID',
        'Location Type', 'Bid Type', 'Bid ID', 'hours',
      });
      expect(aux0['date'], '2020-09-01');
      expect(aux0['Masked Lead Participant ID'], 110487);
      expect(aux0['Masked Location ID'], 41756);
      expect(aux0['Location Type'], 'LOAD ZONE');
      expect(aux0['Bid Type'], 'FIXED');  // can also be DEC, INC, PRICE
      expect(aux0['Bid ID'], 16403780);
      expect((aux0['hours'] as List).length, 24);
      var h0 = (aux0['hours'] as List).first as Map<String,dynamic>;
      expect(h0, {
        'hourBeginning': '2020-09-01T00:00:00.000-04:00',
        'quantity': [5.6],  // only one segment therefore only one element
        // 'price': [...],  // can have a price array too if bid type is not fixed
      });
      var aux46 = data[46];
      h0 = (aux46['hours'] as List).first as Map<String,dynamic>;
      expect(h0, {
        'hourBeginning': '2020-09-01T13:00:00.000-04:00',
        'quantity': [0.9, 0.9],  // two segments
        'price': [-10, 0],  // two segments
      });


    });

  });
}


Future insertDays() async {
  var location = getLocation('America/New_York');
  var archive = DaDemandBidArchive();
  var days = Interval(TZDateTime(location, 2019, 2, 1),
      TZDateTime(location, 2019, 2, 28))
      .splitLeft((dt) => Date.utc(dt.year, dt.month, dt.day));
  await archive.dbConfig.db.open();

  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}


Future soloTest() async {
  var archive = DaDemandBidArchive();
  var data = archive.processFile(archive.getFilename(Date.utc(2017,3,12)));
  print(data);
}


Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');

  //await new DaDemandBidArchive().setupDb();
//  await prepareData();

  //await DaEnergyOffersTest();

  tests();

  // await insertDays();

  //await new DaDemandBidArchive().updateDb();

  //await soloTest();
}

