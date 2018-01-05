library test.isone_demandbids_test;

import 'package:test/test.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/api/api_isone_demandbids.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';

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
      var data = await api.getAggregateBids('20170701', '16');
      expect(data.length, 905);
    });
    test('get load zone MWh by day, participant', () async {
      var participantId = 206845.toString();
      var start = '20170101';
      var end = '20170101';
      var data = await api.mwhByDayParticipantLoadZone(participantId, start, end);
      Map nema = data.firstWhere((Map e) => e['locationId'] == 37894);
      expect(nema['MWh'], 11435.3);
    });
    test('market share', () async {
      var data = await api.marketShare('20170101', '20170101');
      var x = data.firstWhere((Map e) => e['participantId'] == 206845);
      expect(x['MWh'], 36709.3);
    });
  });
}

main() async {
  initializeTimeZoneSync(getLocationTzdb());

  await ApiTest();

//  await ApiTest(db);
//
//  await db.close();
}
