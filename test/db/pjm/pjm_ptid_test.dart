library test.db.pjm.pjm_ptid_test;


import 'dart:convert';

import 'package:elec_server/api/pjm/api_pjm_ptids.dart';
import 'package:elec_server/src/db/pjm/pjm_ptid.dart';
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
      var wHub = data.firstWhere((e) => e['ptid'] == 51288);
      expect(wHub.keys.toSet(),
          {'asOfDate', 'ptid', 'name', 'type', 'subtype', 'zoneName',
            'voltageLevel', 'effectiveDate', 'terminationDate'});

      /// issue with large ptids
      var d1 = data.firstWhere((e) => e['ptid'] == 2155501806);
      var e = json.encode(d1);
      expect(e.length, 205);
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
      expect(res.length > 13000, true);  // lots of nodes

      var d1 = res.firstWhere((e) => e['ptid'] == 2155501806);
      var e = json.encode(d1);
      expect(e.length, 205);
    });
    test('Get the list of available dates (http)', () async {
      var res = await http.get(Uri.parse('$rootUrl/pjm/ptids/v1/dates'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      expect(data.first is String, true);
    });
    test('Get all the ptid information for one date (http)', () async {
      var res = await http.get(Uri.parse('$rootUrl/pjm/ptids/v1/current'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body);
      expect(data.length > 13000, true);
      var wHub = data.firstWhere((e) => e['ptid'] == 51288);
      expect(wHub.keys.toSet(),
          {'ptid', 'name', 'type', 'subtype', 'zoneName',
            'voltageLevel', 'effectiveDate', 'terminationDate'});
    });
  });

  /// The client tests are moved together with the ISONE one in
  /// test/db/isone_ptids_test.dart.
}

void main() async {
  initializeTimeZones();

  var rootUrl = 'http://127.0.0.1:8080';
  tests(rootUrl);
}
