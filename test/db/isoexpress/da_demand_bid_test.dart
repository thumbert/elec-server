import 'dart:io';

import 'package:collection/collection.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec_server/utils.dart';
import 'dart:async';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

Future<void> tests() async {
  group('DA demand bid report (masked bids), 2019-02-28', () {
    final archive = getIsoneDemandBidsArchive();
    test('read 2025-01-01 json file', () async {
      var asOfDate = Date.utc(2025, 1, 1);
      var file = archive.getFilename(asOfDate);
      if (!file.existsSync()) {
        await archive.downloadDay(asOfDate);
      }
      final data = archive.processFileJson(file);
      expect(data.length, 19513);
      final x0 = data.first;
      expect(x0.hourBeginning, TZDateTime(IsoNewEngland.location, 2025, 1, 1));
      expect(x0.maskedParticipantId, 104136);
      expect(x0.maskedLocationId, 28934);
      expect(x0.locationType, 'LOAD ZONE');
      expect(x0.bidType, 'FIXED');
      expect(x0.bidId, 784447620);
      expect(x0.segment, 0);
      expect(x0.mw, 65.7);
    });

    test('read 2023-01-01 json file', () async {
      var asOfDate = Date.utc(2023, 1, 1);
      var file = archive.getFilename(asOfDate);
      final data = archive.processFileJson(file);
      expect(data.length, 19243);
      final x0 = data.first;
      expect(x0.hourBeginning, TZDateTime(IsoNewEngland.location, 2023, 1, 1));
      expect(x0.maskedParticipantId, 104136);
      expect(x0.maskedLocationId, 28934);
      expect(x0.locationType, 'LOAD ZONE');
      expect(x0.bidType, 'FIXED');
      expect(x0.bidId, 784447620);
      expect(x0.segment, 0);
      expect(x0.price, null);
      expect(x0.mw, 6.9);
    });
  });
  // group('api tests for demand bids', () {
  //   var db = Db('mongodb://localhost/isoexpress');
  //   var api = DaDemandBids(db);
  //   setUp(() async {
  //     await db.open();
  //   });
  //   tearDown(() async {
  //     await db.close();
  //   });
  //   test('get demand bids stack for one hour from all participants', () async {
  //     var data = await api.getDemandBidsStack('20170701', '16');
  //     expect(data.length, 906);
  //   });
  //   test('get daily MWh by load zone for participant', () async {
  //     var participantId = 206845.toString();
  //     var start = '20170101';
  //     var end = '20170101';
  //     var data = await api.dailyMwhDemandBidByZoneForParticipant(
  //         participantId, start, end);
  //     var nema = data.firstWhere((Map e) => e['locationId'] == 37894);
  //     expect(nema['MWh'], 11435.3);
  //   });
  //   test('total daily MWh by participant', () async {
  //     var data = await api.dailyMwhDemandBidByParticipantForZone(
  //         '20210101', '20210101',
  //         ptid: null);
  //     var x = data.firstWhere((Map e) => e['participantId'] == 206845);
  //     expect(x['MWh'], 46099.8);
  //   });
  //   test('total daily MWh by participant for zone', () async {
  //     var data = await api.dailyMwhDemandBidByParticipantForZone(
  //         '20210101', '20210101',
  //         ptid: 4004);
  //     var x = data.firstWhere((Map e) => e['participantId'] == 206845);
  //     expect(x['MWh'], 5204.5);
  //   });
  //   test('total daily MWh for participant,zone', () async {
  //     var participantId = '206845';
  //     var start = '20170101';
  //     var end = '20170105';
  //     var ptid = '4008';
  //     var data = await api.dailyMwhDemandBidForParticipantZone(
  //         participantId, ptid, start, end);
  //     expect(data.length, 5);
  //   });

  //   // test('total monthly MWh by participant for zone', () async {
  //   //   var start = '202101';
  //   //   var end = '202102';
  //   //   var ptid = 4004;
  //   //   var data = await api.monthlyMwhDemandBidByParticipantForZone(start, end,
  //   //       ptid: ptid);
  //   //   expect(data.length, 63);
  //   //   expect(
  //   //       data.firstWhere(
  //   //           (e) => e['participantId'] == 218826 && 'month' == '2021-01'),
  //   //       {
  //   //         'participantId': 218826,
  //   //         'month': '2021-01',
  //   //         'MWh': 4017.3,
  //   //       });
  //   // });
  //   test('get daily total inc/dec MWh', () async {
  //     var start = '20170101';
  //     var end = '20170102';
  //     var data = await api.dailyMwhIncDec(start, end);
  //     var dec1 = data.firstWhere(
  //         (Map e) => e['Bid Type'] == 'DEC' && e['date'] == '2017-01-01');
  //     expect(dec1['MWh'], 20395.7);
  //   });

  //   test('get daily total inc/dec MWh by participant', () async {
  //     var start = '20170101';
  //     var end = '20170102';
  //     var data = await api.dailyMwhIncDecByParticipant(start, end);
  //     var dec1 = data.firstWhere((Map e) =>
  //         e['Bid Type'] == 'INC' &&
  //         e['date'] == '2017-01-01' &&
  //         e['participantId'] == 924442);
  //     expect(dec1['MWh'], 19200);
  //   });
  // });
}

/// Look at Calpine load data
void analyzeData() {
  final archive = getIsoneDemandBidsArchive();
  final conn = Connection(archive.duckdbPath);
  final query = '''
SELECT strftime(hourBeginning, '%Y-%m-%d') as day, 
    maskedParticipantId, 
    round(sum(mw)/24) as mw
FROM da_bids
WHERE hourBeginning >= '2022-01-01'
AND hourBeginning < '2024-09-30'
AND bidType in ('FIXED', 'PRICE')
AND locationType = 'LOAD ZONE'
AND maskedParticipantId in (504170, 212494)
GROUP BY day, maskedParticipantId
ORDER BY maskedParticipantId, day;
''';
  final data = conn.fetchRows(query, (List row) => [row[0], row[1], row[2]]);
  // print(data);
  conn.close();

  var groups = groupBy(data, (e) => e[1]);
  var traces = <Map<String, dynamic>>[];
  for (var id in groups.keys) {
    var vs = groups[id]!;
    traces.add({
      'x': vs.map((e) => e[0]).toList(),
      'y': vs.map((e) => e[2]).toList(),
      'name': '$id',
    });
  }
  // print(traces);
  const layout = {
    'title': '',
    'height': 650,
    'width': 1100,
    'yaxis': {'title': 'MW'},
  };

  Plotly.now(traces, layout,
      file: File('/home/adrian/Downloads/hist_load.html'));
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  await tests();

  // analyzeData();
}
