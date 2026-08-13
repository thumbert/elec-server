import 'dart:io';
import 'dart:convert';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/other/ptids.dart';
import 'package:logging/logging.dart';
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/client/isone/ptid_table.dart';

final env = Platform.environment;

void downloadFile() async {
  var config = ComponentConfig(
      host: '127.0.0.1', dbName: 'isone', collectionName: 'pnode_table');
  var dir = '${env['HOME']!}/Downloads/Archive/PnodeTable/Raw/';

  var archive = getIsonePtidArchive();
  var url =
      'https://www.iso-ne.com/static-assets/documents/2019/02/2.6.20_pnode_table_2019_02_05.xlsx';
  await archive.downloadFile(url);
}

void ingestionTest() async {
  var archive = getIsonePtidArchive();

  var file = File('${archive.dir}/pnode_table_2019_01_10.xlsx');
  await archive.db.open();
  await archive.insertMongo(file);
  await archive.db.close();
}

Future<void> tests(String rootUrl) async {
  var archive = getIsonePtidArchive();
  group('Ptid table db tests:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('read file for 2025-05-20', () {
      var file = File('${archive.dir}/pnode_table_2025_05_20.xlsx');
      var data = archive.readSheetNodes(file);
      expect(data.length, 1145);
      expect(data.first.activatedOn.toString(), '2025-05-20');
      // insert into DuckDB
      archive.insertDuckDb(data);
    });

    test('insert file for 2025-06-12', () {
      // var file = File('${archive.dir}/pnode_table_2025_06_12.xlsx');
      // var data = archive.readSheetNodes(file);
      // archive.insertDuckDb(data);

      archive.setupDb2();
    });

    test('read file for 2019-02-05', () {
      var file = File('${archive.dir}2.6.20_pnode_table_2019_02_05.xlsx');
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
      var file = File('${archive.dir}pnode_table_2020_06_11.xlsx');
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
      expect(data.where((e) => e['ptid'] == 4000).length, 1);
      expect(data.where((e) => e['ptid'] == 321).length, 1);
      var me = data.firstWhere((e) => e['ptid'] == 4001);
      expect(me, {
        'ptid': 4001,
        'name': '.Z.MAINE',
        'spokenName': 'MAINE',
        'type': 'zone'
      });
    });
  });
  group('Ptid table client tests:', () {
    var client = PtidsApi(http.Client(), rootUrl: rootUrl);
    test('get current ptid table for isone', () async {
      var data = await client.getPtidTable(region: 'isone');
      expect(data.length > 950, true);
      expect(data.where((e) => e['ptid'] == 4000).length, 1);
      expect(data.where((e) => e['ptid'] == 321).length, 1);
      var me = data.firstWhere((e) => e['ptid'] == 4001);
      expect(me, {
        'ptid': 4001,
        'name': '.Z.MAINE',
        'spokenName': 'MAINE',
        'type': 'zone'
      });
    });
    test('get current ptid table for nyiso', () async {
      var data = await client.getPtidTable(region: 'nyiso');
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
    test('get current ptid table for pjm', () async {
      var data = await client.getPtidTable(region: 'pjm');
      var fitz = data.firstWhere((e) => e['ptid'] == 51288);
      expect(fitz.keys.toSet(), {
        'ptid',
        'name',
        'type',
        'subtype',
        'zoneName',
        'voltageLevel',
        'effectiveDate',
        'terminationDate'
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

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS ptid_table (
    node_type ENUM('hub', 'node', 'load', 'load_zone', 'aggregation_zone', 'reserve_zone', 'interface') NOT NULL,
    ptid INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    substation_name VARCHAR,
    unit_name VARCHAR,
    unit_short_name VARCHAR,
    zone_id INTEGER,
    reserve_id INTEGER,
    rsp_area VARCHAR,
    dispatch_zone VARCHAR,
    dr_reserve_aggregation_zone_id INTEGER,
    activated_on DATE NOT NULL,
    deactivated_on DATE
);
''';
  final generator = CodeGenerator(
    sql,
    apiRoute: '/isone/ptid_table',
    onlyFilters: ['node_type', 'deactivated_on', 'activated_on'],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

void main() async {
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  await tests(dotenv.env['ROOT_URL']!);

  // generateCode();
}
