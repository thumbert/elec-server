import 'dart:io';

import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

void rebuildIsoneEnergyOffers() {
  final home = Platform.environment['HOME'];
  final con =
      Connection('$home/Downloads/Archive/IsoExpress/energy_offers.duckdb');
  con.execute('''
CREATE TABLE IF NOT EXISTS da_energy_offers (
    HourBeginning TIMESTAMP_S NOT NULL,
    MaskedParticipantId UINTEGER NOT NULL,
    MaskedAssetId UINTEGER NOT NULL,
    MaxDailyEnergyAvailable FLOAT NOT NULL,
    EcoMax FLOAT NOT NULL,
    EcoMin FLOAT NOT NULL,
    ColdStartupPrice FLOAT NOT NULL,
    IntermediateStartupPrice FLOAT NOT NULL,
    HotStartupPrice FLOAT NOT NULL,
    NoLoadPrice FLOAT NOT NULL,
    Segment UTINYINT NOT NULL,
    Price FLOAT NOT NULL,
    Quantity FLOAT NOT NULL,
    Claim10 FLOAT NOT NULL,
    Claim30 FLOAT NOT NULL,
    UnitStatus ENUM('ECONOMIC', 'UNAVAILABLE', 'MUST_RUN') NOT NULL,
);  
  ''');
  con.execute('''
INSERT INTO da_energy_offers
FROM read_csv(
    'da_energy_offers_*.csv.gz', 
    header = true, 
    timestampformat = '%Y-%m-%dT%H:%M:%S.000%z');
''');
}


void rebuildMorningReport() {
  final archive = getMorningReportArchive();
  archive.rebuildDuckDb();
}

Future<void> main() async {
  initializeTimeZones();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  dotenv.load('.env/prod.env');

  rebuildMorningReport();
}
