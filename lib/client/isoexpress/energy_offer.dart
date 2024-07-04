library client.isoexpress.energy_offer;

import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'package:timezone/timezone.dart';

// ignore: unused_element
final _queries = '''

SELECT MIN(HourBeginning) FROM rt_energy_offers;

-- one asset for one hour using America/New_York time stamp
SELECT * FROM rt_energy_offers
WHERE MaskedAssetId = 72020
AND HourBeginning = strptime('2023-01-01T00:00:00.000-05:00', '%Y-%m-%dT%H:%M:%S.000%z');

SELECT * FROM rt_energy_offers
WHERE MaskedAssetId = 72020
AND HourBeginning >= epoch('2023-01-01T00:00:00.000-05:00'::TIMESTAMPTZ)
AND HourBeginning < epoch_ms('2023-01-02T00:00:00.000-05:00'::TIMESTAMPTZ);

-- Because the data in DucDb is stored in UTC, it is best to use UTC timestamp
SELECT * FROM rt_energy_offers
WHERE MaskedAssetId = 72020
AND HourBeginning >= strptime('2023-01-01T05:00:00.000', '%Y-%m-%dT%H:%M:%S.000')
AND HourBeginning < strptime('2023-01-02T05:00:00.000', '%Y-%m-%dT%H:%M:%S.000');

-- one asset for one day
SELECT * FROM rt_energy_offers
WHERE MaskedAssetId = 72020
AND HourBeginning >= epoch_ms(1672531200000 + 5*3600000)
AND HourBeginning < epoch_ms(1672531200000 + 29*3600000);

-- , strftime(HourBeginning, '%Y-%m-%d') As Date

-- Get the distinct assetIds and unit status
SELECT DISTINCT MaskedAssetId, UnitStatus  
FROM da_energy_offers
WHERE HourBeginning >= epoch_ms(1672531200000 + 5*3600000)
AND HourBeginning < epoch_ms(1672531200000 + 29*3600000)
ORDER BY MaskedAssetId;

--- Get the units unavailable in RT
SELECT DISTINCT MaskedAssetId, UnitStatus  
FROM da_energy_offers
WHERE HourBeginning >= epoch_ms(1672531200000 + 5*3600000)
AND HourBeginning < epoch_ms(1672531200000 + 29*3600000)
AND UnitStatus = 'UNAVAILABLE'
ORDER BY MaskedAssetId;



--- Get the units that changed their status on this day  
SELECT DISTINCT da.MaskedAssetId, da.UnitStatus as DaStatus, rt.UnitStatus AS RtStatus
FROM rt_energy_offers AS rt
INNER JOIN da_energy_offers AS da
ON da.MaskedAssetId = rt.MaskedAssetId
WHERE da.HourBeginning >= epoch_ms(1672531200000 + 5*3600000)
AND da.HourBeginning < epoch_ms(1672531200000 + 29*3600000)
AND rt.HourBeginning >= epoch_ms(1672531200000 + 5*3600000)
AND rt.HourBeginning < epoch_ms(1672531200000 + 29*3600000)
AND DaStatus != RtStatus;


--- Get the units that became unavailable in RT when they were available in DA  
--- between 1/1/2023 and 2/1/2023
SELECT DISTINCT 
  strftime(da.HourBeginning, '%Y-%m-%d') As Date, 
  da.MaskedAssetId, 
  da.UnitStatus as DaStatus, 
  rt.UnitStatus AS RtStatus
FROM rt_energy_offers AS rt
INNER JOIN da_energy_offers AS da
ON da.MaskedAssetId = rt.MaskedAssetId
WHERE da.HourBeginning >= epoch_ms(1672531200000 + 5*3600000)
AND da.HourBeginning < epoch_ms(1675227600000 + 5*3600000)
AND rt.HourBeginning >= epoch_ms(1672531200000 + 5*3600000)
AND rt.HourBeginning < epoch_ms(1675227600000 + 5*3600000)
AND DaStatus != RtStatus
AND RtStatus = 'UNAVAILABLE'
ORDER BY Date, da.MaskedAssetId;








-- 1/1/2023 00:00:00 UTC
select epoch_ms(1672531200000);  

SET TimeZone = 'UTC'

SELECT * FROM rt_energy_offers
WHERE MaskedAssetId = 72020
AND HourBeginning >= strptime('2023-06-01T00:00:00.000-04:00', '%Y-%m-%dT%H:%M:%S.000%z')
AND HourBeginning < strptime('2023-06-02T00:00:00.000-04:00', '%Y-%m-%dT%H:%M:%S.000%z')
LIMIT 1;

''';


/// Get historical offers
List<EnergyOfferSegment> getEnergyOffers(
    Connection con, Term term, Market market, List<int> maskedAssetIds) {
  final query = '''
SELECT * FROM ${market.toString().toLowerCase()}_energy_offers
WHERE MaskedAssetId = 72020
AND HourBeginning >= epoch_ms(${term.interval.start.millisecondsSinceEpoch})
AND HourBeginning < epoch_ms(${term.interval.end.millisecondsSinceEpoch});
''';
  var res = con.fetch(query);
  return EnergyOfferSegment.fromDuckDb(res);
}



getNewUnits() {}

/// Find the units that tripped (became unavailable in RT when they were available in DA)
getUnitsUnavailableInRt() {}

enum UnitStatus {
  economic,
  unavailable,
  mustRun;

  static UnitStatus parse(String x) {
    return switch (x) {
      'ECONOMIC' => UnitStatus.economic,
      'UNAVAILABLE' => UnitStatus.unavailable,
      'MUST_RUN' => UnitStatus.mustRun,
      _ => throw ArgumentError('Invalid unit type $x'),
    };
  }

  @override
  String toString() {
    return switch (this) {
      UnitStatus.economic => 'ECONOMIC',
      UnitStatus.unavailable => 'UNAVAILABLE',
      UnitStatus.mustRun => 'MUST_RUN',
    };
  }
}

class EnergyOfferSegment {
  EnergyOfferSegment(
      {required this.hour,
      required this.maskedParticipantId,
      required this.maskedAssetId,
      required this.mustTakeEnergy,
      required this.maxDailyEnergyAvailable,
      required this.ecoMax,
      required this.ecoMin,
      required this.coldStartupPrice,
      required this.intermediateStartupPrice,
      required this.hotStartupPrice,
      required this.noLoadPrice,
      required this.segment,
      required this.price,
      required this.quantity,
      required this.claim10,
      required this.claim30,
      required this.unitStatus});

  final Hour hour;
  final int maskedParticipantId;
  final int maskedAssetId;
  final num mustTakeEnergy;
  final num maxDailyEnergyAvailable;
  final num ecoMax;
  final num ecoMin;
  final num coldStartupPrice;
  final num intermediateStartupPrice;
  final num hotStartupPrice;
  final num noLoadPrice;
  // starting at zero
  final int segment;
  final num price;
  final num quantity;
  final num claim10;
  final num claim30;
  final UnitStatus unitStatus;

  /// Input is an element of the list 'HbRealTimeEnergyOffer' corresponding to a
  /// unit (with multiple segments)
  ///
  static List<EnergyOfferSegment> fromJson(Map<String, dynamic> xs) {
    var out = <EnergyOfferSegment>[];
    var aux =
        ((xs['Segments'] as List).first as Map<String, dynamic>)['Segment'];
    var segments = aux is List ? aux : [aux];
    for (Map<String, dynamic> segment in segments) {
      final start = TZDateTime.parse(IsoNewEngland.location, xs['BeginDate']);
      final segmentIdx = int.parse(segment['@Number']) - 1;
      assert(segmentIdx >= 0);
      final price = segment['Price'] is String
          ? num.parse(segment['Price'])
          : segment['Price'];
      final mw =
          segment['Mw'] is String ? num.parse(segment['Mw']) : segment['Mw'];
      out.add(EnergyOfferSegment(
          hour: Hour.beginning(start),
          maskedParticipantId: xs['MaskedParticipantId'],
          maskedAssetId: xs['MaskedAssetId'],
          mustTakeEnergy: xs['MustTakeEnergy'],
          maxDailyEnergyAvailable: xs['MaxDailyEnergy'] is String
              ? num.parse(xs['MaxDailyEnergy'])
              : xs['MaxDailyEnergy'],
          ecoMax: xs['EconomicMax'] is String
              ? num.parse(xs['EconomicMax'])
              : xs['EconomicMax'],
          ecoMin: xs['EconomicMin'] is String
              ? num.parse(xs['EconomicMin'])
              : xs['EconomicMin'],
          coldStartupPrice: xs['ColdStartPrice'] is String
              ? num.parse(xs['ColdStartPrice'])
              : xs['ColdStartPrice'],
          intermediateStartupPrice: xs['IntermediateStartPrice'] is String
              ? num.parse(xs['IntermediateStartPrice'])
              : xs['IntermediateStartPrice'],
          hotStartupPrice: xs['HotStartPrice'] is String
              ? num.parse(xs['HotStartPrice'])
              : xs['HotStartPrice'],
          noLoadPrice: xs['NoLoadPrice'] is String
              ? num.parse(xs['NoLoadPrice'])
              : xs['NoLoadPrice'],
          segment: segmentIdx,
          price: price,
          quantity: mw,
          claim10: num.parse(xs['Claim10Mw']),
          claim30: num.parse(xs['Claim30Mw']),
          unitStatus: UnitStatus.parse(xs['UnitStatus'])));
    }
    return out;
  }

  /// From the CSV file row, create several EnergyOfferSegments
  static List<EnergyOfferSegment> fromRow(List<dynamic> row) {
    var out = <EnergyOfferSegment>[];
    assert(row.length == 36);
    var tradingInterval = row[2].toString().padLeft(2, '0');
    var start = parseHourEndingStamp(row[1], tradingInterval);
    start = TZDateTime.fromMillisecondsSinceEpoch(
        IsoNewEngland.location, start.millisecondsSinceEpoch);
    for (var segment = 0; segment < 10; segment++) {
      if (row[13 + 2 * segment] == '') continue;
      out.add(EnergyOfferSegment(
          hour: Hour.beginning(start),
          maskedParticipantId: row[3],
          maskedAssetId: row[4],
          mustTakeEnergy: row[5],
          maxDailyEnergyAvailable: row[6],
          ecoMax: row[7],
          ecoMin: row[8],
          coldStartupPrice: row[9],
          intermediateStartupPrice: row[10],
          hotStartupPrice: row[11],
          noLoadPrice: row[12],
          segment: segment,
          price: row[13 + 2 * segment],
          quantity: row[14 + 2 * segment],
          claim10: row[33],
          claim30: row[34],
          unitStatus: UnitStatus.parse(row[35])));
    }
    return out;
  }

  static List<EnergyOfferSegment> fromDuckDb(Map<String, List<Object?>> ys) {
    final hbs = ys['HourBeginning']!.cast<DateTime>();
    final participantIds = ys['MaskedParticipantId']!.cast<int>();
    final assetIds = ys['AssetId']!.cast<int>();
    final mustTakeEnergys = ys['MustTakeEnergy']!.cast<num>();
    final maxDailyEnergyAvailables = ys['MaxDailyEnergyAvailable']!.cast<num>();
    final ecoMaxs = ys['EcoMax']!.cast<num>();
    final ecoMins = ys['EcoMin']!.cast<num>();
    final coldStartupPrices = ys['ColdStartupPrice']!.cast<num>();
    final intermediateStartupPrices =
        ys['IntermediateStartupPrice']!.cast<num>();
    final hotStartupPrices = ys['HotStartupPrice']!.cast<num>();
    final noLoadPrices = ys['NoLoadPrice']!.cast<num>();
    final segments = ys['Segment']!.cast<int>();
    final prices = ys['Price']!.cast<num>();
    final mws = ys['Quantity']!.cast<num>();
    final claim10s = ys['Claim10']!.cast<num>();
    final claim30s = ys['Claim30']!.cast<num>();
    final unitStatus = ys['UnitStatus']!
        .cast<String>()
        .map((e) => UnitStatus.parse(e))
        .toList();

    final n = ys['HourBeginning']!.length;
    var out = <EnergyOfferSegment>[];
    for (var i = 0; i < n; i++) {
      out.add(EnergyOfferSegment(
          hour: Hour.beginning(TZDateTime.fromMillisecondsSinceEpoch(
              IsoNewEngland.location, hbs[i].millisecondsSinceEpoch)),
          maskedParticipantId: participantIds[i],
          maskedAssetId: assetIds[i],
          mustTakeEnergy: mustTakeEnergys[i],
          maxDailyEnergyAvailable: maxDailyEnergyAvailables[i],
          ecoMax: ecoMaxs[i],
          ecoMin: ecoMins[i],
          coldStartupPrice: coldStartupPrices[i],
          intermediateStartupPrice: intermediateStartupPrices[i],
          hotStartupPrice: hotStartupPrices[i],
          noLoadPrice: noLoadPrices[i],
          segment: segments[i],
          price: prices[i],
          quantity: mws[i],
          claim10: claim10s[i],
          claim30: claim30s[i],
          unitStatus: unitStatus[i]));
    }
    return out;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'hourBeginning': hour.start.toIso8601String(),
      'maskedParticipantId': maskedParticipantId,
      'maskedAssetId': maskedAssetId,
      'mustTakeEnergy': mustTakeEnergy,
      'maxDailyEnergyAvailable': maxDailyEnergyAvailable,
      'ecoMax': ecoMax,
      'ecoMin': ecoMin,
      'coldStartupPrice': coldStartupPrice,
      'intermediateStartupPrice': intermediateStartupPrice,
      'hotStartupPrice': hotStartupPrice,
      'noLoadPrice': noLoadPrice,
      'segment': segment,
      'price': price,
      'quantity': quantity,
      'claim10': claim10,
      'claim30': claim30,
      'unitStatus': unitStatus.toString(),
    };
  }
}
