import 'package:elec_server/client/nodal/contracts.dart' as client;
import 'package:reduct/reduct.dart';
import 'package:timezone/data/latest.dart';

import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> tests(String rootUrl) async {
  group('Client tests for /nodal/contracts', () {
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
CREATE TABLE IF NOT EXISTS contracts (
    physical_commodity_code VARCHAR NOT NULL,
    contract_long_name VARCHAR NOT NULL,
    contract_short_name VARCHAR NOT NULL,
    product_type VARCHAR NOT NULL,
    product_group VARCHAR NOT NULL,
    settlement_type VARCHAR NOT NULL,
    lot_limit_group VARCHAR NOT NULL,
    group_commodity_code VARCHAR NOT NULL,
    count_of_expiries INTEGER NOT NULL,
    block_exchange_fee DECIMAL(18,5) NOT NULL,
    screen_exchange_fee DECIMAL(18,5) NOT NULL,
    efp_exchange_fee DECIMAL(18,5),
    clearing_fee DECIMAL(18,5) NOT NULL,
    settlement_or_option_exercise_assignment_fee DECIMAL(18,5) NOT NULL,
    gmi_exch VARCHAR NOT NULL,
    gmi_fc VARCHAR NOT NULL,
    description VARCHAR NOT NULL,
    reporting_level VARCHAR,
    spot_month_position_limit_lots INTEGER NOT NULL,
    single_month_accountability_level_lots INTEGER NOT NULL,
    all_month_accountability_level_lots INTEGER NOT NULL,
    aggregation_group INTEGER,
    aggregation_group_type VARCHAR,
    parent_contract_flag BOOLEAN,
    cftc_referenced_contract BOOLEAN NOT NULL,
);
''';
  final generator = CodeGenerator(sql,
      apiRoute: '/nodal/contracts',
      onlyFilters: ['product_group']);
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

Future<void> main() async {
  initializeTimeZones();
  // generateCode();

  dotenv.load('.env/prod.env');
  await tests(dotenv.env['RUST_SERVER']!);
}
