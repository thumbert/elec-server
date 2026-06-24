// Auto-generated Dart stub for DuckDB table: ptid_table
// Created on 2026-06-17 with Dart package reduct

import 'dart:convert';

import 'package:date/date.dart';
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
    path: '/nyiso/ptid_table',
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
  Record({required this.nodeType, required this.ptid, required this.name, required this.aggregationPtid, required this.subzone, required this.zone, required this.latitude, required this.longitude, required this.active, required this.asof, });

  final NodeType nodeType;
  final int ptid;
  final String name;
  final int? aggregationPtid;
  final String? subzone;
  final String zone;
  final double? latitude;
  final double? longitude;
  final bool active;
  final Date asof;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      nodeType: NodeType.parse(json['node_type'] as String),
      ptid: json['ptid'] as int,
      name: json['name'] as String,
      aggregationPtid: json['aggregation_ptid'] as int?,
      subzone: json['subzone'] as String?,
      zone: json['zone'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      active: json['active'] as bool,
      asof: Date.parse(json['asof'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node_type': nodeType.toString(),
      'ptid': ptid,
      'name': name,
      'aggregation_ptid': aggregationPtid,
      'subzone': subzone,
      'zone': zone,
      'latitude': latitude,
      'longitude': longitude,
      'active': active,
      'asof': asof.toIso8601String(),
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
        other.nodeType == nodeType &&
        other.ptid == ptid &&
        other.name == name &&
        other.aggregationPtid == aggregationPtid &&
        other.subzone == subzone &&
        other.zone == zone &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.active == active &&
        other.asof == asof &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      nodeType,
      ptid,
      name,
      aggregationPtid,
      subzone,
      zone,
      latitude,
      longitude,
      active,
      asof,
    ]);
  }
}

enum NodeType {
    gen,
    zone;

  static NodeType parse(String value) {
    return switch (value.toLowerCase()) {
      'gen' => NodeType.gen,
      'zone' => NodeType.zone,
      _ => throw ArgumentError("Invalid value for NodeType: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      NodeType.gen => 'gen',
      NodeType.zone => 'zone',
    };
  }
}


class QueryFilter {
  QueryFilter({
    this.nodeType,
    this.nodeTypeIn,
    this.zone,
    this.zoneLike,
    this.zoneIn,
  });

  NodeType? nodeType;
  List<NodeType>? nodeTypeIn;
  String? zone;
  String? zoneLike;
  List<String>? zoneIn;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (nodeType != null) {
      params['node_type'] = nodeType.toString();
    }
    if (nodeTypeIn != null) {
      params['node_type_in'] = nodeTypeIn!.map((e) => e.toString()).join(',');
    }
    if (zone != null) {
      params['zone'] = zone.toString();
    }
    if (zoneLike != null) {
      params['zone_like'] = zoneLike.toString();
    }
    if (zoneIn != null) {
      params['zone_in'] = zoneIn!.map((e) => e.toString()).join(',');
    }
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  nodeType: $nodeType');
    buffer.writeln('  nodeTypeIn: $nodeTypeIn');
    buffer.writeln('  zone: $zone');
    buffer.writeln('  zoneLike: $zoneLike');
    buffer.writeln('  zoneIn: $zoneIn');
    return buffer.toString();
  }
}
