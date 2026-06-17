import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/nyiso/binding_constraints.dart' as client;
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  group('Client tests for /nyiso/binding_constraints', () {
    test('Query records test', () async {
      final records = await client.queryRecords(
        filter: client.QueryFilter(),
        limit: 5,
        rootUrl: rootUrl,
      );
      expect(records.length, 5);
    });
    test('Query records test with hour_beginning filter', () async {
      final records = await client.queryRecords(
        filter: client.QueryFilter()
          ..hourBeginningGte =
              TZDateTime(getLocation('America/New_York'), 2026, 1, 1)
          ..hourBeginningLt =
              TZDateTime(getLocation('America/New_York'), 2026, 1, 2),
        limit: 5,
        rootUrl: rootUrl,
      );
      expect(records.length, 5);
    });
  });
}

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS binding_constraints (
    market ENUM('DA', 'RT') NOT NULL,
    hour_beginning TIMESTAMPTZ NOT NULL,
    limiting_facility VARCHAR NOT NULL,
    facility_ptid INT64 NOT NULL,
    contingency VARCHAR NOT NULL,
    constraint_cost DECIMAL(9,4) NOT NULL,
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/nyiso/binding_constraints',
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  await tests(dotenv.env['RUST_SERVER']!);

  // generateCode();
}
