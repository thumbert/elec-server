import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart';

/// Function to query records from the DuckDB table via REST API
/// Use the [term], [nodeNames], and [components] to specify filtering criteria.
/// [rootUrl] is the base URL of the API endpoint.
/// [term] specifies the start and end dates for the query.
/// [nodeNames] is a list of node names to filter the records.
/// [components] is a list of LMP components to include in the query.
///
Future<List<HourlyRecord>> getHourlyLmpPrices({
  required Term term,
  required List<String> nodeNames,
  required Market market,
  List<LmpComponent> components = const [LmpComponent.lmp],
  required String rootUrl,
  http.Client? client,
}) async {
  if (market != Market.da) {
    throw Exception('Only the day-ahead market is currently supported.');
  }

  client ??= http.Client();
  final queryParams = <String, String>{};
  queryParams['node_ids'] = nodeNames.join(',');
  if (components.isNotEmpty) {
    queryParams['components'] = components.map((c) => c.toString()).join(',');
  }
  final uri = Uri.parse(rootUrl).replace(
    path:
        '/caiso/prices/${market.toString().toLowerCase()}/hourly/start/${term.startDate}/end/${term.endDate}',
    queryParameters: queryParams,
  );
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to load records: ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.map((json) => HourlyRecord.fromJson(json)).toList();
}

class HourlyRecord {
  HourlyRecord({
    required this.hourBeginning,
    required this.nodeName,
    required this.component,
    required this.price,
  });

  final TZDateTime hourBeginning;
  final String nodeName;
  final LmpComponent component;
  final num price;

  static HourlyRecord fromJson(Map<String, dynamic> json) {
    return HourlyRecord(
      hourBeginning:
          TZDateTime.parse(Caiso.location, json['hour_beginning'] as String),
      nodeName: json['name'] as String,
      component: LmpComponent.parse(json['component'] as String),
      price: json['price'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour_beginning': hourBeginning.toIso8601String(),
      'name': nodeName,
      'component': component.toString(),
      'price': price,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HourlyRecord &&
          runtimeType == other.runtimeType &&
          hourBeginning == other.hourBeginning &&
          nodeName == other.nodeName &&
          component == other.component &&
          price == other.price;

  @override
  int get hashCode =>
      hourBeginning.hashCode ^
      nodeName.hashCode ^
      component.hashCode ^
      price.hashCode;
}

class DailyRecord {
  DailyRecord(
      {required this.date,
      required this.nodeName,
      required this.bucket,
      required this.price});

  final Date date;
  final String nodeName;
  final Bucket bucket;
  final num price;

  static DailyRecord fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: Date.parse(json['date'] as String, location: Caiso.location),
      nodeName: json['name'] as String,
      bucket: Bucket.parse(json['bucket'] as String),
      price: json['price'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'name': nodeName,
      'bucket': bucket.toString(),
      'price': price,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyRecord &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          nodeName == other.nodeName &&
          bucket == other.bucket &&
          price == other.price;

  @override
  int get hashCode =>
      date.hashCode ^ nodeName.hashCode ^ bucket.hashCode ^ price.hashCode;
}

class MonthlyRecord {
  MonthlyRecord(
      {required this.month,
      required this.nodeName,
      required this.bucket,
      required this.price});

  final Month month;
  final String nodeName;
  final Bucket bucket;
  final num price;

  static MonthlyRecord fromJson(Map<String, dynamic> json) {
    return MonthlyRecord(
      month: Month.parse(json['month'] as String, location: Caiso.location),
      nodeName: json['name'] as String,
      bucket: Bucket.parse(json['bucket'] as String),
      price: json['price'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month.toIso8601String(),
      'name': nodeName,
      'bucket': bucket.toString(),
      'price': price,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyRecord &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          nodeName == other.nodeName &&
          bucket == other.bucket &&
          price == other.price;

  @override
  int get hashCode =>
      month.hashCode ^ nodeName.hashCode ^ bucket.hashCode ^ price.hashCode;
}

class TermRecord {
  TermRecord(
      {required this.term,
      required this.nodeName,
      required this.bucket,
      required this.price});

  final Term term;
  final String nodeName;
  final Bucket bucket;
  final num price;

  static TermRecord fromJson(Map<String, dynamic> json) {
    return TermRecord(
      term: Term.parse(json['term'] as String, Caiso.location),
      nodeName: json['name'] as String,
      bucket: Bucket.parse(json['bucket'] as String),
      price: json['price'] as num,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'term': term.toString(),
      'name': nodeName,
      'bucket': bucket.toString(),
      'price': price,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TermRecord &&
          runtimeType == other.runtimeType &&
          term == other.term &&
          nodeName == other.nodeName &&
          bucket == other.bucket &&
          price == other.price;

  @override
  int get hashCode =>
      term.hashCode ^ nodeName.hashCode ^ bucket.hashCode ^ price.hashCode;
}

enum LmpComponent {
  lmp,
  mcl,
  mcc,
  mghg;

  static LmpComponent parse(String value) {
    return switch (value.toLowerCase()) {
      'lmp' => LmpComponent.lmp,
      'mcl' => LmpComponent.mcl,
      'mcc' => LmpComponent.mcc,
      'mghg' => LmpComponent.mghg,
      _ => throw ArgumentError("Invalid value for Caiso LmpComponent: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      LmpComponent.lmp => 'LMP',
      LmpComponent.mcl => 'MCL',
      LmpComponent.mcc => 'MCC',
      LmpComponent.mghg => 'MGHG',
    };
  }
}
