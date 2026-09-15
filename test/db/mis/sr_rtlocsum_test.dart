import 'dart:io';

import 'package:elec_server/api/mis/api_sr_rtlocsum.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:path/path.dart';
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/src/db/mis/sr_rtlocsum.dart';

void tests() async {
  var dir = Directory(
    '${Platform.environment['HOME']!}/Downloads/Archive/Mis/all_samples',
  );
  var file = dir
      .listSync()
      .where((e) => basename(e.path).startsWith('sr_rtlocsum_'))
      .first;
  var archive = SrRtLocSumArchive();

  setUp(() async {
    await archive.dbConfig.db.open();
    //await archive.setupDb();
  });
  tearDown(() async {
    await archive.dbConfig.db.close();
  });

  group('MIS report sr_rtlocsum', () {
    test('read report', () async {
      var data = archive.processFile(file as File);
      expect(data.length, 2);
      // await archive.insertTabData(data[0], tab: 0);
      // await archive.insertTabData(data[1], tab: 1);
    });
  });

  group('MIS report sr_rtlocsum api tests:', () {
    var db = DbProd.mis;
    var api = SrRtLocSum(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get daily rt energy settlement, all locations', () async {
      var data = await api.dailyRtSettlementForAccount(
        '000000001',
        '2015-06-01',
        '2015-06-01',
        0,
      );
      expect(data.length, 17);
    });
    test('get daily rt energy settlement, some locations', () async {
      var data = await api.dailyRtSettlementForAccountLocations(
        '000000001',
        '2015-06-01',
        '2015-06-01',
        '401,402',
        0,
      );
      expect(data.length, 2);
    });
    test('get daily rt energy for subaccount, all locations', () async {
      var data = await api.dailyRtSettlementForSubaccount(
        '000000001',
        '9001',
        '2015-06-01',
        '2015-06-01',
        0,
      );
      expect(data.length, 17);
    });
    test('get daily rt energy for subaccount, some locations', () async {
      var data = await api.dailyRtSettlementForSubaccountLocations(
        '000000001',
        '9001',
        '2015-06-01',
        '2015-06-01',
        '401,402',
        0,
      );
      expect(data.length, 2);
    });
  });
}

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
    revenue_metered_generation DOUBLE,
    scheduled_imports DOUBLE,
    rt_generation_obligation DOUBLE,
    revenue_metered_load DOUBLE, 
    scheduled_exports DOUBLE, 
    internal_bilateral_for_load DOUBLE,
    rt_load_obligation DOUBLE,
    rt_internal_bilateral_for_market_purchases DOUBLE,
    rt_internal_bilateral_for_market_sales DOUBLE,
    rt_adjusted_load_obligation DOUBLE,
    rt_adjusted_net_interchange DOUBLE,
    adjusted_net_interchange_deviation DOUBLE,
    rt_energy_component DOUBLE,
    rt_congestion_component DOUBLE,
    rt_marginal_loss_component DOUBLE,
    rt_energy_charge_or_credit DOUBLE,
    rt_congestion_charge_or_credit DOUBLE,
    rt_loss_charge_or_credit DOUBLE,
    rt_internal_bilateral_for_market_purchases_impacting_mlrlo DOUBLE,
    rt_internal_bilateral_for_market_sales_impacting_mlrlo DOUBLE,
    marginal_loss_revenue_load_obligation DOUBLE, 
    rt_generation_obligation_for_charge_allocation DOUBLE, 
    rt_load_obligation_for_charge_allocation DOUBLE, 
    rt_adjusted_net_interchange_for_charge_allocation DOUBLE,
    rt_demand_reduction_obligation DOUBLE,
    rt_load_obligation_for_demand_reduction_allocation DOUBLE,
    demand_reduction_obligation_deviation DOUBLE,
    rt_demand_reduction_credit DOUBLE, 
    rt_demand_reduction_charge DOUBLE, 
    rt_satoa_obligation DOUBLE, 
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/isone/mis/sr_rtlocsum/tab1',
    onlyFilters: ['report_date', 'account_id', 'subaccount_id', 'location_id'],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

void main() async {
  initializeTimeZones();
  // DbProd();
  // tests();

  generateCode();
}
