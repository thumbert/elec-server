library test.isone_demandbids_test;

import 'dart:convert';
import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/api/isoexpress/api_isone_demandbids.dart';

void tests() async {
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
      expect(data.length, 905);
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
      var data =
          await api.dailyMwhDemandBidByParticipant('20170101', '20170101');
      var x = data.firstWhere((Map e) => e['participantId'] == 206845);
      expect(x['MWh'], 36709.3);
    });
    test('mwh by participant,zone,day', () async {
      var participantId = '206845';
      var start = '20170101';
      var end = '20170105';
      var ptid = 4008.toString();
      var data = await api.dailyMwhDemandBidForParticipantZone(
          participantId, ptid, start, end);
      expect(data.length, 5);
    });

    test('get daily total inc/dec MWh', () async {
      var start = '20170101';
      var end = '20170102';
      var data = await api.dailyMwhIncDec(start, end);
      var dec1 = data.firstWhere(
          (Map e) => e['Bid Type'] == 'DEC' && e['date'] == '2017-01-01');
      expect(dec1['MWh'], 20362.1);
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

void main() async {
  initializeTimeZones();

  tests();

//  await ApiTest(db);
//
//  await db.close();
}
