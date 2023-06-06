library test.db.isoexpress.da_demand_bid_test;

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:table/table_base.dart';
import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_demand_bid.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:elec_server/api/isoexpress/api_isone_demandbids.dart';
import 'package:timezone/timezone.dart';

Future<void> tests() async {
  group('DA demand bid report (masked bids), 2019-02-28', () {
    var archive = DaDemandBidArchive();
    test('process file 2019-02-28.csv', () {
      var file = File('${archive.dir}hbdayaheaddemandbid_20190228.csv');
      var aux = archive.processCsvFile(file);
      var aux0 = aux.first;
      expect(aux0.keys.toSet(), {
        'date',
        'Masked Lead Participant ID',
        'Masked Location ID',
        'Location Type',
        'Bid Type',
        'Bid ID',
        'hours',
      });
      expect(aux0['date'], '2019-02-28');
      expect(aux0['Masked Lead Participant ID'], 110487);
      expect(aux0['Masked Location ID'], 41756);
      expect(aux0['Location Type'], 'LOAD ZONE');
      expect(aux0['Bid Type'], 'FIXED'); // can also be DEC, INC, PRICE
      expect(aux0['Bid ID'], '16403780'); // this should be an integer!
      expect((aux0['hours'] as List).length, 24);
      var h0 = (aux0['hours'] as List).first as Map<String, dynamic>;
      expect(h0, {
        'hourBeginning': '2019-02-28T00:00:00.000-0500',
        'quantity': [6.8], // only one segment therefore only one element
        // 'price': [...],  // can have a price array too if bid type is not fixed
      });
      expect(aux.length, 791);
    });
    test('read 2020-09-01 json file', () async {
      var asOfDate = Date.utc(2020, 9, 1);
      var file = archive.getFilename(asOfDate);
      if (!file.existsSync()) {
        await archive.downloadDay(asOfDate);
      }
      var data = archive.processFile(file);
      expect(data.length, 749);
      var aux0 = data.first;
      expect(aux0.keys.toSet(), {
        'date',
        'Masked Lead Participant ID',
        'Masked Location ID',
        'Location Type',
        'Bid Type',
        'Bid ID',
        'hours',
      });
      expect(aux0['date'], '2020-09-01');
      expect(aux0['Masked Lead Participant ID'], 110487);
      expect(aux0['Masked Location ID'], 41756);
      expect(aux0['Location Type'], 'LOAD ZONE');
      expect(aux0['Bid Type'], 'FIXED'); // can also be DEC, INC, PRICE
      expect(aux0['Bid ID'], 16403780);
      expect((aux0['hours'] as List).length, 24);
      var h0 = (aux0['hours'] as List).first as Map<String, dynamic>;
      expect(h0, {
        'hourBeginning': '2020-09-01T00:00:00.000-0400', // correct ISO-8601
        'quantity': [5.6], // only one segment therefore only one element
        // 'price': [...],  // can have a price array too if bid type is not fixed
      });
      var aux46 = data[46];
      h0 = (aux46['hours'] as List).first as Map<String, dynamic>;
      expect(h0, {
        'hourBeginning': '2020-09-01T13:00:00.000-0400',
        'quantity': [0.9, 0.9], // two segments
        'price': [-10, 0], // two segments
      });
    });
    test('read 2023-02-01 json file', () async {
      /// format changed!
      var asOfDate = Date.utc(2023, 2, 1);
      var file = archive.getFilename(asOfDate);
      if (!file.existsSync()) {
        await archive.downloadDay(asOfDate);
      }
      var data = archive.processFile(file);
      expect(data.length, 881);
      var aux0 = data.first;
      expect(aux0.keys.toSet(), {
        'date',
        'Masked Lead Participant ID',
        'Masked Location ID',
        'Location Type',
        'Bid Type',
        'Bid ID',
        'hours',
      });
      expect(aux0['date'], '2023-02-01');
      expect(aux0['Masked Lead Participant ID'], 104136);
      expect(aux0['Masked Location ID'], 28934);
      expect(aux0['Location Type'], 'LOAD ZONE');
      expect(aux0['Bid Type'], 'FIXED'); // can also be DEC, INC, PRICE
      expect(aux0['Bid ID'], 784447620);
      expect((aux0['hours'] as List).length, 24);
      var h0 = (aux0['hours'] as List).first as Map<String, dynamic>;
      expect(h0, {
        'hourBeginning': '2023-02-01T00:00:00.000-0500', // correct ISO-8601
        'quantity': [11.7], // only one segment therefore only one element
        // 'price': [...],  // can have a price array too if bid type is not fixed
      });
    }, solo: true);
  });
  group('api tests for demand bids', () {
    var db = Db('mongodb://localhost/isoexpress');
    var api = DaDemandBids(db);
    setUp(() async {
      await db.open();
    });
    tearDown(() async {
      await db.close();
    });
    test('get demand bids stack for one hour from all participants', () async {
      var data = await api.getDemandBidsStack('20170701', '16');
      expect(data.length, 906);
    });
    test('get daily MWh by load zone for participant', () async {
      var participantId = 206845.toString();
      var start = '20170101';
      var end = '20170101';
      var data = await api.dailyMwhDemandBidByZoneForParticipant(
          participantId, start, end);
      var nema = data.firstWhere((Map e) => e['locationId'] == 37894);
      expect(nema['MWh'], 11435.3);
    });
    test('total daily MWh by participant', () async {
      var data = await api.dailyMwhDemandBidByParticipantForZone(
          '20210101', '20210101',
          ptid: null);
      var x = data.firstWhere((Map e) => e['participantId'] == 206845);
      expect(x['MWh'], 46099.8);
    });
    test('total daily MWh by participant for zone', () async {
      var data = await api.dailyMwhDemandBidByParticipantForZone(
          '20210101', '20210101',
          ptid: 4004);
      var x = data.firstWhere((Map e) => e['participantId'] == 206845);
      expect(x['MWh'], 5204.5);
    });
    test('total daily MWh for participant,zone', () async {
      var participantId = '206845';
      var start = '20170101';
      var end = '20170105';
      var ptid = '4008';
      var data = await api.dailyMwhDemandBidForParticipantZone(
          participantId, ptid, start, end);
      expect(data.length, 5);
    });

    // test('total monthly MWh by participant for zone', () async {
    //   var start = '202101';
    //   var end = '202102';
    //   var ptid = 4004;
    //   var data = await api.monthlyMwhDemandBidByParticipantForZone(start, end,
    //       ptid: ptid);
    //   expect(data.length, 63);
    //   expect(
    //       data.firstWhere(
    //           (e) => e['participantId'] == 218826 && 'month' == '2021-01'),
    //       {
    //         'participantId': 218826,
    //         'month': '2021-01',
    //         'MWh': 4017.3,
    //       });
    // });
    test('get daily total inc/dec MWh', () async {
      var start = '20170101';
      var end = '20170102';
      var data = await api.dailyMwhIncDec(start, end);
      var dec1 = data.firstWhere(
          (Map e) => e['Bid Type'] == 'DEC' && e['date'] == '2017-01-01');
      expect(dec1['MWh'], 20395.7);
    });

    test('get daily total inc/dec MWh by participant', () async {
      var start = '20170101';
      var end = '20170102';
      var data = await api.dailyMwhIncDecByParticipant(start, end);
      var dec1 = data.firstWhere((Map e) =>
          e['Bid Type'] == 'INC' &&
          e['date'] == '2017-01-01' &&
          e['participantId'] == 924442);
      expect(dec1['MWh'], 19200);
    });
  });
}

Future insertDays() async {
  var location = getLocation('America/New_York');
  var archive = DaDemandBidArchive();
  var days = Interval(
          TZDateTime(location, 2019, 2, 1), TZDateTime(location, 2019, 2, 28))
      .splitLeft((dt) => Date.utc(dt.year, dt.month, dt.day));
  await archive.dbConfig.db.open();

  for (var day in days) {
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

/// Look at load data
Future<void> analyzeData() async {
  var day = Date.utc(2021, 6, 1);
  var db = Db('mongodb://localhost/isoexpress');
  await db.open();
  var api = DaDemandBids(db);
  var data = await api.dailyMwhDemandBidByParticipantForZone(
      day.toString(), day.toString(),
      ptid: 4004);
  data.sort((a, b) => -a['MWh'].compareTo(b['MWh']));
  print(Table.from(data).toCsv());

  await db.close();
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');

  // await analyzeData();

  //await new DaDemandBidArchive().setupDb();
//  await prepareData();

  //await DaEnergyOffersTest();

  await tests();

  // await insertDays();

  //await new DaDemandBidArchive().updateDb();

  //await soloTest();
}
