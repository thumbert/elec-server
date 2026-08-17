import 'package:elec_server/client/isone/participants.dart' as client;
import 'package:reduct/reduct.dart';
import 'package:timezone/data/latest.dart';

import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> tests(String rootUrl) async {
  group('Client tests for /isone/participant_list', () {
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
CREATE TABLE IF NOT EXISTS participants (
    as_of DATE NOT NULL,
    id INT64 NOT NULL,
    customer_name VARCHAR NOT NULL,
    address1 VARCHAR,
    address2 VARCHAR,
    address3 VARCHAR,
    city VARCHAR,
    state VARCHAR,
    zip VARCHAR,
    country VARCHAR,
    phone VARCHAR,
    status ENUM('ACTIVE', 'SUSPENDED') NOT NULL,
    sector ENUM('Supplier', 'Not applicable', 'Alternative Resources', 'Generation', 'End User', 'Publicly-Owned Entity', 'Transmission', 'Market Participant') NOT NULL,
    participant_type ENUM('Participant', 'Non-Participant', 'Pool Operator') NOT NULL,
    classification ENUM('Market Participant', 'Governance Only', 'Group Member', 'Other', 'Local Control Center', 'Public Utility Commission', 'Transmission Only') NOT NULL,
    sub_classification VARCHAR,
    has_voting_rights BOOLEAN,
    termination_date DATE,
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/isone/participant_list',
    onlyFilters: ['status'],
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
