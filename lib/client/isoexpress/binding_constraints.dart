// Auto-generated Dart stub for DuckDB table: constraints
// Created on 2026-07-18 with Dart package reduct

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
    path: '/isone/binding_constraints/da',
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
    required this.hourBeginning,
    required this.constraintName,
    required this.contingencyName,
    required this.marginalValue,
  });

  final TZDateTime hourBeginning;
  final String constraintName;
  final String contingencyName;
  final num marginalValue;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      hourBeginning: TZDateTime.parse(
          getLocation('America/New_York'), json['hour_beginning'] as String),
      constraintName: json['constraint_name'] as String,
      contingencyName: json['contingency_name'] as String,
      marginalValue: json['marginal_value'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour_beginning': hourBeginning.toIso8601String(),
      'constraint_name': constraintName,
      'contingency_name': contingencyName,
      'marginal_value': marginalValue,
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
        other.hourBeginning == hourBeginning &&
        other.constraintName == constraintName &&
        other.contingencyName == contingencyName &&
        other.marginalValue == marginalValue &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      hourBeginning,
      constraintName,
      contingencyName,
      marginalValue,
    ]);
  }
}

class QueryFilter {
  QueryFilter({
    this.hourBeginning,
    this.hourBeginningGte,
    this.hourBeginningLt,
    this.constraintName,
    this.constraintNameLike,
    this.constraintNameIn,
  });

  TZDateTime? hourBeginning;
  TZDateTime? hourBeginningGte;
  TZDateTime? hourBeginningLt;
  String? constraintName;
  String? constraintNameLike;
  List<String>? constraintNameIn;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
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
    if (constraintName != null) {
      params['constraint_name'] = constraintName.toString();
    }
    if (constraintNameLike != null) {
      params['constraint_name_like'] = constraintNameLike.toString();
    }
    if (constraintNameIn != null) {
      params['constraint_name_in'] =
          constraintNameIn!.map((e) => e.toString()).join(',');
    }
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  hourBeginning: $hourBeginning');
    buffer.writeln('  hourBeginningGte: $hourBeginningGte');
    buffer.writeln('  hourBeginningLt: $hourBeginningLt');
    buffer.writeln('  constraintName: $constraintName');
    buffer.writeln('  constraintNameLike: $constraintNameLike');
    buffer.writeln('  constraintNameIn: $constraintNameIn');
    return buffer.toString();
  }
}
