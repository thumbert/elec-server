import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/isoexpress/binding_constraints.dart' as client;
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  group('Client tests for /isone/binding_constraints/da', () {
    test('Query records test', () async {
      final records = await client.queryRecords(
        filter: client.QueryFilter(),
        limit: 5,
        rootUrl: rootUrl,
      );
      expect(records.length, 5);
    });
    test('Query records test day', () async {
      final records = await client.queryRecords(
        filter: client.QueryFilter()
          ..hourBeginningGte = TZDateTime(getLocation('America/New_York'), 2025, 1, 1)
          ..hourBeginningLt = TZDateTime(getLocation('America/New_York'), 2025, 1, 3),
        rootUrl: rootUrl,
      );
      expect(records.length, 18);
    });
  });
}

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS constraints (
    hour_beginning TIMESTAMPTZ NOT NULL,
    constraint_name VARCHAR NOT NULL,
    contingency_name VARCHAR NOT NULL,
    marginal_value DECIMAL(9,2) NOT NULL,
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/isone/binding_constraints/da',
    onlyFilters: ['constraint_name', 'hour_beginning'],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

void main() async {
  dotenv.load('.env/prod.env');
  initializeTimeZones();
  final rootUrl = dotenv.env['RUST_SERVER']!;
  await tests(rootUrl);
  // generateCode();
}
