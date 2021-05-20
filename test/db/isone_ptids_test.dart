library test.db.isone_ptids_test;

import 'dart:io';
import 'dart:convert';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:http/http.dart' as http;
//import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/other/ptids.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/other/isone_ptids.dart';
import 'package:elec_server/api/api_isone_ptids.dart';

var env = Platform.environment;

void downloadFile() async {
  var config = ComponentConfig()
    ..host = '127.0.0.1'
    ..dbName = 'isone'
    ..collectionName = 'pnode_table';
  var dir = env['HOME'] + '/Downloads/Archive/PnodeTable/Raw/';

  var archive = PtidArchive(config: config, dir: dir);
  var url =
      'https://www.iso-ne.com/static-assets/documents/2019/02/2.6.20_pnode_table_2019_02_05.xlsx';
  await archive.downloadFile(url);
}

void ingestionTest() async {
  var config = ComponentConfig()
    ..host = '127.0.0.1'
    ..dbName = 'isone'
    ..collectionName = 'pnode_table';
  var dir = env['HOME'] + '/Downloads/Archive/PnodeTable/Raw/';

  var archive = PtidArchive(config: config);
  //await archive.setup();

  var file = File(dir + 'pnode_table_2019_01_10.xlsx');
  await archive.db.open();
  await archive.insertMongo(file);
  await archive.db.close();
}

void tests(String rootUrl) async {
  // var rootUrl = dotenv.env['SHELF_ROOT_URL'];
  var config = ComponentConfig()
    ..host = '127.0.0.1'
    ..dbName = 'isone'
    ..collectionName = 'pnode_table';
  var dir = env['HOME'] + '/Downloads/Archive/PnodeTable/Raw/';
  var archive = PtidArchive(config: config, dir: dir);
  var api = ApiPtids(config.db);
  group('Ptid table db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('read file for 2019-02-05', () {
      var file = File(archive.dir + '2.6.20_pnode_table_2019_02_05.xlsx');
      var data = archive.readXlsx(file);
      expect(data.length, 1158);
      expect(data.first, {
        'ptid': 4000,
        'name': '.H.INTERNAL_HUB',
        'spokenName': 'HUB',
        'type': 'hub',
        'asOfDate': '2019-02-05'
      });
      expect(data[9]['type'], 'reserve zone');
    });
    test('read file for 2020-06-11', () {
      var file = File(archive.dir + 'pnode_table_2020_06_11.xlsx');
      var data = archive.readXlsx(file);
      expect(data.length, 1179);
      expect(data.first, {
        'ptid': 4000,
        'name': '.H.INTERNAL_HUB',
        'spokenName': 'HUB',
        'type': 'hub',
        'asOfDate': '2020-06-11'
      });
      expect(data[9]['type'], 'reserve zone');
      expect(data[19]['type'], 'demand response zone');
    });
  });
  group('Ptid table API tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('Get the list of available dates', () async {
      var res = await api.getAvailableAsOfDates();
      expect(res is List<String>, true);
    });
    test('Get the list of available dates (http)', () async {
      var res = await http.get(Uri.parse('$rootUrl/ptids/v1/dates'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body) as List;
      expect(data.first is String, true);
    });
    test('Get all the ptid information for one date (http)', () async {
      var res = await http.get(Uri.parse('$rootUrl/ptids/v1/current'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body);
      expect(data.length > 950, true);
      expect(data.first['ptid'], 4000);
      var me = data.firstWhere((e) => e['ptid'] == 4001);
      expect(me, {
        'ptid': 4001,
        'name': '.Z.MAINE',
        'spokenName': 'MAINE',
        'type': 'zone'
      });
    });
    test('Get the list of available dates for one ptid', () async {
      var aux = await api.apiPtid(1616);
      expect(aux.isNotEmpty, true);
      var res = await http.get(Uri.parse('$rootUrl/ptids/v1/ptid/1616'),
          headers: {'Content-Type': 'application/json'});
      var data = json.decode(res.body);
      expect(data is List, true);
      expect(data.map((e) => e['asOfDate']).contains('2019-01-10'), true);
    });
  });
  group('Ptid table client tests:', () {
    var client = PtidsApi(http.Client(), rootUrl: rootUrl);
    test('get current ptid table', () async {
      var data = await client.getPtidTable();
      expect(data.length > 950, true);
      expect(data.first['ptid'], 4000);
      var me = data.firstWhere((e) => e['ptid'] == 4001);
      expect(me, {
        'ptid': 4001,
        'name': '.Z.MAINE',
        'spokenName': 'MAINE',
        'type': 'zone'
      });
    });
    test('get asOfDates', () async {
      var dates = await client.getAvailableAsOfDates();
      expect(dates.isNotEmpty, true);
    });
    test('get ptids from a given zone', () async {
      var ptids = await client.getPtidsForZone('CT');
      expect(ptids.length > 100, true);
    });
  });
}

void main() async {
  initializeTimeZones();

//  await ingestionTest();

  DbProd();
  tests('http://127.0.0.1:8080');
}
