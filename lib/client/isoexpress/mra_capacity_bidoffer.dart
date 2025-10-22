import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

enum ResourceType {
  generating,
  demand,
  import;

  static ResourceType parse(String x) {
    return switch (x.toLowerCase()) {
      'generating' => ResourceType.generating,
      'demand' => ResourceType.demand,
      'import' => ResourceType.import,
      _ => throw ArgumentError('Invalid ResourceType $x'),
    };
  }
}

enum BidOffer {
  bid,
  offer;

  static BidOffer parse(String x) {
    return switch (x.toLowerCase()) {
      'supply_offer' => BidOffer.offer,
      'demand_bid' => BidOffer.bid,
      _ => throw ArgumentError('Invalid BidOffer $x'),
    };
  }
}

class MraCapacityRecord {
  MraCapacityRecord(
      this.month,
      this.maskedResourceId,
      this.maskedParticipantId,
      this.maskedCapacityZoneId,
      this.resourceType,
      this.maskedExternalInterfaceId,
      this.bidOffer,
      this.segment,
      this.quantity,
      this.price);

  final Month month;
  final int maskedResourceId;
  final int maskedParticipantId;
  final int maskedCapacityZoneId;
  final ResourceType resourceType;
  final int? maskedExternalInterfaceId;
  final BidOffer bidOffer;
  final int segment;
  final num quantity;
  final num price;

  /// Each entry can contain several segments.
  static List<MraCapacityRecord> fromJson(Map<String, dynamic> x) {
    final month =
        Month.parse((x['BeginDate'] as String).substring(0, 7), location: UTC);
    final segmentCount = x.keys.where((e) => e.startsWith('Seg')).length ~/ 2;

    var out = <MraCapacityRecord>[];
    for (var segment = 1; segment <= segmentCount; segment++) {
      // ISO has the quantity and price fields backwards!  Nice job!
      // If they fix it at some point, I'll need to revert.
      late final num price, quantity;
      if (x['Seg${segment}Price'] is double) {
        quantity = x['Seg${segment}Price'];
      } else {
        quantity = num.parse(x['Seg${segment}Price']);
      }
      if (x['Seg${segment}Mw'] is double) {
        price = x['Seg${segment}Mw'];
      } else {
        price = num.parse(x['Seg${segment}Mw']);
      }
      out.add(MraCapacityRecord(
        month,
        x['MaskResID'],
        x['MaskLPID'],
        x['MaskCZID'],
        ResourceType.parse(x['ResType']),
        !x.containsKey('MaskIntfcID') ? null : x['MaskIntfcID'],
        BidOffer.parse(x['BidType']),
        segment - 1,
        quantity,
        price,
      ));
    }
    return out;
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month.year * 100 + month.month,
      'maskedResourceId': maskedResourceId,
      'maskedParticipantId': maskedParticipantId,
      'maskedCapacityZoneId': maskedCapacityZoneId,
      'resourceType': resourceType.name,
      'maskedExternalInterfaceId':
          maskedExternalInterfaceId == null ? "" : maskedExternalInterfaceId!,
      'bidOffer': bidOffer.name,
      'segment': segment,
      'quantity': quantity,
      'price': price,
    };
  }
}
