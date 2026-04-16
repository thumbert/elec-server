// Auto-generated Dart stub for DuckDB table: views_asof_date
// Created on 2026-04-15 with Dart package reduct

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:date/date.dart';

Future<List<({String userId, String viewName})>>
    getUniqueUserIdAndViewNamePairs({
  required String rootUrl,
  http.Client? client,
}) async {
  client ??= http.Client();
  final uri = Uri.parse(rootUrl)
      .replace(path: '/ui/eod_settlements/asof_date/users_views');
  final response = await client.get(uri);

  if (response.statusCode != 200) {
    throw Exception(
        'Failed to load unique user/view pairs: ${response.statusCode}');
  }

  final List<dynamic> jsonList = jsonDecode(response.body);
  if (jsonList.isEmpty) {
    throw Exception('No unique user/view pairs found');
  }

  return jsonList
      .map((json) => (
            userId: json[0] as String,
            viewName: json[1] as String
          ))
      .toList();
}

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
    path: '/ui/eod_settlements/asof_date',
    queryParameters: queryParams,
  );
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to load records: ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.map((json) => Record.fromJson(json)).toList();
}

Future<http.Response> insertRecords({
  required List<Record> records,
  required String rootUrl,
  http.Client? client,
}) async {
  final uniquePairs = records
      .map((r) => (userId: r.userId, viewName: r.viewName))
      .toSet()
      .toList();
  if (uniquePairs.length != 1) {
    throw Exception(
        'All records must have the same userId and viewName. Found: $uniquePairs');
  }

  client ??= http.Client();
  final uri = Uri.parse(rootUrl).replace(
    path: '/ui/eod_settlements/asof_date',
  );
  final response = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'user_id': records.first.userId,
      'view_name': records.first.viewName,
      'records': records.map((r) => r.toJson()).toList()}),
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to load records: ${response.statusCode}');
  }
  return response;
}



class Record {
  Record({
    required this.userId,
    required this.viewName,
    required this.rowId,
    required this.source,
    required this.iceCategory,
    required this.iceHub,
    required this.iceProduct,
    required this.endurCurveName,
    required this.nodalContractName,
    required this.asOfDate,
    required this.strip,
    required this.unitConversion,
    required this.label,
  });

  final String userId;
  final String viewName;
  final int rowId;
  final String source;
  final String? iceCategory;
  final String? iceHub;
  final String? iceProduct;
  final String? endurCurveName;
  final String? nodalContractName;
  final Date asOfDate;
  final String? strip;
  final String? unitConversion;
  final String? label;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      userId: json['user_id'] as String,
      viewName: json['view_name'] as String,
      rowId: json['row_id'] as int,
      source: json['source'] as String,
      iceCategory: json['ice_category'] as String?,
      iceHub: json['ice_hub'] as String?,
      iceProduct: json['ice_product'] as String?,
      endurCurveName: json['endur_curve_name'] as String?,
      nodalContractName: json['nodal_contract_name'] as String?,
      asOfDate: Date.parse(json['as_of_date'] as String),
      strip: json['strip'] as String?,
      unitConversion: json['unit_conversion'] as String?,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'view_name': viewName,
      'row_id': rowId,
      'source': source,
      'ice_category': iceCategory,
      'ice_hub': iceHub,
      'ice_product': iceProduct,
      'endur_curve_name': endurCurveName,
      'nodal_contract_name': nodalContractName,
      'as_of_date': asOfDate.toIso8601String(),
      'strip': strip,
      'unit_conversion': unitConversion,
      'label': label,
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
        other.userId == userId &&
        other.viewName == viewName &&
        other.rowId == rowId &&
        other.source == source &&
        other.iceCategory == iceCategory &&
        other.iceHub == iceHub &&
        other.iceProduct == iceProduct &&
        other.endurCurveName == endurCurveName &&
        other.nodalContractName == nodalContractName &&
        other.asOfDate == asOfDate &&
        other.strip == strip &&
        other.unitConversion == unitConversion &&
        other.label == label &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      userId,
      viewName,
      rowId,
      source,
      iceCategory,
      iceHub,
      iceProduct,
      endurCurveName,
      nodalContractName,
      asOfDate,
      strip,
      unitConversion,
      label,
    ]);
  }
}

class QueryFilter {
  QueryFilter({
    this.userId,
    this.userIdLike,
    this.userIdIn,
    this.viewName,
    this.viewNameLike,
    this.viewNameIn,
  });

  String? userId;
  String? userIdLike;
  List<String>? userIdIn;
  String? viewName;
  String? viewNameLike;
  List<String>? viewNameIn;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (userId != null) {
      params['user_id'] = (userId).toString();
    }
    if (userIdLike != null) {
      params['user_id_like'] = (userIdLike).toString();
    }
    if (userIdIn != null) {
      params['user_id_in'] = userIdIn!.map((e) => e.toString()).join(',');
    }
    if (viewName != null) {
      params['view_name'] = (viewName).toString();
    }
    if (viewNameLike != null) {
      params['view_name_like'] = (viewNameLike).toString();
    }
    if (viewNameIn != null) {
      params['view_name_in'] = viewNameIn!.map((e) => e.toString()).join(',');
    }
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  userId: $userId');
    buffer.writeln('  userIdLike: $userIdLike');
    buffer.writeln('  userIdIn: $userIdIn');
    buffer.writeln('  viewName: $viewName');
    buffer.writeln('  viewNameLike: $viewNameLike');
    buffer.writeln('  viewNameIn: $viewNameIn');
    return buffer.toString();
  }
}
