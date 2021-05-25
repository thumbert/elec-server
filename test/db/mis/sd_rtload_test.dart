library db.mis.sd_rtload_test;

import 'dart:convert';
import 'dart:io';

import 'package:elec_server/api/mis/api_sd_rtload.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/mis/sd_rtload.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:path/path.dart';

void tests() async {
  var archive = SdRtloadArchive();
  group('RT Load archive tests: ', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('import file', () {
      var file = Directory('test/_assets')
          .listSync()
          .where((e) => basename(e.path).startsWith('sd_rtload_'))
          .first;
      var data = archive.processFile(file as File);
      expect(data.keys.toSet(), {0}); // only one tab
      var xs = data[0]!;
      expect(xs.length, 5); // 5 load asset ids
      expect(xs.first.keys.toSet(), {
        'date',
        'version',
        'Asset ID',
        'hourBeginning',
        'Load Reading',
        'Ownership Share',
        'Share of Load Reading'
      });
    });
  });
  group('RT Load API tests: ', () {
    var db = DbProd.mis;
    var api = SdRtload(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('return last settlement for several ids', () async {
      var start = '2013-06-01';
      var assetIds = '201,202';
      var data = await api.hourlyRtLoadForAssetIdsLastSettlement(
          start, start, assetIds);
      expect(data.length, 2); // two asset ids
      var x0 = data.first;
      expect(x0.keys.toSet(), {
        'date',
        'Asset ID',
        'Load Reading',
        'Ownership Share',
        'Share of Load Reading'
      });
      expect(x0['Asset ID'], 201); // ordered
    });
  });
}

void main() async {
  initializeTimeZones();
  DbProd();
  tests();
}
