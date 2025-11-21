import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> rebuildIsoneMaskedData() async {
  var months = Month(2022, 2, location: IsoNewEngland.location)
      .upTo(Month(2025, 6, location: IsoNewEngland.location));
  await updateIsoneDemandBids(months: months, download: false);

  // getIsoneDaEnergyOfferArchive().updateDuckDb(months: months);
  // getIsoneRtEnergyOfferArchive().updateDuckDb();
}

Future<void> main() async {
  initializeTimeZones();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  dotenv.load('.env/prod.env');

  // getIsoneMorningReportArchive().rebuildDuckDb();
  // getIsoneDaLmpArchive().rebuildDuckDb();
  // getIsoneRtLmpArchive().rebuildDuckDb();

  await rebuildIsoneMaskedData();
}
