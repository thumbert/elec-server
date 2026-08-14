import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:reduct/reduct.dart';
import 'package:timezone/data/latest.dart';


void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS capacity_offers_monthly (
    auction_month VARCHAR NOT NULL,
    forward_month VARCHAR NOT NULL,
    participant_id INTEGER NOT NULL,
    location_id INTEGER NOT NULL,
    row_type ENUM('BID', 'OFFER') NOT NULL,
    price DECIMAL(9,4) NOT NULL,
    mw DECIMAL(9,4) NOT NULL
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/nyiso/capacity_offers/monthly',
    onlyFilters: [
      'auction_month',
      'forward_month',
      'location_id',
      'participant_id',
      'row_type',
    ],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

Future<void> main() async {
  dotenv.load('.env/prod.env');
  initializeTimeZones();
  // await tests();

  generateCode();
}

