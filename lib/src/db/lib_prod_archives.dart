import 'dart:io';

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/db_isone.dart';
import 'package:elec_server/db_nyiso.dart';
import 'package:elec_server/src/db/canadian_statistics/canadian_statistics.dart';
import 'package:elec_server/src/db/cme/cme_energy_settlements.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/hq/hq_water.dart';
import 'package:elec_server/src/db/ieso/rt_generation.dart';
import 'package:elec_server/src/db/ieso/rt_zonal_demand.dart';
import 'package:elec_server/src/db/isoexpress/rt_lmp_5min.dart';
import 'package:elec_server/src/db/isoexpress/rt_reserve_prices.dart';
import 'package:elec_server/src/db/isoexpress/rt_system_load_5min.dart';
import 'package:elec_server/src/db/polygraph/polygraph_archive.dart';
import 'package:elec_server/src/db/weather/normal_temperature.dart';

CanadianStatisticsArchive getCanadianStatisticsArchive() {
  var dir =
      '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/DuckDB/statistics_canada';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return CanadianStatisticsArchive(
    duckDbPath: '$dir/energy_generation.duckdb',
  );
}

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

MaineCmpLoadArchive getCmpLoadArchive() {
  final dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'utility', collectionName: 'load_cmp');
  final dir =
      '${Platform.environment['HOME']!}/Downloads/Archive/Utility/Maine/CMP/Load/Raw/';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return MaineCmpLoadArchive(dbConfig: dbConfig, dir: dir);
}

CtSupplierBacklogRatesArchive getCtSupplierBacklogRatesArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1',
      dbName: 'retail_suppliers',
      collectionName: 'ct_backlog_rates');
  var dir =
      '${Platform.environment['HOME']}/Downloads/Archive/SupplierBacklogRates/CT/Raw/';
  var archive = CtSupplierBacklogRatesArchive(dbConfig: dbConfig, dir: dir);
  if (!Directory(archive.dir).existsSync()) {
    Directory(archive.dir).createSync(recursive: true);
  }
  return archive;
}

HqWaterArchive getHqWaterArchive() {
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/DuckDB';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return HqWaterArchive(
    duckDbPath: '$dir/hq_water_level.duckdb',
  );
}

DaEnergyOfferArchive getIsoneDaEnergyOfferArchive() {
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/IsoExpress/PricingReports/DaEnergyOffer';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return DaEnergyOfferArchive(
      dir: dir,
      duckDbPath:
          '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/DuckDB/isone/masked_energy_offers.duckdb');
}

IesoRtGenerationArchive getIesoRtGenerationArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'ieso', collectionName: 'rt_generation');
  var dir = Directory('${Platform.environment['HOME'] ?? ''}'
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

RtSystemLoad5minArchive getRtSystemLoad5minArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1',
      dbName: 'isoexpress',
      collectionName: 'rt_systemload_5min');
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/IsoExpress/Demand/SystemDemand5min/Raw/';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return RtSystemLoad5minArchive(dbConfig: dbConfig, dir: dir);
}

DaLmpHourlyArchive getIsoneDaLmpArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'da_lmp_hourly');
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/IsoExpress/PricingReports/DaLmpHourly/Raw/';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return DaLmpHourlyArchive(dbConfig: dbConfig, dir: dir);
}

DaDemandBidArchive getIsoneDemandBidsArchive() {
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/IsoExpress/PricingReports/DaDemandBid';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return DaDemandBidArchive()
    ..dir = dir
    ..duckdbPath =
        '${Platform.environment['HOME']}/Downloads/Archive/DuckDB/isone/masked_demand_bids.duckdb';
}

IsoneBtmSolarArchive getIsoneHistoricalBtmSolarArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'isone', collectionName: 'hourly_btm_solar');
  var dir = Directory('${Platform.environment['HOME'] ?? ''}'
      '/Downloads/Archive/Isone/Solar/BTM/Raw');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return IsoneBtmSolarArchive(dbConfig: dbConfig, dir: dir.path);
}

MonthlyAssetNcpcArchive getIsoneMonthlyAssetNcpcArchive() {
  var config = ComponentConfig(
      host: dotenv.env['MONGO_CONNECTION']!,
      dbName: 'isoexpress',
      collectionName: 'monthly_asset_ncpc');
  final dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/IsoExpress/GridReports/MonthlyAssetNcpc';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }

  /// data starts on 4/1/2019
  return MonthlyAssetNcpcArchive()
    ..dbConfig = config
    ..dir = dir
    ..reportName = 'Monthly NCPC credits by Asset Report';
}

MraCapacityBidOfferArchive getIsoneMraBidOfferArchive() {
  final dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/IsoExpress/Capacity/HistoricalBidsOffers/MonthlyAuction';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return MraCapacityBidOfferArchive(dir: dir);
}

MraCapacityResultsArchive getIsoneMraResultsArchive() {
  final dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/IsoExpress/Capacity/Results/MonthlyAuction';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return MraCapacityResultsArchive(dir: dir);
}

RtEnergyOfferArchive getIsoneRtEnergyOfferArchive() {
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/IsoExpress/PricingReports/RtEnergyOffer';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return RtEnergyOfferArchive(dir: dir);
}

RtLmpHourlyArchive getIsoneRtLmpArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'isoexpress', collectionName: 'rt_lmp_hourly');
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/IsoExpress/PricingReports/RtLmpHourly/Raw/';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return RtLmpHourlyArchive(dbConfig: dbConfig, dir: dir);
}

RtLmp5MinArchive getIsoneRtLmp5MinArchive() {
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/IsoExpress/PricingReports/RtLmp5Min';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return RtLmp5MinArchive(dir: dir);
}

RtReservePriceArchive getIsoneRtReservePriceArchive() {
  var dir =
      '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/IsoExpress/PricingReports/RtReservePrice';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return RtReservePriceArchive(dir: dir);
}

SevenDayCapacityForecastArchive getIsoneSevenDayCapacityForecastArchive() {
  var dir =
      '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/IsoExpress/7dayCapacityForecast';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return SevenDayCapacityForecastArchive(dir: dir);
}

IsoneMorningReportArchive getIsoneMorningReportArchive() {
  var dir =
      '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/IsoExpress/MorningReport';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return IsoneMorningReportArchive(
      dir: dir,
      duckdbPath:
          '${Platform.environment['HOME'] ?? ''}/Downloads/Archive/DuckDB/isone/morning_report.duckdb');
}

NormalTemperatureArchive getNormalTemperatureArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1',
      dbName: 'weather',
      collectionName: 'normal_temperature');
  var dir =
      '${Platform.environment['HOME']}/Downloads/Archive/Weather/NormalTemperature';
  var archive = NormalTemperatureArchive(dbConfig: dbConfig, dir: dir);
  if (!Directory(archive.dir).existsSync()) {
    Directory(archive.dir).createSync(recursive: true);
  }
  return archive;
}

NyisoEnergyOfferArchive getNyisoEnergyOfferArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'nyiso', collectionName: 'da_energy_offer');
  var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
      '/Nyiso/EnergyOffer/Raw/';
  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return NyisoEnergyOfferArchive(dbConfig: dbConfig, dir: dir);
}

// NyisoEnergyOfferArchive getNyisoMaskedIdArchive() {
//   var dbConfig = ComponentConfig(
//       host: '127.0.0.1', dbName: 'nyiso', collectionName: 'da_energy_offer');
//   var dir = '${Platform.environment['HOME'] ?? ''}/Downloads/Archive'
//       '/Nyiso/EnergyOffer/Raw/';
//   if (!Directory(dir).existsSync()) {
//     Directory(dir).createSync(recursive: true);
//   }
//   return NyisoEnergyOfferArchive(dbConfig: dbConfig, dir: dir);
// }

NyisoTccClearingPrices getNyisoTccClearingPriceArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1',
      dbName: 'nyiso',
      collectionName: 'tcc_clearing_prices');
  var dir =
      '${Platform.environment['HOME']!}/Downloads/Archive/Nyiso/TCC/ClearingPrices/Raw/';

  if (!Directory(dir).existsSync()) {
    Directory(dir).createSync(recursive: true);
  }
  return NyisoTccClearingPrices(config: dbConfig, dir: dir);
}

PolygraphArchive getPolygraphArchive() {
  var dbConfig = ComponentConfig(
      host: '127.0.0.1', dbName: 'polygraph', collectionName: 'projects');
  var dir = Directory('${Platform.environment['HOME'] ?? ''}'
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
