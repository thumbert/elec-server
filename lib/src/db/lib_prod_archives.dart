library lib.src.db.lib_prod_archives;

import 'dart:io';

import 'package:elec_server/src/db/cme/cme_energy_settlements.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/ieso/rt_generation.dart';
import 'package:elec_server/src/db/ieso/rt_zonal_demand.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/src/db/polygraph/polygraph_archive.dart';
import 'package:elec_server/src/db/utilities/eversource/supplier_backlog_rates.dart';
import 'package:elec_server/src/db/utilities/retail_suppliers_offers_archive.dart';

CmeSettlementsEnergyArchive getCmeEnergySettlementsArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'cme', collectionName: 'settlements');
  var dir =
      '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/Cme/Settlements/Energy/Raw/';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return CmeSettlementsEnergyArchive(dbConfig: dbConfig, dir: dir);
}

DaEnergyOfferArchive getDaEnergyOfferArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'da_energy_offer');
  var dir =
      '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/Downloads/'
      'Archive/IsoExpress/DaEnergyOffer/Raw/';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return DaEnergyOfferArchive(dbConfig: dbConfig, dir: dir);

}


IesoRtGenerationArchive getIesoRtGenerationArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'ieso', collectionName: 'rt_generation');
  var dir=Directory('${Platform.environment['HOME'] ?? ''}'
      '/Downloads/Archive/Ieso/RtGeneration/Raw/');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return IesoRtGenerationArchive(dbConfig: dbConfig, dir: dir.path);
}

IesoRtZonalDemandArchive getIesoRtZonalDemandArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'ieso', collectionName: 'rt_zonal_demand');
  var dir = Directory('${Platform.environment['HOME'] ?? ''}'
      '/Downloads/Archive/Ieso/RtZonalDemand/Raw/');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return IesoRtZonalDemandArchive(dbConfig: dbConfig, dir: dir.path);
}

CtSupplierBacklogRatesArchive getCtSupplierBacklogRatesArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'retail_suppliers',
      collectionName: 'ct_backlog_rates');
  var archive = CtSupplierBacklogRatesArchive(dbConfig: dbConfig);
  if (!Directory(archive.dir).existsSync()) {
    Directory(archive.dir).createSync(recursive: true);
  }
  return archive;
}

PolygraphArchive getPolygraphArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'polygraph', collectionName: 'projects');
  var dir =Directory('${Platform.environment['HOME'] ?? ''}'
      '/Downloads/Archive/Polygraph/Projects/Raw/');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return PolygraphArchive(dbConfig: dbConfig, dir: dir);
}

RetailSuppliersOffersArchive getRetailSuppliersOffersArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1',
      dbName: 'retail_suppliers',
      collectionName: 'historical_offers');
  var dir =
      '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/RateBoardOffers/Raw/';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return RetailSuppliersOffersArchive(dbConfig: dbConfig, dir: dir);
}
