import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec/nyiso.dart';
import 'package:http/http.dart' as http;

/// Function to query records from the DuckDB table via REST API
/// Use the [QueryFilter] to specify filtering criteria.  Note:
/// an empty filter will return all records if [limit] is not specified.
/// [rootUrl] is the base URL of the API endpoint.
/// Optional [limit] can be provided to limit the number of records.
///
Future<List<Record>> queryRecords({
  required QueryFilter filter,
  required String rootUrl,
  int? limit,
  http.Client? client,
}) async {
  client ??= http.Client();
  final queryParams = filter.toUriParams();
  if (limit != null) {
    queryParams['_limit'] = limit.toString();
  }
  final uri = Uri.parse(rootUrl).replace(
    path: '/nyiso/capacity_prices/monthly',
    queryParameters: queryParams,
  );
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to load records: ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.map((json) => Record.fromJson(json)).toList();
}

class Record {
  Record({
    required this.capabilityPeriod,
    required this.auctionMonth,
    required this.forwardMonth,
    required this.location,
    required this.clearingPrice,
    required this.awardedMw,
  });

  final CapabilityPeriod capabilityPeriod;
  final Month auctionMonth;
  final Month forwardMonth;
  final CapacityLocation location;
  final num clearingPrice;
  final num awardedMw;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      capabilityPeriod: CapabilityPeriod(json['capability_period'] as String),
      auctionMonth: Month.parse(json['auction_month'] as String),
      forwardMonth: Month.parse(json['forward_month'] as String),
      location: CapacityLocation.parse(json['location'] as String),
      clearingPrice: json['clearing_price'] as num,
      awardedMw: json['awarded_mw'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'capability_period': capabilityPeriod.name,
      'auction_month': auctionMonth.toString(),
      'forward_month': forwardMonth.toString(),
      'location': location.name,
      'clearing_price': clearingPrice,
      'awarded_mw': awardedMw,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Record &&
        other.capabilityPeriod == capabilityPeriod &&
        other.auctionMonth == auctionMonth &&
        other.forwardMonth == forwardMonth &&
        other.location == location &&
        other.clearingPrice == clearingPrice &&
        other.awardedMw == awardedMw &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      capabilityPeriod,
      auctionMonth,
      forwardMonth,
      location,
      clearingPrice,
      awardedMw,
    ]);
  }
}

class QueryFilter {
  QueryFilter({
    this.capabilityPeriod,
    this.capabilityPeriodLike,
    this.capabilityPeriodIn,
    this.location,
    this.locationLike,
    this.locationIn,
  });

  String? capabilityPeriod;
  String? capabilityPeriodLike;
  List<String>? capabilityPeriodIn;
  String? location;
  String? locationLike;
  List<String>? locationIn;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (capabilityPeriod != null) {
      params['capability_period'] = capabilityPeriod.toString();
    }
    if (capabilityPeriodLike != null) {
      params['capability_period_like'] = capabilityPeriodLike.toString();
    }
    if (capabilityPeriodIn != null) {
      params['capability_period_in'] =
          capabilityPeriodIn!.map((e) => e.toString()).join(',');
    }
    if (location != null) {
      params['location'] = location.toString();
    }
    if (locationLike != null) {
      params['location_like'] = locationLike.toString();
    }
    if (locationIn != null) {
      params['location_in'] = locationIn!.map((e) => e.toString()).join(',');
    }
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  capabilityPeriod: $capabilityPeriod');
    buffer.writeln('  capabilityPeriodLike: $capabilityPeriodLike');
    buffer.writeln('  capabilityPeriodIn: $capabilityPeriodIn');
    buffer.writeln('  location: $location');
    buffer.writeln('  locationLike: $locationLike');
    buffer.writeln('  locationIn: $locationIn');
    return buffer.toString();
  }
}
