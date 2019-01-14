library test.db.isone_ptids_test;

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/other/isone_ptids.dart';
import 'package:elec_server/api/api_isone_ptids.dart';

Map env = Platform.environment;

downloadFile() async {
  ComponentConfig config = new ComponentConfig()
    ..host = '127.0.0.1'
    ..dbName = 'isone'
    ..collectionName = 'pnode_table';
  String dir = env['HOME'] + '/Downloads/Archive/PnodeTable/Raw/';

  var archive = new PtidArchive(config: config, dir: dir);
  String url =
      'https://www.iso-ne.com/static-assets/documents/2019/01/2.6.19_pnode_table_2019_01_10.xls';
  archive.downloadFile(url);
}

ingestionTest() async {
  ComponentConfig config = new ComponentConfig()
    ..host = '127.0.0.1'
    ..dbName = 'isone'
    ..collectionName = 'pnode_table';
  String dir = env['HOME'] + '/Downloads/Archive/PnodeTable/Raw/';

  var archive = new PtidArchive(config: config);
  //await archive.setup();

  File file = new File(dir + 'pnode_table_2019_01_10.xlsx');
  await archive.db.open();
  await archive.insertMongo(file);
  await archive.db.close();
}

apiTest() async {
  group('Ptid table tests:', () {
    ComponentConfig config;
    PtidArchive archive;
    ApiPtids api;
    setUp(() async {
      config = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isone'
        ..collectionName = 'pnode_table';
      String dir = env['HOME'] + '/Downloads/Archive/PnodeTable/Raw/';
      archive = new PtidArchive(config: config, dir: dir);

      api = new ApiPtids(config.db);
      await config.db.open();
    });
    tearDown(() async {
      await config.db.close();
    });
    test('read file for 2017-09-19', () {
      File file = new File(archive.dir + 'pnode_table_2017_09_19.xlsx');
      var data = archive.readXlsx(file);
      expect(data.length, 1120);
      expect(data.first, {'ptid': 4000, 'name': '.H.INTERNAL_HUB',
        'spokenName': 'HUB', 'type': 'hub', 'asOfDate': '2017-09-19'});
      expect(data[9]['type'], 'reserve zone');
    });
    test('read file for 2018-09-19', () {
      File file = new File(archive.dir + 'pnode_table_2018_09_11.xlsx');
      var data = archive.readXlsx(file);
      expect(data.length, 1161);
      expect(data.first, {'ptid': 4000, 'name': '.H.INTERNAL_HUB',
        'spokenName': 'HUB', 'type': 'hub', 'asOfDate': '2018-09-11'});
      expect(data[9]['type'], 'reserve zone');
      expect(data[19]['type'], 'demand response zone');
    });
    test('Get the list of available dates', () async {
      var res = await api.getAvailableAsOfDates();
      expect(res is List<String>, true);
    });
    test('Get the list of available dates (http)', () async {
      var url = 'http://localhost:8080/ptids/v1/dates';
      var res = await get(url);
      var data = json.decode(res.body);
      expect(data is List, true);
      expect(data.first is String, true);
    });
    test('Get all the ptid information for one date (http)', () async {
      var url = 'http://localhost:8080/ptids/v1/current';
      var res = await get(url);
      var data = json.decode(json.decode(res.body)['result']);
      expect(data.length > 950, true);
      expect(data.first['ptid'], 4000);
      var me = data.firstWhere((e) => e['ptid'] == 4001);
      expect(me, {'ptid': 4001, 'name': '.Z.MAINE', 'spokenName': 'MAINE',
        'type': 'zone'});
    });
    test('Get the list of available dates for one ptid (http)', () async {
      var url = 'http://localhost:8080/ptids/v1/ptid/10348';
      var res = await get(url);
      var aux = json.decode(res.body);
      var data = json.decode(aux['result']) as List;
      expect(data is List, true);
      expect(data.map((e) => e['asOfDate']).contains('2019-01-10'), false);
    });
  });
}

main() async {
  await initializeTimeZone();

  //await ingestionTest();

  await apiTest();


}
