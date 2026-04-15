import 'package:elec_server/client/ui/eod_settlements/views_asof_date.dart' as client;
import 'package:reduct/reduct.dart';
import 'package:timezone/data/latest.dart';

import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> tests(String rootUrl) async {
  group('Client tests for /ui/eod_settlements/asof_date', () {
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
CREATE TABLE IF NOT EXISTS views_asof_date (
    user_id VARCHAR NOT NULL,
    view_name VARCHAR NOT NULL,
    row_id UINTEGER NOT NULL,
    source VARCHAR NOT NULL,
    ice_category VARCHAR,
    ice_hub VARCHAR,
    ice_product VARCHAR,
    endur_curve_name VARCHAR,
    nodal_contract_name VARCHAR,
    as_of_date DATE NOT NULL,
    strip VARCHAR,
    unit_conversion VARCHAR,
    label VARCHAR,
);
''';
  final generator = CodeGenerator(
    sql,
    apiRoute: '/ui/eod_settlements/asof_date',
  );
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
