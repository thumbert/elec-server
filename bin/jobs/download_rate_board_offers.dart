import 'dart:io';

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart' as prod;
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<int> main() async {
  print('Running ... ${DateTime.now()}');
  initializeTimeZones();

  var archive = prod.getRetailSuppliersOffersArchive();
  await archive.saveCurrentRatesToFile();

  var status = await updateCompetitiveOffersDb(
      days: [Date.today(location: UTC)],
      states: ['CT', 'MA'],
      externalDownload: false);

  print('Done at ${DateTime.now()}');
  exit(status);
}
