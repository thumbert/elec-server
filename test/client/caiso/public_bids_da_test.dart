import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/caiso/public_bids_da.dart' as client;
import 'package:test/test.dart';

import 'package:timezone/data/latest.dart';

Future<void> tests(String rootUrl) async {
  group('Client tests for caiso/public_bids/da', () {
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

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['RUST_SERVER']!;
  await tests(rootUrl);
}
