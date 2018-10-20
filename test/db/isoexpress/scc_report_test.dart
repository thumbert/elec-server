library test.db.isoexpress.scc_report_test;

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/isoexpress/scc_report.dart';

Map env = Platform.environment;

downloadFile() async {
  ComponentConfig config = new ComponentConfig()
    ..host = '127.0.0.1'
    ..dbName = 'isone'
    ..collectionName = 'scc_report';
  String dir = env['HOME'] + '/Downloads/Archive/IsoExpress/OperationsReports/SeasonalClaimedCapability/Raw/';

  var archive = new SccReportArchive(config: config, dir: dir);
  String url =
    'https://www.iso-ne.com/static-assets/documents/2018/10/scc_october_2018.xls';
  archive.downloadFile(url);
}

ingestionTest() async {
  ComponentConfig config = new ComponentConfig()
    ..host = '127.0.0.1'
    ..dbName = 'isone'
    ..collectionName = 'scc_report';
  String dir = env['HOME'] + '/Downloads/Archive/IsoExpress/OperationsReports/SeasonalClaimedCapability/Raw/';

  var archive = new SccReportArchive(config: config, dir: dir);
  //await archive.setup();

  File file = new File(dir + 'scc_october_2018.xlsx');
  var data = await archive.readXlsx(file)
  
  await archive.db.open();
  await archive.insertMongo(file);
  await archive.db.close();
}

//apiTest() async {
//  group('Ptid table tests:', () {
//    ComponentConfig config;
//    PtidArchive archive;
//    ApiPtids api;
//    setUp(() async {
//      config = new ComponentConfig()
//        ..host = '127.0.0.1'
//        ..dbName = 'isone'
//        ..collectionName = 'pnode_table';
//      String dir = env['HOME'] + '/Downloads/Archive/PnodeTable/Raw/';
//      archive = new PtidArchive(config: config, dir: dir);
//
//      api = new ApiPtids(config.db);
//      await config.db.open();
//    });
//    tearDown(() async {
//      await config.db.close();
//    });
//    test('read file for 2017-09-19', () {
//      File file = new File(archive.dir + 'pnode_table_2017_09_19.xlsx');
//      var data = archive.readXlsx(file);
//      expect(data.length, 1120);
//      expect(data.first, {'ptid': 4000, 'name': '.H.INTERNAL_HUB',
//        'spokenName': 'HUB', 'type': 'hub', 'asOfDate': '2017-09-19'});
//      expect(data[9]['type'], 'reserve zone');
//    });
//    test('read file for 2018-09-19', () {
//      File file = new File(archive.dir + 'pnode_table_2018_09_11.xlsx');
//      var data = archive.readXlsx(file);
//      expect(data.length, 1161);
//      expect(data.first, {'ptid': 4000, 'name': '.H.INTERNAL_HUB',
//        'spokenName': 'HUB', 'type': 'hub', 'asOfDate': '2018-09-11'});
//      expect(data[9]['type'], 'reserve zone');
//      expect(data[19]['type'], 'demand response zone');
//    });
//    test('Get the list of available dates', () async {
//      var res = await api.getAvailableAsOfDates();
//      expect(res is List<String>, true);
//    });
//    test('Get the list of available dates (http)', () async {
//      var url = 'http://localhost:8080/ptids/v1/dates';
//      var res = await get(url);
//      var data = json.decode(res.body);
//      expect(data is List, true);
//      expect(data.first is String, true);
//    });
//    test('Get all the ptid information for one date (http)', () async {
//      var url = 'http://localhost:8080/ptids/v1/current';
//      var res = await get(url);
//      var data = json.decode(json.decode(res.body)['result']);
//      expect(data.length > 950, true);
//      expect(data.first['ptid'], 4000);
//      var me = data.firstWhere((e) => e['ptid'] == 4001);
//      expect(me, {'ptid': 4001, 'name': '.Z.MAINE', 'spokenName': 'MAINE',
//        'type': 'zone'});
//    });
//
//  });
//}

main() async {
  await initializeTimeZone();

  await ingestionTest();

//  await apiTest();


}
