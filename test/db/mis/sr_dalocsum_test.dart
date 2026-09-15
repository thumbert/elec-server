import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
//import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:date/date.dart';
import 'package:elec_server/api/mis/api_sr_dalocsum.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/mis/sr_dalocsum.dart';
import 'package:path/path.dart';
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/client/mis/sr_dalocsum.dart' as client;

void tests(String rootUrl) async {
  // var rootUrl = dotenv.env['SHELF_ROOT_URL'];
  var dir = Directory('test/_assets');
  var file = dir
      .listSync()
      .where((e) => basename(e.path).startsWith('sr_dalocsum_'))
      .first;
  var archive = SrDaLocSumArchive();
  // await archive.setupDb();

  group('MIS report sr_dalocsum tests:', () {
    setUp(() async {
      await archive.dbConfig.db.open();
    });
    tearDown(() async {
      await archive.dbConfig.db.close();
    });
    test('read and insert report', () async {
      var data = archive.processFile(file as File);
      expect(data.length, 2);
      // await archive.insertTabData(data[0], tab: 0);
      // await archive.insertTabData(data[1], tab: 1);
    });
  });

  group('MIS report sr_dalocsum api tests:', () {
    var db = DbProd.mis;
    var api = SrDaLocSum(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get daily da energy settlement, all locations', () async {
      var data = await api.dailyDaSettlementForAccount(
        '000000003',
        '2013-06-03',
        '2013-06-03',
        0,
      );
      expect(data.length, 20);
    });
    test('get daily da energy settlement, some locations', () async {
      var data = await api.dailyDaSettlementForAccountLocations(
        '000000003',
        '2013-06-03',
        '2013-06-03',
        '401,402',
        0,
      );
      expect(data.length, 2);
    });
    test('get daily da energy for subaccount, all locations', () async {
      var data = await api.dailyDaSettlementForSubaccount(
        '000000003',
        '9001',
        '2013-06-03',
        '2013-06-03',
        0,
      );
      expect(data.length, 20);
    });
    test('get daily da energy for subaccount, some locations', () async {
      var data = await api.dailyDaSettlementForSubaccountLocations(
        '000000003',
        '9001',
        '2013-06-03',
        '2013-06-03',
        '401,402',
        0,
      );
      expect(data.length, 2);
    });
  });

  group('MIS report sr_dalocsum client tests', () {
    test('get one column for one zone, for account', () async {
      var url =
          '$rootUrl/sr_dalocsum/v1/accountId/000000003/locationId/401/column/Day Ahead Cleared Demand Bids/start/20130603/end/20130603';
      var res = await http.get(Uri.parse(url));
      var data = json.decode(res.body);
      expect(data.length, 24);
    });
    test('get one column for one zone, for subaccount', () async {
      var url =
          '$rootUrl/sr_dalocsum/v1/accountId/000000003/subaccountId/9001/locationId/401/column/Day Ahead Cleared Demand Bids/start/20130603/end/20130603';
      var res = await http.get(Uri.parse(url));
      var data = json.decode(res.body);
      expect(data.length, 24);
    });
  });

  group('Client tests for /mis/sr_dalocsum/tab1', () {
    test('Query records test', () async {
      final records = await client.queryRecords(
        filter: client.QueryFilter(),
        limit: 5,
        rootUrl: rootUrl,
      );
      expect(records.length, 5);
    });
  });
}

void insertMonths(List<Month> months) async {}

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS tab1 (
    report_date DATE NOT NULL,
    version TIMESTAMP NOT NULL,
    account_id UINTEGER NOT NULL,
    subaccount_id UINTEGER NOT NULL,
    subaccount_name VARCHAR NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    location_id UINTEGER NOT NULL,
    location_name VARCHAR NOT NULL,
    location_type ENUM ('LOAD ZONE', 'NETWORK NODE', 'HUB', 'DRR AGGREGATION ZONE') NOT NULL,
    da_cleared_generation DOUBLE,
    da_cleared_increments DOUBLE,
    da_cleared_imports DOUBLE,
    da_generation_obligation DOUBLE,
    da_cleared_demand_bids DOUBLE, 
    da_cleared_decrements DOUBLE, 
    da_cleared_exports DOUBLE, 
    da_load_obligation DOUBLE,
    da_internal_bilateral_for_purchases DOUBLE,
    da_internal_bilateral_for_sales DOUBLE,
    da_adjusted_load_obligation DOUBLE,
    da_adjusted_net_interchange DOUBLE,
    da_energy_component DOUBLE,
    da_congestion_component DOUBLE,
    da_marginal_loss_component DOUBLE,
    da_energy_charge_or_credit DOUBLE,
    da_congestion_charge_or_credit DOUBLE,
    da_marginal_loss_charge_or_credit DOUBLE,
    da_cleared_asset_related_demand_bids DOUBLE,
    da_load_obligation_for_charge_allocation DOUBLE,
    da_demand_reduction DOUBLE,
    da_demand_reduction_obligation DOUBLE,
    da_cleared_sodera_load DOUBLE,
    da_cleared_sodera_generation DOUBLE,
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/mis/sr_dalocsum/tab1',
    onlyFilters: ['report_date', 'account_id', 'subaccount_id', 'location_id'],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

void main() async {
  initializeTimeZones();
  // DbProd();
  // dotenv.load('.env/prod.env');
  // tests('http://127.0.0.1:8080');

  generateCode();
}
