import 'dart:convert';

import 'package:elec_server/api/nyiso/api_nyiso_ptids.dart';
import 'package:elec_server/src/db/nyiso/nyiso_ptid.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  var archive = PtidArchive();
  group('NYISO ptid archive db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read latest file', () async {
      var date = archive.lastDate();
      var data = archive.processData(date);
      var zoneF = data.firstWhere((e) => e['spokenName'] == 'Zone F');
      expect(zoneF.keys.toSet(),
          {'asOfDate', 'ptid', 'name', 'spokenName', 'type'});
      var fitz = data.firstWhere((e) => e['ptid'] == 23598);
      expect(fitz.keys.toSet(), {
        'asOfDate',
        'ptid',
        'name',
        'type',
        'zoneName',
        'zonePtid',
        'subzoneName',
        'lat/lon',
      });
    });
  });
  group('Ptid table API tests:', () {
    var api = ApiPtids(archive.db);
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('Get the list of available dates', () async {
      var res = await api.getAvailableAsOfDates();
      expect(res.isNotEmpty, true);
    });
    test('Get the current table', () async {
      var res = await api.ptidTableCurrent();
      expect(res.length > 550, true);
    });

    test('Get the list of available dates (http)', () async {
      var res = await http.get(Uri.parse('$rootUrl/nyiso/ptids/v1/dates'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      expect(data.first is String, true);
    });
    test('Get all the ptid information for one date (http)', () async {
      var res = await http.get(Uri.parse('$rootUrl/nyiso/ptids/v1/current'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body);
      expect(data.length > 550, true);
      var fitz = data.firstWhere((e) => e['ptid'] == 23598);
      expect(fitz.keys.toSet(), {
        'ptid',
        'name',
        'type',
        'zoneName',
        'zonePtid',
        'subzoneName',
        'lat/lon',
      });
    });
    test('Get the list of available dates for one ptid', () async {
      var aux = await api.apiPtid(23598);
      expect(aux.isNotEmpty, true);
      var res = await http.get(Uri.parse('$rootUrl/nyiso/ptids/v1/ptid/23598'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body);
      expect(data is List, true);
    });
  });

  /// The client tests are moved together with the ISONE one.
}

void main() async {
  initializeTimeZones();

  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
