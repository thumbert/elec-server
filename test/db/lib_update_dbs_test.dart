import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/api/api_dacongestion.dart';
import 'package:elec_server/client/ftr_clearing_prices.dart';
import 'package:elec_server/src/db/isoexpress/da_binding_constraints_report.dart';
import 'package:elec_server/src/db/isoexpress/da_congestion_compact.dart';
import 'package:elec_server/src/db/isoexpress/da_demand_bid.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/db/isoexpress/fwdres_auction_results.dart';
import 'package:elec_server/src/db/isoexpress/monthly_asset_ncpc.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:elec_server/src/db/nyiso/binding_constraints.dart';
import 'package:elec_server/src/db/nyiso/da_congestion_compact.dart';
import 'package:elec_server/src/db/nyiso/da_lmp_hourly.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:more/collection.dart';
import 'package:path/path.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

import '../../bin/setup_db.dart';


Future<void> insertDays(DailyIsoExpressReport archive, List<Date> days) async {
  await archive.dbConfig.db.open();
  for (var day in days) {
    print('Working on $day');
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

Future<void> tests() async {
  // var days = Date.today(location: UTC).next.previousN(4);
  // var days = Term.parse('24May22-31May22', UTC).days();
  // await insertDays(DaLmpHourlyArchive(), days);

  var months = Month.utc(2020, 1).upTo(Month.utc(2023, 9));
  await updateIesoRtGenerationArchive(months: months);

  // var years = IntegerRange(2013, 2023);
  // await updateIesoRtZonalDemandArchive(years: [2023]);
  // var days = Term.parse('Cal21', UTC).days();
  // await insertDays(DaLmpHourlyArchive(), days);
  var days = Term.parse('24May22-31May22', UTC).days();
  await insertDays(DaLmpHourlyArchive(), days);

  // await updateCmeEnergySettlements(days, setUp: false);
  await updateCtSuplierBacklogRatesDb(months: [
    Month.utc(2022, 12),
    Month.utc(2023, 1),
    Month.utc(2023, 2),
  ]);

  // await updatePolygraphProjects(setUp: false);

}

void main() async {
  initializeTimeZones();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  dotenv.load('.env/prod.env');

  await tests();

  ///
  /// See bin/setup_db.dart on how to update a database
  ///
}
