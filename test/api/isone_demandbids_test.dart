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
    test('get aggregated demand bids for one hour from all participants',
        () async {
      var aux = await api.getDemandBidsStack('20170701', '16');
      var data = json.decode(aux.result);
      expect(data.length, 905);
    });
    test('get load zone MWh by day, participant', () async {
      var participantId = 206845.toString();
      var start = '20170101';
      var end = '20170101';
      var data = await api.mwhByDayZoneForParticipant(participantId, start, end);
      Map nema = data.firstWhere((Map e) => e['locationId'] == 37894);
      expect(nema['MWh'], 11435.3);
    });
    test('total MWh by participant', () async {
      var data = await api.totalMwhByParticipant('20170101', '20170101');
      var x = data.firstWhere((Map e) => e['participantId'] == 206845);
      expect(x['MWh'], 36709.3);
    });
    test('mwh by participant,zone,day', () async {
      var participantId = '206845';
      var start = '20170101';
      var end = '20170105';
      var ptid = 4008.toString();
      var data = await api.mwhByDayForParticipantAndZone(participantId, ptid, start, end);
      expect(data.length, 5);
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
