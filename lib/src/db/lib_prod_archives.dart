library lib.src.db.lib_prod_archives;

import 'dart:io';

import 'package:elec_server/src/db/cme/cme_energy_settlements.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/utilities/retail_suppliers_offers_archive.dart';

CmeSettlementsEnergyArchive getCmeEnergySettlementsArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'cme', collectionName: 'settlements');
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/Cme/Settlements/Energy/Raw/';
  return CmeSettlementsEnergyArchive(dbConfig: dbConfig, dir: dir);
}

RetailSuppliersOffersArchive getRetailSuppliersOffersArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'retail_suppliers', collectionName: 'historical_offers');
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/RateBoardOffers/Raw/';
  return RetailSuppliersOffersArchive(dbConfig: dbConfig, dir: dir);
}
