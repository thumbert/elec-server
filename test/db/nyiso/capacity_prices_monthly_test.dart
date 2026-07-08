import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  group('NYISO Capacity Clearing Prices Monthly', () {
    final archive = getNyisoCapacityPricesMonthlyArchive();
    test('download Jan24', () async {
      final res = await archive.downloadPricesToCsv(
          seasonId: 702409, month: Month.utc(2024, 1));
      expect(res.length, 32);
      final gj = res.where((e) => e.location.name == 'G-J Locality');
      expect(gj.length, 4);
      expect(gj.map((e) => e.forwardMonth.toIso8601String()).toList(),
          ['2024-01', '2024-02', '2024-03', '2024-04']);
      final gjPrices = gj.map((e) => e.clearingPrice).toList();
      expect(gjPrices, [4.2, 3.94, 1.86, 1.35]);
    });
    test('download May26', () async {
      final res = await archive.downloadPricesToCsv(
          seasonId: 705094, month: Month.utc(2026, 5));
      expect(res.length, 48);
    });
  });
}

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS capacity_prices_monthly (
    capability_period VARCHAR NOT NULL,
    auction_month VARCHAR NOT NULL,
    forward_month VARCHAR NOT NULL,
    location VARCHAR NOT NULL,
    clearing_price DECIMAL(9,4) NOT NULL,
    awarded_mw DECIMAL(9,4) NOT NULL
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/nyiso/capacity_prices/monthly',
    onlyFilters: ['capability_period', 'location'],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

Future<void> main() async {
  dotenv.load('.env/prod.env');
  initializeTimeZones();
  await tests();

  // generateCode();
}


// Description	seasonId
// Summer 2026	705094
// Winter 2025-2026	704686
// Summer 2025	703919
// Winter 2024-2025	703176
// Summer 2024	702793