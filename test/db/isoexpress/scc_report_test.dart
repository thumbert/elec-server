library test.db.isoexpress.scc_report_test;

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/isoexpress/scc_report.dart';
import 'package:elec_server/api/api_scc_report.dart';


Map env = Platform.environment;

downloadFile() async {
  ComponentConfig config = new ComponentConfig()
    ..host = '127.0.0.1'
    ..dbName = 'isoexpress'
    ..collectionName = 'scc_report';
  String dir = env['HOME'] + '/Downloads/Archive/IsoExpress/OperationsReports/SeasonalClaimedCapability/Raw/';

  var archive = new SccReportArchive(config: config, dir: dir);
  await archive.setup();

  String url =
    'https://www.iso-ne.com/static-assets/documents/2018/10/scc_october_2018.xls';
  archive.downloadFile(url);
}

ingestionTest() async {
  ComponentConfig config = new ComponentConfig()
    ..host = '127.0.0.1'
    ..dbName = 'isoexpress'
    ..collectionName = 'scc_report';
  String dir = env['HOME'] + '/Downloads/Archive/IsoExpress/OperationsReports/SeasonalClaimedCapability/Raw/';

  var archive = new SccReportArchive(config: config, dir: dir);
  await archive.setup();

  File file = new File(dir + 'scc_october_2018.xlsx');
  var data = await archive.readXlsx(file, Month(2018,10));
  //print(data);

  await archive.db.open();
  await archive.insertData(data);
  await archive.db.close();
}

apiTest() async {
  group('SCC Report API tests:', () {
    ComponentConfig config;
    SccReport api;
    setUp(() async {
      config = new ComponentConfig()
        ..host = '127.0.0.1'
        ..dbName = 'isoexpress'
        ..collectionName = 'scc_report';

      api = SccReport(config.db);
      await config.db.open();
    });
    tearDown(() async {
      await config.db.close();
    });
    test('Get the months of the SCC report in the db', () async {
      var data = await api.getMonths();
      print(data.result);
      expect(true, true);
    });

//    test('Get the list of available months (http)', () async {
//      var url = 'http://localhost:8080/scc_report/v1/months';
//      var res = await get(url);
//      var data = json.decode(res.body);
//      expect(data is List, true);
//      expect(data.first is String, true);
//    });
    test('Get the SCC report for one month, all assets (http)', () async {
      var url = 'http://localhost:8080/scc_report/v1/month/2018-10';
      var res = await get(Uri.parse(url));
      var data = json.decode(json.decode(res.body)['result']);
      expect(data.length > 950, true);
    });

  });
}

void main() async {
  await initializeTimeZone();

//  await downloadFile();
//  await ingestionTest();

  await apiTest();


}
