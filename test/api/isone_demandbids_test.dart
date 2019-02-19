library test.isone_demandbids_test;

import 'dart:convert';
import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/api/api_isone_demandbids.dart';

ApiTest() async {
  group('api tests for demand bids', () {
    Db db = new Db('mongodb://localhost/isoexpress');
    var api = new DaDemandBids(db);
    setUp(() async {
      await db.open();
    });
    tearDown(() async {
      await db.close();
    });
    test('get demand bids stack for one hour from all participants',
        () async {
      var aux = await api.getDemandBidsStack('20170701', '16');
      var data = json.decode(aux.result);
      expect(data.length, 905);
    });
    test('get daily MWh by load zone for participant', () async {
      var participantId = 206845.toString();
      var start = '20170101';
      var end = '20170101';
      var aux = await api.dailyMwhByZoneForParticipant(participantId, start, end);
      var data = (json.decode(aux.result) as List).cast<Map>();
      var nema = data.firstWhere((Map e) => e['locationId'] == 37894);
      expect(nema['MWh'], 11435.3);
    });
    test('total daily MWh by participant', () async {
      var aux = await api.dailyMwhByParticipant('20170101', '20170101');
      var data = (json.decode(aux.result) as List).cast<Map>();
      var x = data.firstWhere((Map e) => e['participantId'] == 206845);
      expect(x['MWh'], 36709.3);
    });
    test('mwh by participant,zone,day', () async {
      var participantId = '206845';
      var start = '20170101';
      var end = '20170105';
      var ptid = 4008.toString();
      var aux = await api.dailyMwhForParticipantZone(participantId, ptid, start, end);
      var data = json.decode(aux.result);
      expect(data.length, 5);
    });
    
    test('get daily total inc/dec MWh', () async {
      var start = '20170101';
      var end = '20170102';
      var aux = await api.dailyMwhIncDec(start, end);
      var data = (json.decode(aux.result) as List).cast<Map>();
      var dec1 = data.firstWhere((Map e) => e['Bid Type'] == 'DEC'
          && e['date'] == '2017-01-01');
      expect(dec1['MWh'], 20362.1);
    });

    test('get daily total inc/dec MWh by participant', () async {
      var start = '20170101';
      var end = '20170102';
      var aux = await api.dailyMwhIncDecByParticipant(start, end);
      var data = (json.decode(aux.result) as List).cast<Map>();
      var dec1 = data.firstWhere((Map e) => e['Bid Type'] == 'INC'
          && e['date'] == '2017-01-01' && e['participantId'] == 924442);
      expect(dec1['MWh'], 19200);
    });

    
  });
}

main() async {
  await initializeTimeZone();

  await ApiTest();

//  await ApiTest(db);
//
//  await db.close();
}
