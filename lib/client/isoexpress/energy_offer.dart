library client.isoexpress.energy_offer;

import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart';

getNewUnits() {}

/// Find the units that tripped (became unavailable in RT when they were available in DA)
getUnitsUnavailableInRt() {}

/// Get the energy offers from the elec-server.
Future<List<Datum>> getEnergyOffers(
    {required Date start,
    required Date end,
    required Market market,
    required Iso iso,
    required String rootUrl}) async {
  final url = '$rootUrl/${iso.name.toLowerCase()}/energy_offers'
      '/${market.name.toLowerCase()}/start/$start/end/$end';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data as List).map<Datum>((e) => Datum.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load energy offers');
  }
}

enum UnitStatus {
  economic(1),
  unavailable(2),
  mustRun(0);

  const UnitStatus(this.value);
  final int value;

  static UnitStatus parse(String x) {
    return switch (x.toUpperCase()) {
      'ECONOMIC' => UnitStatus.economic,
      'UNAVAILABLE' => UnitStatus.unavailable,
      'MUST_RUN' || 'MUSTRUN' => UnitStatus.mustRun,
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

class Datum {
  Datum(
      {required this.hourBeginning,
      required this.maskedAssetId,
      required this.unitStatus,
      required this.segment,
      required this.price,
      required this.quantity});

  final TZDateTime hourBeginning;
  final int maskedAssetId;
  final UnitStatus unitStatus;
  final int segment;
  final num price;
  final num quantity;

  static fromJson(Map<String, dynamic> json) {
    return Datum(
      hourBeginning:
          TZDateTime.parse(IsoNewEngland.location, json['hour_beginning']),
      maskedAssetId: json['masked_asset_id'],
      segment: json['segment'],
      price: json['price'],
      quantity: json['quantity'],
      unitStatus: UnitStatus.parse(json['unit_status']),
    );
  }

  @override
  String toString() {
    return toJson().toString();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'hour_beginning': hourBeginning.toIso8601String(),
      'masked_asset_id': maskedAssetId,
      'unit_status': unitStatus.toString(),
      'segment': segment,
      'price': price,
      'quantity': quantity,
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
    var segments = <Map<String, dynamic>>[];
    var aux = xs['Segments'];
    if (aux is Map) {
      var segment = aux['Segment'];
      if (segment is List) {
        segments.add(segment.first as Map<String, dynamic>);
      } else {
        segments.add(segment as Map<String, dynamic>);
      }
    } else if (aux is List) {
      var s = aux.map((e) => e['Segment']).toList();
      if (s.first is List) {
        segments = (s.first as List).cast<Map<String, dynamic>>();
      } else {
        segments = [...s.cast<Map<String, dynamic>>()];
      }
    }
    final claim10 = xs['Claim10Mw'] is String
        ? num.parse(xs['Claim10Mw'])
        : xs['Claim10Mw'] as num;
    final claim30 = xs['Claim30Mw'] is String
        ? num.parse(xs['Claim30Mw'])
        : xs['Claim30Mw'] as num;
    final start = TZDateTime.parse(IsoNewEngland.location, xs['BeginDate']);
    for (Map<String, dynamic> segment in segments) {
      var s = segment['@Number'] ?? segment['Number'];
      final segmentIdx = (s is String) ? int.parse(s) - 1 : s;
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
          claim10: claim10,
          claim30: claim30,
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

  // static List<EnergyOfferSegment> fromDuckDb(Map<String, List<Object?>> ys) {
  //   final hbs = ys['HourBeginning']!.cast<DateTime>();
  //   final participantIds = ys['MaskedParticipantId']!.cast<int>();
  //   final assetIds = ys['AssetId']!.cast<int>();
  //   final mustTakeEnergys = ys['MustTakeEnergy']!.cast<num>();
  //   final maxDailyEnergyAvailables = ys['MaxDailyEnergyAvailable']!.cast<num>();
  //   final ecoMaxs = ys['EcoMax']!.cast<num>();
  //   final ecoMins = ys['EcoMin']!.cast<num>();
  //   final coldStartupPrices = ys['ColdStartupPrice']!.cast<num>();
  //   final intermediateStartupPrices =
  //       ys['IntermediateStartupPrice']!.cast<num>();
  //   final hotStartupPrices = ys['HotStartupPrice']!.cast<num>();
  //   final noLoadPrices = ys['NoLoadPrice']!.cast<num>();
  //   final segments = ys['Segment']!.cast<int>();
  //   final prices = ys['Price']!.cast<num>();
  //   final mws = ys['Quantity']!.cast<num>();
  //   final claim10s = ys['Claim10']!.cast<num>();
  //   final claim30s = ys['Claim30']!.cast<num>();
  //   final unitStatus = ys['UnitStatus']!
  //       .cast<String>()
  //       .map((e) => UnitStatus.parse(e))
  //       .toList();

  //   final n = ys['HourBeginning']!.length;
  //   var out = <EnergyOfferSegment>[];
  //   for (var i = 0; i < n; i++) {
  //     out.add(EnergyOfferSegment(
  //         hour: Hour.beginning(TZDateTime.fromMillisecondsSinceEpoch(
  //             IsoNewEngland.location, hbs[i].millisecondsSinceEpoch)),
  //         maskedParticipantId: participantIds[i],
  //         maskedAssetId: assetIds[i],
  //         mustTakeEnergy: mustTakeEnergys[i],
  //         maxDailyEnergyAvailable: maxDailyEnergyAvailables[i],
  //         ecoMax: ecoMaxs[i],
  //         ecoMin: ecoMins[i],
  //         coldStartupPrice: coldStartupPrices[i],
  //         intermediateStartupPrice: intermediateStartupPrices[i],
  //         hotStartupPrice: hotStartupPrices[i],
  //         noLoadPrice: noLoadPrices[i],
  //         segment: segments[i],
  //         price: prices[i],
  //         quantity: mws[i],
  //         claim10: claim10s[i],
  //         claim30: claim30s[i],
  //         unitStatus: unitStatus[i]));
  //   }
  //   return out;
  // }

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
