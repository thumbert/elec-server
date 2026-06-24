// Auto-generated Dart stub for DuckDB table: fuel_mix
// Created on 2026-06-24 with Dart package reduct

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart';

/// Function to query records from the DuckDB table via REST API
/// Use the [QueryFilter] to specify filtering criteria.  Note:
/// an empty filter will return all records if [limit] is not specified.
/// [rootUrl] is the base URL of the API endpoint.
/// Optional [limit] can be provided to limit the number of records.
///
Future<List<Record>> queryRecords({ required QueryFilter filter,  required String rootUrl,  int? limit,  http.Client? client, }) async {
  client ??= http.Client();
  final queryParams = filter.toUriParams();
  if (limit != null) {
    queryParams['_limit'] = limit.toString();
  }
  final uri = Uri.parse(rootUrl).replace(
    path: '/hq/fuel_mix',
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
  Record({required this.zoned, required this.total, required this.hydro, required this.wind, required this.solar, required this.other, required this.thermal, });

  final TZDateTime zoned;
  final int total;
  final int hydro;
  final int wind;
  final int solar;
  final int other;
  final int thermal;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      zoned: TZDateTime.parse(getLocation('America/New_York'), json['zoned'] as String),
      total: json['total'] as int,
      hydro: json['hydro'] as int,
      wind: json['wind'] as int,
      solar: json['solar'] as int,
      other: json['other'] as int,
      thermal: json['thermal'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zoned': zoned.toIso8601String(),
      'total': total,
      'hydro': hydro,
      'wind': wind,
      'solar': solar,
      'other': other,
      'thermal': thermal,
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
        other.zoned == zoned &&
        other.total == total &&
        other.hydro == hydro &&
        other.wind == wind &&
        other.solar == solar &&
        other.other == other &&
        other.thermal == thermal &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      zoned,
      total,
      hydro,
      wind,
      solar,
      other,
      thermal,
    ]);
  }
}

class QueryFilter {
  QueryFilter({this.zoned, this.zonedGte, this.zonedLt, });

  TZDateTime? zoned;
  TZDateTime? zonedGte;
  TZDateTime? zonedLt;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (zoned != null) { params['zoned'] = '${zoned!.toIso8601String()}[${zoned!.location.name}]';}
    if (zonedGte != null) { params['zoned_gte'] = '${zonedGte!.toIso8601String()}[${zonedGte!.location.name}]';}
    if (zonedLt != null) { params['zoned_lt'] = '${zonedLt!.toIso8601String()}[${zonedLt!.location.name}]';}
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  zoned: $zoned');
    buffer.writeln('  zonedGte: $zonedGte');
    buffer.writeln('  zonedLt: $zonedLt');
    return buffer.toString();
  }
}
