// Auto-generated Dart stub for DuckDB table: zonal_uplift
// Created on 2026-02-18 with Dart package reduct

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
    path: '//nyiso/zonal_uplift',
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
    required this.day,
    required this.ptid,
    required this.name,
    required this.upliftCategory,
    required this.upliftPayment,
  });

  final Date day;
  final String ptid;
  final String name;
  final String upliftCategory;
  final num upliftPayment;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      day: Date.parse(json['day'] as String),
      ptid: json['ptid'] as String,
      name: json['name'] as String,
      upliftCategory: json['uplift_category'] as String,
      upliftPayment: json['uplift_payment'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day.toIso8601String(),
      'ptid': ptid,
      'name': name,
      'upliftCategory': upliftCategory,
      'upliftPayment': upliftPayment,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

class QueryFilter {
  QueryFilter({
    this.day,
    this.dayIn,
    this.dayGte,
    this.dayLte,
    this.ptid,
    this.ptidLike,
    this.ptidIn,
    this.name,
    this.nameLike,
    this.nameIn,
    this.upliftCategory,
    this.upliftCategoryLike,
    this.upliftCategoryIn,
    this.upliftPayment,
    this.upliftPaymentIn,
    this.upliftPaymentGte,
    this.upliftPaymentLte,
  });

  Date? day;
  List<Date>? dayIn;
  Date? dayGte;
  Date? dayLte;
  String? ptid;
  String? ptidLike;
  List<String>? ptidIn;
  String? name;
  String? nameLike;
  List<String>? nameIn;
  String? upliftCategory;
  String? upliftCategoryLike;
  List<String>? upliftCategoryIn;
  num? upliftPayment;
  List<num>? upliftPaymentIn;
  num? upliftPaymentGte;
  num? upliftPaymentLte;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (day != null) {
      params['day'] = day!.toIso8601String();
    }
    if (dayIn != null) {
      params['day_in'] = dayIn!.map((e) => e.toIso8601String()).join(',');
    }
    if (dayGte != null) {
      params['day_gte'] = dayGte!.toIso8601String();
    }
    if (dayLte != null) {
      params['day_lte'] = dayLte!.toIso8601String();
    }
    if (ptid != null) {
      params['ptid'] = (ptid).toString();
    }
    if (ptidLike != null) {
      params['ptid_like'] = (ptidLike).toString();
    }
    if (ptidIn != null) {
      params['ptid_in'] = ptidIn!.map((e) => e.toString()).join(',');
    }
    if (name != null) {
      params['name'] = (name).toString();
    }
    if (nameLike != null) {
      params['name_like'] = (nameLike).toString();
    }
    if (nameIn != null) {
      params['name_in'] = nameIn!.map((e) => e.toString()).join(',');
    }
    if (upliftCategory != null) {
      params['uplift_category'] = (upliftCategory).toString();
    }
    if (upliftCategoryLike != null) {
      params['uplift_category_like'] = (upliftCategoryLike).toString();
    }
    if (upliftCategoryIn != null) {
      params['uplift_category_in'] =
          upliftCategoryIn!.map((e) => e.toString()).join(',');
    }
    if (upliftPayment != null) {
      params['uplift_payment'] = (upliftPayment).toString();
    }
    if (upliftPaymentIn != null) {
      params['uplift_payment_in'] =
          upliftPaymentIn!.map((e) => e.toString()).join(',');
    }
    if (upliftPaymentGte != null) {
      params['uplift_payment_gte'] = (upliftPaymentGte).toString();
    }
    if (upliftPaymentLte != null) {
      params['uplift_payment_lte'] = (upliftPaymentLte).toString();
    }
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  day: $day');
    buffer.writeln('  dayIn: $dayIn');
    buffer.writeln('  dayGte: $dayGte');
    buffer.writeln('  dayLte: $dayLte');
    buffer.writeln('  ptid: $ptid');
    buffer.writeln('  ptidLike: $ptidLike');
    buffer.writeln('  ptidIn: $ptidIn');
    buffer.writeln('  name: $name');
    buffer.writeln('  nameLike: $nameLike');
    buffer.writeln('  nameIn: $nameIn');
    buffer.writeln('  upliftCategory: $upliftCategory');
    buffer.writeln('  upliftCategoryLike: $upliftCategoryLike');
    buffer.writeln('  upliftCategoryIn: $upliftCategoryIn');
    buffer.writeln('  upliftPayment: $upliftPayment');
    buffer.writeln('  upliftPaymentIn: $upliftPaymentIn');
    buffer.writeln('  upliftPaymentGte: $upliftPaymentGte');
    buffer.writeln('  upliftPaymentLte: $upliftPaymentLte');
    return buffer.toString();
  }
}
