import 'package:elec_server/client/nyiso/capacity_season.dart' as client;
import 'package:reduct/reduct.dart';
import 'package:timezone/data/latest.dart';

import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> tests(String rootUrl) async {
  group('Client tests for /nyiso/capacity_seasons', () {
    test('Query records test', () async {
      final records = await client.queryRecords(
        limit: 5,
        rootUrl: rootUrl,
      );
      expect(records.length, 5);
    });
  });
}

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS capacity_seasons (
    id INT64 NOT NULL,
    description VARCHAR NOT NULL
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/nyiso/capacity_seasons',
    onlyFilters: [],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

Future<void> main() async {
  dotenv.load('.env/prod.env');
  initializeTimeZones();
  // await tests(dotenv.env['RUST_SERVER']!);

  generateCode();
}
