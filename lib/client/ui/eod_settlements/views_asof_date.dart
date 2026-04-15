// Auto-generated Dart stub for DuckDB table: views_asof_date
// Created on 2026-04-15 with Dart package reduct

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:date/date.dart';

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
    this.rowId,
    this.rowIdIn,
    this.rowIdGte,
    this.rowIdLte,
    this.source,
    this.sourceLike,
    this.sourceIn,
    this.iceCategory,
    this.iceCategoryLike,
    this.iceCategoryIn,
    this.iceHub,
    this.iceHubLike,
    this.iceHubIn,
    this.iceProduct,
    this.iceProductLike,
    this.iceProductIn,
    this.endurCurveName,
    this.endurCurveNameLike,
    this.endurCurveNameIn,
    this.nodalContractName,
    this.nodalContractNameLike,
    this.nodalContractNameIn,
    this.asOfDate,
    this.asOfDateIn,
    this.asOfDateGte,
    this.asOfDateLte,
    this.strip,
    this.stripLike,
    this.stripIn,
    this.unitConversion,
    this.unitConversionLike,
    this.unitConversionIn,
    this.label,
    this.labelLike,
    this.labelIn,
  });

  String? userId;
  String? userIdLike;
  List<String>? userIdIn;
  String? viewName;
  String? viewNameLike;
  List<String>? viewNameIn;
  int? rowId;
  List<int>? rowIdIn;
  int? rowIdGte;
  int? rowIdLte;
  String? source;
  String? sourceLike;
  List<String>? sourceIn;
  String? iceCategory;
  String? iceCategoryLike;
  List<String>? iceCategoryIn;
  String? iceHub;
  String? iceHubLike;
  List<String>? iceHubIn;
  String? iceProduct;
  String? iceProductLike;
  List<String>? iceProductIn;
  String? endurCurveName;
  String? endurCurveNameLike;
  List<String>? endurCurveNameIn;
  String? nodalContractName;
  String? nodalContractNameLike;
  List<String>? nodalContractNameIn;
  Date? asOfDate;
  List<Date>? asOfDateIn;
  Date? asOfDateGte;
  Date? asOfDateLte;
  String? strip;
  String? stripLike;
  List<String>? stripIn;
  String? unitConversion;
  String? unitConversionLike;
  List<String>? unitConversionIn;
  String? label;
  String? labelLike;
  List<String>? labelIn;

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
    if (rowId != null) {
      params['row_id'] = (rowId).toString();
    }
    if (rowIdIn != null) {
      params['row_id_in'] = rowIdIn!.map((e) => e.toString()).join(',');
    }
    if (rowIdGte != null) {
      params['row_id_gte'] = (rowIdGte).toString();
    }
    if (rowIdLte != null) {
      params['row_id_lte'] = (rowIdLte).toString();
    }
    if (source != null) {
      params['source'] = (source).toString();
    }
    if (sourceLike != null) {
      params['source_like'] = (sourceLike).toString();
    }
    if (sourceIn != null) {
      params['source_in'] = sourceIn!.map((e) => e.toString()).join(',');
    }
    if (iceCategory != null) {
      params['ice_category'] = (iceCategory).toString();
    }
    if (iceCategoryLike != null) {
      params['ice_category_like'] = (iceCategoryLike).toString();
    }
    if (iceCategoryIn != null) {
      params['ice_category_in'] =
          iceCategoryIn!.map((e) => e.toString()).join(',');
    }
    if (iceHub != null) {
      params['ice_hub'] = (iceHub).toString();
    }
    if (iceHubLike != null) {
      params['ice_hub_like'] = (iceHubLike).toString();
    }
    if (iceHubIn != null) {
      params['ice_hub_in'] = iceHubIn!.map((e) => e.toString()).join(',');
    }
    if (iceProduct != null) {
      params['ice_product'] = (iceProduct).toString();
    }
    if (iceProductLike != null) {
      params['ice_product_like'] = (iceProductLike).toString();
    }
    if (iceProductIn != null) {
      params['ice_product_in'] =
          iceProductIn!.map((e) => e.toString()).join(',');
    }
    if (endurCurveName != null) {
      params['endur_curve_name'] = (endurCurveName).toString();
    }
    if (endurCurveNameLike != null) {
      params['endur_curve_name_like'] = (endurCurveNameLike).toString();
    }
    if (endurCurveNameIn != null) {
      params['endur_curve_name_in'] =
          endurCurveNameIn!.map((e) => e.toString()).join(',');
    }
    if (nodalContractName != null) {
      params['nodal_contract_name'] = (nodalContractName).toString();
    }
    if (nodalContractNameLike != null) {
      params['nodal_contract_name_like'] = (nodalContractNameLike).toString();
    }
    if (nodalContractNameIn != null) {
      params['nodal_contract_name_in'] =
          nodalContractNameIn!.map((e) => e.toString()).join(',');
    }
    if (asOfDate != null) {
      params['as_of_date'] = asOfDate!.toIso8601String();
    }
    if (asOfDateIn != null) {
      params['as_of_date_in'] =
          asOfDateIn!.map((e) => e.toIso8601String()).join(',');
    }
    if (asOfDateGte != null) {
      params['as_of_date_gte'] = asOfDateGte!.toIso8601String();
    }
    if (asOfDateLte != null) {
      params['as_of_date_lte'] = asOfDateLte!.toIso8601String();
    }
    if (strip != null) {
      params['strip'] = (strip).toString();
    }
    if (stripLike != null) {
      params['strip_like'] = (stripLike).toString();
    }
    if (stripIn != null) {
      params['strip_in'] = stripIn!.map((e) => e.toString()).join(',');
    }
    if (unitConversion != null) {
      params['unit_conversion'] = (unitConversion).toString();
    }
    if (unitConversionLike != null) {
      params['unit_conversion_like'] = (unitConversionLike).toString();
    }
    if (unitConversionIn != null) {
      params['unit_conversion_in'] =
          unitConversionIn!.map((e) => e.toString()).join(',');
    }
    if (label != null) {
      params['label'] = (label).toString();
    }
    if (labelLike != null) {
      params['label_like'] = (labelLike).toString();
    }
    if (labelIn != null) {
      params['label_in'] = labelIn!.map((e) => e.toString()).join(',');
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
    buffer.writeln('  rowId: $rowId');
    buffer.writeln('  rowIdIn: $rowIdIn');
    buffer.writeln('  rowIdGte: $rowIdGte');
    buffer.writeln('  rowIdLte: $rowIdLte');
    buffer.writeln('  source: $source');
    buffer.writeln('  sourceLike: $sourceLike');
    buffer.writeln('  sourceIn: $sourceIn');
    buffer.writeln('  iceCategory: $iceCategory');
    buffer.writeln('  iceCategoryLike: $iceCategoryLike');
    buffer.writeln('  iceCategoryIn: $iceCategoryIn');
    buffer.writeln('  iceHub: $iceHub');
    buffer.writeln('  iceHubLike: $iceHubLike');
    buffer.writeln('  iceHubIn: $iceHubIn');
    buffer.writeln('  iceProduct: $iceProduct');
    buffer.writeln('  iceProductLike: $iceProductLike');
    buffer.writeln('  iceProductIn: $iceProductIn');
    buffer.writeln('  endurCurveName: $endurCurveName');
    buffer.writeln('  endurCurveNameLike: $endurCurveNameLike');
    buffer.writeln('  endurCurveNameIn: $endurCurveNameIn');
    buffer.writeln('  nodalContractName: $nodalContractName');
    buffer.writeln('  nodalContractNameLike: $nodalContractNameLike');
    buffer.writeln('  nodalContractNameIn: $nodalContractNameIn');
    buffer.writeln('  asOfDate: $asOfDate');
    buffer.writeln('  asOfDateIn: $asOfDateIn');
    buffer.writeln('  asOfDateGte: $asOfDateGte');
    buffer.writeln('  asOfDateLte: $asOfDateLte');
    buffer.writeln('  strip: $strip');
    buffer.writeln('  stripLike: $stripLike');
    buffer.writeln('  stripIn: $stripIn');
    buffer.writeln('  unitConversion: $unitConversion');
    buffer.writeln('  unitConversionLike: $unitConversionLike');
    buffer.writeln('  unitConversionIn: $unitConversionIn');
    buffer.writeln('  label: $label');
    buffer.writeln('  labelLike: $labelLike');
    buffer.writeln('  labelIn: $labelIn');
    return buffer.toString();
  }
}
