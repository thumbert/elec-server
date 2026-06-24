import 'package:elec_server/client/hq/fuel_mix.dart' as client;
import 'package:reduct/reduct.dart';
import 'package:timezone/data/latest.dart';

import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/timezone.dart';

// import 'client//hq/fuel_mix/fuel_mix.dart' as client;

Future<void> tests(String rootUrl) async {
  group('Client tests for /hq/fuel_mix', () {
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
          ..zonedGte = TZDateTime(getLocation('America/New_York'), 2025, 1, 1)
          ..zonedLt = TZDateTime(getLocation('America/New_York'), 2025, 1, 3),
        rootUrl: rootUrl,
      );
      expect(records.length, 48);
    });
  });
}

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS fuel_mix (
    zoned TIMESTAMPTZ NOT NULL,
    total INT64 NOT NULL,
    hydro INT64 NOT NULL,
    wind INT64 NOT NULL,
    solar INT64 NOT NULL,
    other INT64 NOT NULL,
    thermal INT64 NOT NULL
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/hq/fuel_mix',
    onlyFilters: ['zoned'],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

Future<void> main() async {
  dotenv.load('.env/prod.env');
  initializeTimeZones();
  final rootUrl = dotenv.env['RUST_SERVER']!;
  await tests(rootUrl);

  // generateCode();
}
