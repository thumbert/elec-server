import 'dart:convert';

import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/elec.dart';
import 'package:timezone/timezone.dart';
import 'package:http/http.dart' as http;

Future<List<MraCapacityZoneRecord>> getMraClearingPriceZone(Month month) async {
  final url = '${dotenv.env['RUST_SERVER']}/isone/capacity/mra/results/zone'
      '/start/${month.toIso8601String()}/end/${month.toIso8601String()}';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception(
        'Failed to load MRA clearing price: ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.map((e) {
    final month = Month.fromInt(e['month'] as int, location: IsoNewEngland.location);
    return MraCapacityZoneRecord(
        month: month,
        capacityZoneId: e['capacity_zone_id'] as int,
        capacityZoneType: e['capacity_zone_type'] as String,
        capacityZoneName: e['capacity_zone_name'] as String,
        supplyOffersSubmitted: e['supply_offers_submitted'] as num,
        demandBidsSubmitted: e['demand_bids_submitted'] as num,
        supplyOffersCleared: e['supply_offers_cleared'] as num,
        demandBidsCleared: e['demand_bids_cleared'] as num,
        netCapacityCleared: e['net_capacity_cleared'] as num,
        clearingPrice: e['clearing_price'] as num);
  }).toList();
}

Future<List<MraCapacityInterfaceRecord>> getMraClearingPriceInterface(Month month) async {
  final url = '${dotenv.env['RUST_SERVER']}/isone/capacity/mra/results/interface'
      '/start/${month.toIso8601String()}/end/${month.toIso8601String()}';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception(
        'Failed to load MRA interface clearing prices for ${month.toIso8601String()}: ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.map((e) {
    final month = Month.fromInt(e['month'] as int, location: IsoNewEngland.location);
    return MraCapacityInterfaceRecord(
        month: month,
        externalInterfaceName: e['external_interface_name'] as String,
        externalInterfaceId: e['external_interface_id'] as int,
        supplyOffersSubmitted: e['supply_offers_submitted'] as num,
        demandBidsSubmitted: e['demand_bids_submitted'] as num,
        supplyOffersCleared: e['supply_offers_cleared'] as num,
        demandBidsCleared: e['demand_bids_cleared'] as num,
        netCapacityCleared: e['net_capacity_cleared'] as num,
        clearingPrice: e['clearing_price'] as num);
  }).toList();
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
    final auction = x['Auction'] as Map;
    late List<dynamic> zs;
    if (auction.containsKey('ClearedCapacityZones')) {
      zs = auction['ClearedCapacityZones']['ClearedCapacityZone'];
    } else {
      zs = x['ClearedCapacityZones']['ClearedCapacityZone'];
    }
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
    final auction = x['Auction'] as Map;
    // In 2025-04, the ISO changed the format by nesting the field 'ClearedCapacityZones'
    // under 'Auction'.
    late List<dynamic> zs;
    if (auction.containsKey('ClearedCapacityZones')) {
      zs = auction['ClearedCapacityZones']['ClearedCapacityZone'];
    } else {
      zs = x['ClearedCapacityZones']['ClearedCapacityZone'];
    }
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
