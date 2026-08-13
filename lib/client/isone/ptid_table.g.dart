part of 'ptid_table.dart';

// Auto-generated Dart stub for DuckDB table: ptid_table
// Created on 2026-08-13 with Dart package reduct

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
    path: '/isone/ptid_table',
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
  Record({required this.nodeType, required this.ptid, required this.name, required this.substationName, required this.unitName, required this.unitShortName, required this.zoneId, required this.reserveId, required this.rspArea, required this.dispatchZone, required this.drReserveAggregationZoneId, required this.activatedOn, required this.deactivatedOn, });

  final NodeType nodeType;
  final int ptid;
  final String name;
  final String? substationName;
  final String? unitName;
  final String? unitShortName;
  final int? zoneId;
  final int? reserveId;
  final String? rspArea;
  final String? dispatchZone;
  final int? drReserveAggregationZoneId;
  final Date activatedOn;
  final Date? deactivatedOn;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      nodeType: NodeType.parse(json['node_type'] as String),
      ptid: json['ptid'] as int,
      name: json['name'] as String,
      substationName: json['substation_name'] as String?,
      unitName: json['unit_name'] as String?,
      unitShortName: json['unit_short_name'] as String?,
      zoneId: json['zone_id'] as int?,
      reserveId: json['reserve_id'] as int?,
      rspArea: json['rsp_area'] as String?,
      dispatchZone: json['dispatch_zone'] as String?,
      drReserveAggregationZoneId: json['dr_reserve_aggregation_zone_id'] as int?,
      activatedOn: Date.parse(json['activated_on'] as String),
      deactivatedOn: json['deactivated_on'] == null ? null : Date.parse(json['deactivated_on'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node_type': nodeType.toString(),
      'ptid': ptid,
      'name': name,
      'substation_name': substationName,
      'unit_name': unitName,
      'unit_short_name': unitShortName,
      'zone_id': zoneId,
      'reserve_id': reserveId,
      'rsp_area': rspArea,
      'dispatch_zone': dispatchZone,
      'dr_reserve_aggregation_zone_id': drReserveAggregationZoneId,
      'activated_on': activatedOn.toIso8601String(),
      'deactivated_on': deactivatedOn?.toIso8601String(),
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
        other.substationName == substationName &&
        other.unitName == unitName &&
        other.unitShortName == unitShortName &&
        other.zoneId == zoneId &&
        other.reserveId == reserveId &&
        other.rspArea == rspArea &&
        other.dispatchZone == dispatchZone &&
        other.drReserveAggregationZoneId == drReserveAggregationZoneId &&
        other.activatedOn == activatedOn &&
        other.deactivatedOn == deactivatedOn &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      nodeType,
      ptid,
      name,
      substationName,
      unitName,
      unitShortName,
      zoneId,
      reserveId,
      rspArea,
      dispatchZone,
      drReserveAggregationZoneId,
      activatedOn,
      deactivatedOn,
    ]);
  }
}

enum NodeType {
    aggregationZone,
    hub,
    interface,
    load,
    loadZone,
    node,
    reserveZone;

  static NodeType parse(String value) {
    return switch (value.toLowerCase()) {
      'aggregation_zone' => NodeType.aggregationZone,
      'hub' => NodeType.hub,
      'interface' => NodeType.interface,
      'load' => NodeType.load,
      'load_zone' => NodeType.loadZone,
      'node' => NodeType.node,
      'reserve_zone' => NodeType.reserveZone,
      _ => throw ArgumentError("Invalid value for NodeType: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      NodeType.aggregationZone => 'aggregation_zone',
      NodeType.hub => 'hub',
      NodeType.interface => 'interface',
      NodeType.load => 'load',
      NodeType.loadZone => 'load_zone',
      NodeType.node => 'node',
      NodeType.reserveZone => 'reserve_zone',
    };
  }
}

class QueryFilter {
  QueryFilter({this.nodeType, this.nodeTypeIn, this.activatedOn, this.activatedOnIn, this.activatedOnGte, this.activatedOnLte, this.deactivatedOn, this.deactivatedOnIn, this.deactivatedOnGte, this.deactivatedOnLte, });

  NodeType? nodeType;
  List<NodeType>? nodeTypeIn;
  Date? activatedOn;
  List<Date>? activatedOnIn;
  Date? activatedOnGte;
  Date? activatedOnLte;
  Date? deactivatedOn;
  List<Date>? deactivatedOnIn;
  Date? deactivatedOnGte;
  Date? deactivatedOnLte;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (nodeType != null) { params['node_type'] = nodeType.toString();}
    if (nodeTypeIn != null) { params['node_type_in'] = nodeTypeIn!.map((e) => e.toString()).join(',');}
    if (activatedOn != null) { params['activated_on'] = activatedOn!.toIso8601String();}
    if (activatedOnIn != null) { params['activated_on_in'] = activatedOnIn!.map((e) => e.toIso8601String()).join(',');}
    if (activatedOnGte != null) { params['activated_on_gte'] = activatedOnGte!.toIso8601String();}
    if (activatedOnLte != null) { params['activated_on_lte'] = activatedOnLte!.toIso8601String();}
    if (deactivatedOn != null) { params['deactivated_on'] = deactivatedOn!.toIso8601String();}
    if (deactivatedOnIn != null) { params['deactivated_on_in'] = deactivatedOnIn!.map((e) => e.toIso8601String()).join(',');}
    if (deactivatedOnGte != null) { params['deactivated_on_gte'] = deactivatedOnGte!.toIso8601String();}
    if (deactivatedOnLte != null) { params['deactivated_on_lte'] = deactivatedOnLte!.toIso8601String();}
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  nodeType: $nodeType');
    buffer.writeln('  nodeTypeIn: $nodeTypeIn');
    buffer.writeln('  activatedOn: $activatedOn');
    buffer.writeln('  activatedOnIn: $activatedOnIn');
    buffer.writeln('  activatedOnGte: $activatedOnGte');
    buffer.writeln('  activatedOnLte: $activatedOnLte');
    buffer.writeln('  deactivatedOn: $deactivatedOn');
    buffer.writeln('  deactivatedOnIn: $deactivatedOnIn');
    buffer.writeln('  deactivatedOnGte: $deactivatedOnGte');
    buffer.writeln('  deactivatedOnLte: $deactivatedOnLte');
    return buffer.toString();
  }
}
