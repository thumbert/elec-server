library client.isoexpress.mra_capacity_results;

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

enum MraRecordType {
  zone,
  interface,
}

sealed class MraCapacityRecord {}

class MraCapacityZoneRecord extends MraCapacityRecord {
  MraCapacityZoneRecord({
    required this.month,
    required this.capacityZoneId,
    required this.capacityZoneType,
    required this.capacityZoneName,
    required this.supplyOffersSubmitted,
    required this.demandBidsSubmitted,
    required this.supplyOffersCleared,
    required this.demandBidsCleared,
    required this.netCapacityCleared,
    required this.clearingPrice,
  });

  final Month month;
  final int capacityZoneId;
  final String capacityZoneType;
  final String capacityZoneName;

  /// in MW
  final num supplyOffersSubmitted;

  /// in MW
  final num supplyOffersCleared;

  /// in MW
  final num demandBidsSubmitted;

  /// in MW
  final num demandBidsCleared;

  /// in MW
  final num netCapacityCleared;

  /// in $/kW-month
  final num clearingPrice;

  /// Each entry can contain several segments.
  static List<MraCapacityZoneRecord> fromJson(Map<String, dynamic> x) {
    final month =
        Month.parse((x['Auction']['Description'] as String), location: UTC);
    final zs = x['ClearedCapacityZones']['ClearedCapacityZone'] as List;
    var out = <MraCapacityZoneRecord>[];
    for (Map<String, dynamic> zoneData in zs) {
      out.add(MraCapacityZoneRecord(
          month: month,
          capacityZoneId: zoneData['CapacityZoneID'],
          capacityZoneType: zoneData['CapacityZoneType'],
          capacityZoneName: zoneData['CapacityZoneName'],
          supplyOffersSubmitted: zoneData['SupplySubmitted'],
          demandBidsSubmitted: zoneData['DemandSubmitted'],
          supplyOffersCleared: zoneData['SupplyCleared'],
          demandBidsCleared: zoneData['DemandCleared'],
          netCapacityCleared: zoneData['NetCapacityCleared'],
          clearingPrice: zoneData['ClearingPrice']));
    }
    return out;
  }


  Map<String, dynamic> toJson() {
    return {
      'month': month.toInt(),
      'capacityZoneId': capacityZoneId,
      'capacityZoneType': capacityZoneType,
      'capacityZoneName': capacityZoneName,
      'supplyOffersSubmitted': supplyOffersSubmitted,
      'demandBidsSubmitted': demandBidsSubmitted,
      'supplyOffersCleared': supplyOffersCleared,
      'demandBidsCleared': demandBidsCleared,
      'netCapacityCleared': netCapacityCleared,
      'clearingPrice': clearingPrice,
    };
  }
}

class MraCapacityInterfaceRecord extends MraCapacityRecord {
  MraCapacityInterfaceRecord({
    required this.month,
    required this.externalInterfaceId,
    required this.externalInterfaceName,
    required this.supplyOffersSubmitted,
    required this.demandBidsSubmitted,
    required this.supplyOffersCleared,
    required this.demandBidsCleared,
    required this.netCapacityCleared,
    required this.clearingPrice,
  });

  final Month month;
  final int externalInterfaceId;
  final String externalInterfaceName;

  /// in MW
  final num supplyOffersSubmitted;

  /// in MW
  final num supplyOffersCleared;

  /// in MW
  final num demandBidsSubmitted;

  /// in MW
  final num demandBidsCleared;

  /// in MW
  final num netCapacityCleared;

  /// in $/kW-month
  final num clearingPrice;

  /// Input is the Map from ['FCMRAResults']['FCMRAResult'] 
  /// 
  /// Input is the Map from ['FCMRAResults']['FCMRAResult']
  static List<MraCapacityInterfaceRecord> fromJson(Map<String, dynamic> x) {
    final month =
        Month.parse((x['Auction']['Description'] as String), location: UTC);
    final zs = x['ClearedCapacityZones']['ClearedCapacityZone'] as List;
    var out = <MraCapacityInterfaceRecord>[];
    for (Map<String, dynamic> zoneData in zs) {
      var interfaces = zoneData['ClearedExternalInterfaces'];
      if (interfaces == '') continue;
      interfaces =
          zoneData['ClearedExternalInterfaces']['ClearedExternalInterface'];
      late final List interfaceData;
      if (interfaces is Map<String, dynamic>) {
        interfaceData = [interfaces];
      } else if (interfaces is List) {
        interfaceData = interfaces;
      } else if (interfaces == null) {
        continue;
      } else {
        throw StateError('Problem parsing interface data $interfaces');
      }
      for (var one in interfaceData) {
        out.add(MraCapacityInterfaceRecord(
            month: month,
            externalInterfaceId: one['ExternalInterfaceId'],
            externalInterfaceName: one['ExternalInterfaceName'],
            supplyOffersSubmitted: one['SupplySubmitted'],
            demandBidsSubmitted: one['DemandSubmitted'],
            supplyOffersCleared: one['SupplyCleared'],
            demandBidsCleared: one['DemandCleared'],
            netCapacityCleared: one['NetCapacityCleared'],
            clearingPrice: one['ClearingPrice']));
      }
    }

    return out;
  }



  Map<String, dynamic> toJson() {
    return {
      'month': month.toInt(),
      'externalInterfaceId': externalInterfaceId,
      'externalInterfaceName': externalInterfaceName,
      'supplyOffersSubmitted': supplyOffersSubmitted,
      'demandBidsSubmitted': demandBidsSubmitted,
      'supplyOffersCleared': supplyOffersCleared,
      'demandBidsCleared': demandBidsCleared,
      'netCapacityCleared': netCapacityCleared,
      'clearingPrice': clearingPrice,
    };
  }
}
