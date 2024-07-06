library client.isoexpress.energy_offer;


import 'package:csv/csv.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'package:timezone/timezone.dart';

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
  final int segment;
  final num price;
  final num quantity;
  final num claim10;
  final num claim30;
  final UnitStatus unitStatus;

  static const List<String> columns = [
    'HourBeginning',
    'MaskedParticipantId',
    'MaskedAssetId',
    'MaxDailyEnergyAvailable',
    'EcoMax',
    'EcoMin',
    'ColdStartupPrice',
    'IntermediateStartupPrice',
    'HotStartupPrice',
    'NoLoadPrice',
    'Segment',
    'Price',
    'Quantity',
    'Claim10',
    'Claim30',
    'UnitStatus',
  ];

  ///
  String toCsv() {
    return ListToCsvConverter().convert([
      [
        hour.start.toIso8601String(),
        maskedParticipantId,
        maskedAssetId,
        maxDailyEnergyAvailable,
        ecoMax,
        ecoMin,
        coldStartupPrice,
        intermediateStartupPrice,
        hotStartupPrice,
        noLoadPrice,
        segment,
        price,
        quantity,
        claim10,
        claim30,
        unitStatus.toString(),
      ]
    ]);
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
}


