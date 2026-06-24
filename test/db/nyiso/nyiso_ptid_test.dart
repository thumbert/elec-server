
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:logging/logging.dart';
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/client/nyiso/ptid_table.dart' as client;


/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl) async {
  group('Client tests for nyiso/ptid_table', () {
    test('Query records test', () async {
      final records = await client.queryRecords(
        filter: client.QueryFilter(),
        limit: 5,
        rootUrl: dotenv.env['RUST_SERVER']!,
      );
      expect(records.length, 5);
    });
  });

}

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS ptid_table (
    node_type ENUM('gen', 'zone') NOT NULL,
    ptid INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    aggregation_ptid INTEGER,
    subzone VARCHAR,
    zone VARCHAR NOT NULL,
    latitude DOUBLE,
    longitude DOUBLE,
    active BOOLEAN NOT NULL,
    "asof" DATE NOT NULL
);
''';
  final generator = CodeGenerator(
    sql,
    apiRoute: '/nyiso/ptid_table',
    onlyFilters: ['node_type', 'zone'],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}



void main() async {
  initializeTimeZones();
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  dotenv.load('.env/test.env');
  // await tests(dotenv.env['ROOT_URL']!);
  generateCode();
}
