import 'dart:math';

import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/client/isoexpress/daas_offer.dart';
import 'package:elec_server/client/isoexpress/energy_offer.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:more/comparator.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> analysis() async {
  final hourBeginning =
      TZDateTime(IsoNewEngland.location, 2025, 6, 25, 14, 0, 0);
  final archive = getIsoneDaEnergyOfferArchive();

  // var energyOffers = await getEnergyOffers(
  //     start: Date(2025, 6, 25, location: IsoNewEngland.location),
  //     end: Date(2025, 6, 25, location: IsoNewEngland.location),
  //     market: Market.da,
  //     iso: Iso.newEngland,
  //     rootUrl: dotenv.env['RUST_SERVER']!);
  final conn = Connection(archive.duckDbPath);
  var energyOffers = archive.getOffers(conn, hourBeginning);
  energyOffers = energyOffers
      .where((e) =>
          e.hourBeginning == hourBeginning &&
          e.unitStatus != UnitStatus.unavailable)
      .toList();
  energyOffers.sortBy((e) => e.price);

  var cumulative = 0.0;
  for (var e in energyOffers) {
    var out = e.toJson();
    cumulative += e.quantity;
    out['cumulative_quantity'] = cumulative;
    print(out);
  }

  var daasOffers = await getDaasOffers(
      start: Date(2025, 6, 25, location: IsoNewEngland.location),
      end: Date(2025, 6, 25, location: IsoNewEngland.location),
      iso: Iso.newEngland,
      rootUrl: dotenv.env['RUST_SERVER']!);
  daasOffers =
      daasOffers.where((e) => e.hourBeginning == hourBeginning).toList();
  // print(daasOffers);
}

Future<void> main(List<String> args) async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  await analysis();
}
