import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

// void rebuildIsoneEnergyOffers() {
//   getDaEnergyOfferArchive().updateDuckDb();
//   getIsoneRtEnergyOfferArchive().updateDuckDb();
// }

Future<void> main() async {
  initializeTimeZones();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  dotenv.load('.env/prod.env');

  // getIsoneMorningReportArchive().rebuildDuckDb();
  getIsoneRtLmpArchive().rebuildDuckDb();

  // rebuildIsoneEnergyOffers();
}
