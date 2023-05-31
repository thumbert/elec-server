library lib.src.db.lib_prod_archives;

import 'dart:io';

import 'package:elec_server/src/db/cme/cme_energy_settlements.dart';
import 'package:elec_server/src/db/config.dart';

CmeSettlementsEnergyArchive getCmeEnergySettlementsArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'cme', collectionName: 'settlements');
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/Cme/Settlements/Energy/Raw/';
  return CmeSettlementsEnergyArchive(dbConfig: dbConfig, dir: dir);
}
