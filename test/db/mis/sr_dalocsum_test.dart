
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/client/mis/sr_dalocsum.dart' as client;

void tests(String rootUrl) async {
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
    apiRoute: '/isone/mis/sr_dalocsum/tab1',
    onlyFilters: ['report_date', 'account_id', 'subaccount_id', 'location_id'],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  tests(dotenv.env['RUST_SERVER']!);

  // generateCode();
}
