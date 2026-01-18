// import 'package:dotenv/dotenv.dart' as dotenv;
// import 'package:elec_server/src/db/lib_prod_archives.dart';
// import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:reduct/reduct.dart';
// import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

// Future<void> tests(String rootUrl) async {
//   var archive = getIsoneAraBidOfferArchive();
//   group('ARA BidOffer archive tests:', () {
//     test('read file for 2024-01', () async {
//       var file = archive.getFilename(Month.utc(2024, 1));
//       var data = archive.processJsonFile(file);
//       expect(data.length, 454);
//       var xs = data.where((e) => e.maskedResourceId == 52995).toList();
//       expect(xs.length, 5);
//       var segments = xs.map((e) => e.segment).toList();
//       segments.sort();
//       expect(segments, [0, 1, 2, 3, 4]);
//     });
//   });
// }

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS bids_offers (
    capability_period VARCHAR NOT NULL,
    auction_type ENUM('ARA1', 'ARA2', 'ARA3') NOT NULL,
    masked_resource_id UINTEGER NOT NULL,
    masked_participant_id UINTEGER NOT NULL,
    masked_capacity_zone_id USMALLINT NOT NULL,
    resource_type ENUM('Import', 'Generating', 'Demand') NOT NULL,
    bid_offer ENUM('Demand_Bid', 'Supply_Offer') NOT NULL,
    segment UTINYINT NOT NULL,
    quantity DECIMAL(9,4) NOT NULL,
    price DECIMAL(9,4) NOT NULL
);''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/isone/capacity/ara/bids_offers',
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

Future<void> main() async {
  initializeTimeZones();
  generateCode();


  // dotenv.load('.env/prod.env');
  // DbProd();
  // await tests(dotenv.env['ROOT_URL']!);

}
