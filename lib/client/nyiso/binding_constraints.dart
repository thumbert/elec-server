// Auto-generated Dart stub for DuckDB table: binding_constraints
// Created on 2026-06-07 with Dart package reduct

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart';

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
    path: '/nyiso/binding_constraints',
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
    required this.market,
    required this.hourBeginning,
    required this.limitingFacility,
    required this.facilityPtid,
    required this.contingency,
    required this.constraintCost,
  });

  final Market market;
  final TZDateTime hourBeginning;
  final String limitingFacility;
  final int facilityPtid;
  final String contingency;
  final num constraintCost;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      market: Market.parse(json['market'] as String),
      hourBeginning: TZDateTime.parse(
          getLocation('America/New_York'), json['hour_beginning'] as String),
      limitingFacility: json['limiting_facility'] as String,
      facilityPtid: json['facility_ptid'] as int,
      contingency: json['contingency'] as String,
      constraintCost: json['constraint_cost'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'market': market.toString(),
      'hour_beginning': hourBeginning.toIso8601String(),
      'limiting_facility': limitingFacility,
      'facility_ptid': facilityPtid,
      'contingency': contingency,
      'constraint_cost': constraintCost,
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
        other.market == market &&
        other.hourBeginning == hourBeginning &&
        other.limitingFacility == limitingFacility &&
        other.facilityPtid == facilityPtid &&
        other.contingency == contingency &&
        other.constraintCost == constraintCost &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      market,
      hourBeginning,
      limitingFacility,
      facilityPtid,
      contingency,
      constraintCost,
    ]);
  }
}

enum Market {
  da,
  rt;

  static Market parse(String value) {
    return switch (value.toLowerCase()) {
      'da' => Market.da,
      'rt' => Market.rt,
      _ => throw ArgumentError("Invalid value for Market: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      Market.da => 'DA',
      Market.rt => 'RT',
    };
  }
}

class QueryFilter {
  QueryFilter({
    this.market,
    this.marketIn,
    this.hourBeginning,
    this.hourBeginningGte,
    this.hourBeginningLt,
    this.limitingFacility,
    this.limitingFacilityLike,
    this.limitingFacilityIn,
    this.facilityPtid,
    this.facilityPtidIn,
    this.facilityPtidGte,
    this.facilityPtidLte,
    this.contingency,
    this.contingencyLike,
    this.contingencyIn,
    this.constraintCost,
    this.constraintCostIn,
    this.constraintCostGte,
    this.constraintCostLte,
  });

  Market? market;
  List<Market>? marketIn;
  TZDateTime? hourBeginning;
  TZDateTime? hourBeginningGte;
  TZDateTime? hourBeginningLt;
  String? limitingFacility;
  String? limitingFacilityLike;
  List<String>? limitingFacilityIn;
  int? facilityPtid;
  List<int>? facilityPtidIn;
  int? facilityPtidGte;
  int? facilityPtidLte;
  String? contingency;
  String? contingencyLike;
  List<String>? contingencyIn;
  num? constraintCost;
  List<num>? constraintCostIn;
  num? constraintCostGte;
  num? constraintCostLte;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (market != null) {
      params['market'] = market.toString();
    }
    if (marketIn != null) {
      params['market_in'] = marketIn!.map((e) => e.toString()).join(',');
    }
    if (hourBeginning != null) {
      params['hour_beginning'] =
          '${hourBeginning!.toIso8601String()}[${hourBeginning!.location.name}]';
    }
    if (hourBeginningGte != null) {
      params['hour_beginning_gte'] =
          '${hourBeginningGte!.toIso8601String()}[${hourBeginningGte!.location.name}]';
    }
    if (hourBeginningLt != null) {
      params['hour_beginning_lt'] =
          '${hourBeginningLt!.toIso8601String()}[${hourBeginningLt!.location.name}]';
    }
    if (limitingFacility != null) {
      params['limiting_facility'] = limitingFacility.toString();
    }
    if (limitingFacilityLike != null) {
      params['limiting_facility_like'] = limitingFacilityLike.toString();
    }
    if (limitingFacilityIn != null) {
      params['limiting_facility_in'] =
          limitingFacilityIn!.map((e) => e.toString()).join(',');
    }
    if (facilityPtid != null) {
      params['facility_ptid'] = facilityPtid.toString();
    }
    if (facilityPtidIn != null) {
      params['facility_ptid_in'] =
          facilityPtidIn!.map((e) => e.toString()).join(',');
    }
    if (facilityPtidGte != null) {
      params['facility_ptid_gte'] = facilityPtidGte.toString();
    }
    if (facilityPtidLte != null) {
      params['facility_ptid_lte'] = facilityPtidLte.toString();
    }
    if (contingency != null) {
      params['contingency'] = contingency.toString();
    }
    if (contingencyLike != null) {
      params['contingency_like'] = contingencyLike.toString();
    }
    if (contingencyIn != null) {
      params['contingency_in'] =
          contingencyIn!.map((e) => e.toString()).join(',');
    }
    if (constraintCost != null) {
      params['constraint_cost'] = constraintCost.toString();
    }
    if (constraintCostIn != null) {
      params['constraint_cost_in'] =
          constraintCostIn!.map((e) => e.toString()).join(',');
    }
    if (constraintCostGte != null) {
      params['constraint_cost_gte'] = constraintCostGte.toString();
    }
    if (constraintCostLte != null) {
      params['constraint_cost_lte'] = constraintCostLte.toString();
    }
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  market: $market');
    buffer.writeln('  marketIn: $marketIn');
    buffer.writeln('  hourBeginning: $hourBeginning');
    buffer.writeln('  hourBeginningGte: $hourBeginningGte');
    buffer.writeln('  hourBeginningLt: $hourBeginningLt');
    buffer.writeln('  limitingFacility: $limitingFacility');
    buffer.writeln('  limitingFacilityLike: $limitingFacilityLike');
    buffer.writeln('  limitingFacilityIn: $limitingFacilityIn');
    buffer.writeln('  facilityPtid: $facilityPtid');
    buffer.writeln('  facilityPtidIn: $facilityPtidIn');
    buffer.writeln('  facilityPtidGte: $facilityPtidGte');
    buffer.writeln('  facilityPtidLte: $facilityPtidLte');
    buffer.writeln('  contingency: $contingency');
    buffer.writeln('  contingencyLike: $contingencyLike');
    buffer.writeln('  contingencyIn: $contingencyIn');
    buffer.writeln('  constraintCost: $constraintCost');
    buffer.writeln('  constraintCostIn: $constraintCostIn');
    buffer.writeln('  constraintCostGte: $constraintCostGte');
    buffer.writeln('  constraintCostLte: $constraintCostLte');
    return buffer.toString();
  }
}
