import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:timezone/timezone.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:dotenv/dotenv.dart' as dotenv;

Future<List<MraCapacityRecord>> getMraBidsOffers(Month month) async {
  final url = '${dotenv.env['RUST_SERVER']}/isone/capacity/mra/bids_offers'
      '/start/${month.toIso8601String()}/end/${month.toIso8601String()}';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception(
        'Failed to load MRA bids/offers for ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.map((e) {
    final month =
        Month.fromInt(e['month'] as int, location: IsoNewEngland.location);
    return MraCapacityRecord(
        month,
        e['masked_asset_id'] as int,
        e['masked_participant_id'] as int,
        e['masked_capacity_zone_id'] as int,
        ResourceType.parse(e['resource_type'] as String),
        e['masked_external_interface_id'] as int?,
        BidOffer.parse(e['bid_offer'] as String),
        e['segment'] as int,
        e['quantity'] as num,
        e['price'] as num);
  }).toList();
}

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
      'supply_offer' || 'offer' => BidOffer.offer,
      'demand_bid' || 'bid' => BidOffer.bid,
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
