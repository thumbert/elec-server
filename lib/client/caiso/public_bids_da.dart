// Auto-generated Dart stub for DuckDB table: public_bids_da
// Created on 2026-01-07 with Dart package reduct

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
    path: '/caiso/public_bids_da',
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
    required this.resourceType,
    required this.schedulingCoordinatorSeq,
    required this.resourceBidSeq,
    required this.timeIntervalStart,
    required this.timeIntervalEnd,
    required this.productBidDesc,
    required this.productBidMrid,
    required this.marketProductDesc,
    required this.marketProductType,
    required this.selfSchedMw,
    required this.schBidTimeIntervalStart,
    required this.schBidTimeIntervalEnd,
    required this.schBidXaxisData,
    required this.schBidY1axisData,
    required this.schBidY2axisData,
    required this.schBidCurveType,
    required this.minEohStateOfCharge,
    required this.maxEohStateOfCharge,
  });

  final TZDateTime hourBeginning;
  final ResourceType resourceType;
  final int schedulingCoordinatorSeq;
  final int resourceBidSeq;
  final TZDateTime? timeIntervalStart;
  final TZDateTime? timeIntervalEnd;
  final String? productBidDesc;
  final String? productBidMrid;
  final String? marketProductDesc;
  final String? marketProductType;
  final num? selfSchedMw;
  final TZDateTime? schBidTimeIntervalStart;
  final TZDateTime? schBidTimeIntervalEnd;
  final num? schBidXaxisData;
  final num? schBidY1axisData;
  final num? schBidY2axisData;
  final SchBidCurveType? schBidCurveType;
  final num? minEohStateOfCharge;
  final num? maxEohStateOfCharge;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      hourBeginning: TZDateTime.parse(
          getLocation('America/Los_Angeles'), json['hour_beginning'] as String),
      resourceType: ResourceType.parse(json['resource_type'] as String),
      schedulingCoordinatorSeq: json['scheduling_coordinator_seq'] as int,
      resourceBidSeq: json['resource_bid_seq'] as int,
      timeIntervalStart: json['time_interval_start'] == null
          ? null
          : TZDateTime.parse(getLocation('America/Los_Angeles'),
              json['time_interval_start'] as String),
      timeIntervalEnd: json['time_interval_end'] == null
          ? null
          : TZDateTime.parse(getLocation('America/Los_Angeles'),
              json['time_interval_end'] as String),
      productBidDesc: json['product_bid_desc'] as String?,
      productBidMrid: json['product_bid_mrid'] as String?,
      marketProductDesc: json['market_product_desc'] as String?,
      marketProductType: json['market_product_type'] as String?,
      selfSchedMw: json['self_sched_mw'] as num?,
      schBidTimeIntervalStart: json['sch_bid_time_interval_start'] == null
          ? null
          : TZDateTime.parse(getLocation('America/Los_Angeles'),
              json['sch_bid_time_interval_start'] as String),
      schBidTimeIntervalEnd: json['sch_bid_time_interval_end'] == null
          ? null
          : TZDateTime.parse(getLocation('America/Los_Angeles'),
              json['sch_bid_time_interval_end'] as String),
      schBidXaxisData: json['sch_bid_xaxis_data'] as num?,
      schBidY1axisData: json['sch_bid_y1axis_data'] as num?,
      schBidY2axisData: json['sch_bid_y2axis_data'] as num?,
      schBidCurveType: json['sch_bid_curve_type'] == null
          ? null
          : SchBidCurveType.parse(json['sch_bid_curve_type'] as String),
      minEohStateOfCharge: json['min_eoh_state_of_charge'] as num?,
      maxEohStateOfCharge: json['max_eoh_state_of_charge'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour_beginning': hourBeginning.toIso8601String(),
      'resourceType': resourceType.toString(),
      'schedulingCoordinatorSeq': schedulingCoordinatorSeq,
      'resourceBidSeq': resourceBidSeq,
      'time_interval_start': timeIntervalStart?.toIso8601String(),
      'time_interval_end': timeIntervalEnd?.toIso8601String(),
      'productBidDesc': productBidDesc,
      'productBidMrid': productBidMrid,
      'marketProductDesc': marketProductDesc,
      'marketProductType': marketProductType,
      'selfSchedMw': selfSchedMw,
      'sch_bid_time_interval_start': schBidTimeIntervalStart?.toIso8601String(),
      'sch_bid_time_interval_end': schBidTimeIntervalEnd?.toIso8601String(),
      'schBidXaxisData': schBidXaxisData,
      'schBidY1axisData': schBidY1axisData,
      'schBidY2axisData': schBidY2axisData,
      'schBidCurveType': schBidCurveType?.toString(),
      'minEohStateOfCharge': minEohStateOfCharge,
      'maxEohStateOfCharge': maxEohStateOfCharge,
    };
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

enum ResourceType {
  generator,
  intertie,
  load;

  static ResourceType parse(String value) {
    return switch (value.toLowerCase()) {
      'generator' => ResourceType.generator,
      'intertie' => ResourceType.intertie,
      'load' => ResourceType.load,
      _ => throw ArgumentError("Invalid value for ResourceType: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      ResourceType.generator => 'Generator',
      ResourceType.intertie => 'Intertie',
      ResourceType.load => 'Load',
    };
  }
}

enum SchBidCurveType {
  bidprice;

  static SchBidCurveType parse(String value) {
    return switch (value.toLowerCase()) {
      'bidprice' => SchBidCurveType.bidprice,
      _ => throw ArgumentError("Invalid value for SchBidCurveType: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      SchBidCurveType.bidprice => 'Bidprice',
    };
  }
}

class QueryFilter {
  QueryFilter({
    this.hourBeginning,
    this.hourBeginningGte,
    this.hourBeginningLt,
    this.resourceType,
    this.resourceTypeIn,
    this.schedulingCoordinatorSeq,
    this.schedulingCoordinatorSeqIn,
    this.schedulingCoordinatorSeqGte,
    this.schedulingCoordinatorSeqLte,
    this.resourceBidSeq,
    this.resourceBidSeqIn,
    this.resourceBidSeqGte,
    this.resourceBidSeqLte,
    this.timeIntervalStart,
    this.timeIntervalStartGte,
    this.timeIntervalStartLt,
    this.timeIntervalEnd,
    this.timeIntervalEndGte,
    this.timeIntervalEndLt,
    this.productBidDesc,
    this.productBidDescLike,
    this.productBidDescIn,
    this.productBidMrid,
    this.productBidMridLike,
    this.productBidMridIn,
    this.marketProductDesc,
    this.marketProductDescLike,
    this.marketProductDescIn,
    this.marketProductType,
    this.marketProductTypeLike,
    this.marketProductTypeIn,
    this.selfSchedMw,
    this.selfSchedMwIn,
    this.selfSchedMwGte,
    this.selfSchedMwLte,
    this.schBidTimeIntervalStart,
    this.schBidTimeIntervalStartGte,
    this.schBidTimeIntervalStartLt,
    this.schBidTimeIntervalEnd,
    this.schBidTimeIntervalEndGte,
    this.schBidTimeIntervalEndLt,
    this.schBidXaxisData,
    this.schBidXaxisDataIn,
    this.schBidXaxisDataGte,
    this.schBidXaxisDataLte,
    this.schBidY1axisData,
    this.schBidY1axisDataIn,
    this.schBidY1axisDataGte,
    this.schBidY1axisDataLte,
    this.schBidY2axisData,
    this.schBidY2axisDataIn,
    this.schBidY2axisDataGte,
    this.schBidY2axisDataLte,
    this.schBidCurveType,
    this.schBidCurveTypeIn,
    this.minEohStateOfCharge,
    this.minEohStateOfChargeIn,
    this.minEohStateOfChargeGte,
    this.minEohStateOfChargeLte,
    this.maxEohStateOfCharge,
    this.maxEohStateOfChargeIn,
    this.maxEohStateOfChargeGte,
    this.maxEohStateOfChargeLte,
  });

  TZDateTime? hourBeginning;
  TZDateTime? hourBeginningGte;
  TZDateTime? hourBeginningLt;
  ResourceType? resourceType;
  List<ResourceType>? resourceTypeIn;
  int? schedulingCoordinatorSeq;
  List<int>? schedulingCoordinatorSeqIn;
  int? schedulingCoordinatorSeqGte;
  int? schedulingCoordinatorSeqLte;
  int? resourceBidSeq;
  List<int>? resourceBidSeqIn;
  int? resourceBidSeqGte;
  int? resourceBidSeqLte;
  TZDateTime? timeIntervalStart;
  TZDateTime? timeIntervalStartGte;
  TZDateTime? timeIntervalStartLt;
  TZDateTime? timeIntervalEnd;
  TZDateTime? timeIntervalEndGte;
  TZDateTime? timeIntervalEndLt;
  String? productBidDesc;
  String? productBidDescLike;
  List<String>? productBidDescIn;
  String? productBidMrid;
  String? productBidMridLike;
  List<String>? productBidMridIn;
  String? marketProductDesc;
  String? marketProductDescLike;
  List<String>? marketProductDescIn;
  String? marketProductType;
  String? marketProductTypeLike;
  List<String>? marketProductTypeIn;
  num? selfSchedMw;
  List<num>? selfSchedMwIn;
  num? selfSchedMwGte;
  num? selfSchedMwLte;
  TZDateTime? schBidTimeIntervalStart;
  TZDateTime? schBidTimeIntervalStartGte;
  TZDateTime? schBidTimeIntervalStartLt;
  TZDateTime? schBidTimeIntervalEnd;
  TZDateTime? schBidTimeIntervalEndGte;
  TZDateTime? schBidTimeIntervalEndLt;
  num? schBidXaxisData;
  List<num>? schBidXaxisDataIn;
  num? schBidXaxisDataGte;
  num? schBidXaxisDataLte;
  num? schBidY1axisData;
  List<num>? schBidY1axisDataIn;
  num? schBidY1axisDataGte;
  num? schBidY1axisDataLte;
  num? schBidY2axisData;
  List<num>? schBidY2axisDataIn;
  num? schBidY2axisDataGte;
  num? schBidY2axisDataLte;
  SchBidCurveType? schBidCurveType;
  List<SchBidCurveType>? schBidCurveTypeIn;
  num? minEohStateOfCharge;
  List<num>? minEohStateOfChargeIn;
  num? minEohStateOfChargeGte;
  num? minEohStateOfChargeLte;
  num? maxEohStateOfCharge;
  List<num>? maxEohStateOfChargeIn;
  num? maxEohStateOfChargeGte;
  num? maxEohStateOfChargeLte;

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
    if (resourceType != null) {
      params['resource_type'] = (resourceType).toString();
    }
    if (resourceTypeIn != null) {
      params['resource_type_in'] =
          resourceTypeIn!.map((e) => e.toString()).join(',');
    }
    if (schedulingCoordinatorSeq != null) {
      params['scheduling_coordinator_seq'] =
          (schedulingCoordinatorSeq).toString();
    }
    if (schedulingCoordinatorSeqIn != null) {
      params['scheduling_coordinator_seq_in'] =
          schedulingCoordinatorSeqIn!.map((e) => e.toString()).join(',');
    }
    if (schedulingCoordinatorSeqGte != null) {
      params['scheduling_coordinator_seq_gte'] =
          (schedulingCoordinatorSeqGte).toString();
    }
    if (schedulingCoordinatorSeqLte != null) {
      params['scheduling_coordinator_seq_lte'] =
          (schedulingCoordinatorSeqLte).toString();
    }
    if (resourceBidSeq != null) {
      params['resource_bid_seq'] = (resourceBidSeq).toString();
    }
    if (resourceBidSeqIn != null) {
      params['resource_bid_seq_in'] =
          resourceBidSeqIn!.map((e) => e.toString()).join(',');
    }
    if (resourceBidSeqGte != null) {
      params['resource_bid_seq_gte'] = (resourceBidSeqGte).toString();
    }
    if (resourceBidSeqLte != null) {
      params['resource_bid_seq_lte'] = (resourceBidSeqLte).toString();
    }
    if (timeIntervalStart != null) {
      params['time_interval_start'] =
          '${timeIntervalStart!.toIso8601String()}[${timeIntervalStart!.location.name}]';
    }
    if (timeIntervalStartGte != null) {
      params['time_interval_start_gte'] =
          '${timeIntervalStartGte!.toIso8601String()}[${timeIntervalStartGte!.location.name}]';
    }
    if (timeIntervalStartLt != null) {
      params['time_interval_start_lt'] =
          '${timeIntervalStartLt!.toIso8601String()}[${timeIntervalStartLt!.location.name}]';
    }
    if (timeIntervalEnd != null) {
      params['time_interval_end'] =
          '${timeIntervalEnd!.toIso8601String()}[${timeIntervalEnd!.location.name}]';
    }
    if (timeIntervalEndGte != null) {
      params['time_interval_end_gte'] =
          '${timeIntervalEndGte!.toIso8601String()}[${timeIntervalEndGte!.location.name}]';
    }
    if (timeIntervalEndLt != null) {
      params['time_interval_end_lt'] =
          '${timeIntervalEndLt!.toIso8601String()}[${timeIntervalEndLt!.location.name}]';
    }
    if (productBidDesc != null) {
      params['product_bid_desc'] = (productBidDesc).toString();
    }
    if (productBidDescLike != null) {
      params['product_bid_desc_like'] = (productBidDescLike).toString();
    }
    if (productBidDescIn != null) {
      params['product_bid_desc_in'] =
          productBidDescIn!.map((e) => e.toString()).join(',');
    }
    if (productBidMrid != null) {
      params['product_bid_mrid'] = (productBidMrid).toString();
    }
    if (productBidMridLike != null) {
      params['product_bid_mrid_like'] = (productBidMridLike).toString();
    }
    if (productBidMridIn != null) {
      params['product_bid_mrid_in'] =
          productBidMridIn!.map((e) => e.toString()).join(',');
    }
    if (marketProductDesc != null) {
      params['market_product_desc'] = (marketProductDesc).toString();
    }
    if (marketProductDescLike != null) {
      params['market_product_desc_like'] = (marketProductDescLike).toString();
    }
    if (marketProductDescIn != null) {
      params['market_product_desc_in'] =
          marketProductDescIn!.map((e) => e.toString()).join(',');
    }
    if (marketProductType != null) {
      params['market_product_type'] = (marketProductType).toString();
    }
    if (marketProductTypeLike != null) {
      params['market_product_type_like'] = (marketProductTypeLike).toString();
    }
    if (marketProductTypeIn != null) {
      params['market_product_type_in'] =
          marketProductTypeIn!.map((e) => e.toString()).join(',');
    }
    if (selfSchedMw != null) {
      params['self_sched_mw'] = (selfSchedMw).toString();
    }
    if (selfSchedMwIn != null) {
      params['self_sched_mw_in'] =
          selfSchedMwIn!.map((e) => e.toString()).join(',');
    }
    if (selfSchedMwGte != null) {
      params['self_sched_mw_gte'] = (selfSchedMwGte).toString();
    }
    if (selfSchedMwLte != null) {
      params['self_sched_mw_lte'] = (selfSchedMwLte).toString();
    }
    if (schBidTimeIntervalStart != null) {
      params['sch_bid_time_interval_start'] =
          '${schBidTimeIntervalStart!.toIso8601String()}[${schBidTimeIntervalStart!.location.name}]';
    }
    if (schBidTimeIntervalStartGte != null) {
      params['sch_bid_time_interval_start_gte'] =
          '${schBidTimeIntervalStartGte!.toIso8601String()}[${schBidTimeIntervalStartGte!.location.name}]';
    }
    if (schBidTimeIntervalStartLt != null) {
      params['sch_bid_time_interval_start_lt'] =
          '${schBidTimeIntervalStartLt!.toIso8601String()}[${schBidTimeIntervalStartLt!.location.name}]';
    }
    if (schBidTimeIntervalEnd != null) {
      params['sch_bid_time_interval_end'] =
          '${schBidTimeIntervalEnd!.toIso8601String()}[${schBidTimeIntervalEnd!.location.name}]';
    }
    if (schBidTimeIntervalEndGte != null) {
      params['sch_bid_time_interval_end_gte'] =
          '${schBidTimeIntervalEndGte!.toIso8601String()}[${schBidTimeIntervalEndGte!.location.name}]';
    }
    if (schBidTimeIntervalEndLt != null) {
      params['sch_bid_time_interval_end_lt'] =
          '${schBidTimeIntervalEndLt!.toIso8601String()}[${schBidTimeIntervalEndLt!.location.name}]';
    }
    if (schBidXaxisData != null) {
      params['sch_bid_xaxis_data'] = (schBidXaxisData).toString();
    }
    if (schBidXaxisDataIn != null) {
      params['sch_bid_xaxis_data_in'] =
          schBidXaxisDataIn!.map((e) => e.toString()).join(',');
    }
    if (schBidXaxisDataGte != null) {
      params['sch_bid_xaxis_data_gte'] = (schBidXaxisDataGte).toString();
    }
    if (schBidXaxisDataLte != null) {
      params['sch_bid_xaxis_data_lte'] = (schBidXaxisDataLte).toString();
    }
    if (schBidY1axisData != null) {
      params['sch_bid_y1axis_data'] = (schBidY1axisData).toString();
    }
    if (schBidY1axisDataIn != null) {
      params['sch_bid_y1axis_data_in'] =
          schBidY1axisDataIn!.map((e) => e.toString()).join(',');
    }
    if (schBidY1axisDataGte != null) {
      params['sch_bid_y1axis_data_gte'] = (schBidY1axisDataGte).toString();
    }
    if (schBidY1axisDataLte != null) {
      params['sch_bid_y1axis_data_lte'] = (schBidY1axisDataLte).toString();
    }
    if (schBidY2axisData != null) {
      params['sch_bid_y2axis_data'] = (schBidY2axisData).toString();
    }
    if (schBidY2axisDataIn != null) {
      params['sch_bid_y2axis_data_in'] =
          schBidY2axisDataIn!.map((e) => e.toString()).join(',');
    }
    if (schBidY2axisDataGte != null) {
      params['sch_bid_y2axis_data_gte'] = (schBidY2axisDataGte).toString();
    }
    if (schBidY2axisDataLte != null) {
      params['sch_bid_y2axis_data_lte'] = (schBidY2axisDataLte).toString();
    }
    if (schBidCurveType != null) {
      params['sch_bid_curve_type'] = (schBidCurveType).toString();
    }
    if (schBidCurveTypeIn != null) {
      params['sch_bid_curve_type_in'] =
          schBidCurveTypeIn!.map((e) => e.toString()).join(',');
    }
    if (minEohStateOfCharge != null) {
      params['min_eoh_state_of_charge'] = (minEohStateOfCharge).toString();
    }
    if (minEohStateOfChargeIn != null) {
      params['min_eoh_state_of_charge_in'] =
          minEohStateOfChargeIn!.map((e) => e.toString()).join(',');
    }
    if (minEohStateOfChargeGte != null) {
      params['min_eoh_state_of_charge_gte'] =
          (minEohStateOfChargeGte).toString();
    }
    if (minEohStateOfChargeLte != null) {
      params['min_eoh_state_of_charge_lte'] =
          (minEohStateOfChargeLte).toString();
    }
    if (maxEohStateOfCharge != null) {
      params['max_eoh_state_of_charge'] = (maxEohStateOfCharge).toString();
    }
    if (maxEohStateOfChargeIn != null) {
      params['max_eoh_state_of_charge_in'] =
          maxEohStateOfChargeIn!.map((e) => e.toString()).join(',');
    }
    if (maxEohStateOfChargeGte != null) {
      params['max_eoh_state_of_charge_gte'] =
          (maxEohStateOfChargeGte).toString();
    }
    if (maxEohStateOfChargeLte != null) {
      params['max_eoh_state_of_charge_lte'] =
          (maxEohStateOfChargeLte).toString();
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
    buffer.writeln('  resourceType: $resourceType');
    buffer.writeln('  resourceTypeIn: $resourceTypeIn');
    buffer.writeln('  schedulingCoordinatorSeq: $schedulingCoordinatorSeq');
    buffer.writeln('  schedulingCoordinatorSeqIn: $schedulingCoordinatorSeqIn');
    buffer
        .writeln('  schedulingCoordinatorSeqGte: $schedulingCoordinatorSeqGte');
    buffer
        .writeln('  schedulingCoordinatorSeqLte: $schedulingCoordinatorSeqLte');
    buffer.writeln('  resourceBidSeq: $resourceBidSeq');
    buffer.writeln('  resourceBidSeqIn: $resourceBidSeqIn');
    buffer.writeln('  resourceBidSeqGte: $resourceBidSeqGte');
    buffer.writeln('  resourceBidSeqLte: $resourceBidSeqLte');
    buffer.writeln('  timeIntervalStart: $timeIntervalStart');
    buffer.writeln('  timeIntervalStartGte: $timeIntervalStartGte');
    buffer.writeln('  timeIntervalStartLt: $timeIntervalStartLt');
    buffer.writeln('  timeIntervalEnd: $timeIntervalEnd');
    buffer.writeln('  timeIntervalEndGte: $timeIntervalEndGte');
    buffer.writeln('  timeIntervalEndLt: $timeIntervalEndLt');
    buffer.writeln('  productBidDesc: $productBidDesc');
    buffer.writeln('  productBidDescLike: $productBidDescLike');
    buffer.writeln('  productBidDescIn: $productBidDescIn');
    buffer.writeln('  productBidMrid: $productBidMrid');
    buffer.writeln('  productBidMridLike: $productBidMridLike');
    buffer.writeln('  productBidMridIn: $productBidMridIn');
    buffer.writeln('  marketProductDesc: $marketProductDesc');
    buffer.writeln('  marketProductDescLike: $marketProductDescLike');
    buffer.writeln('  marketProductDescIn: $marketProductDescIn');
    buffer.writeln('  marketProductType: $marketProductType');
    buffer.writeln('  marketProductTypeLike: $marketProductTypeLike');
    buffer.writeln('  marketProductTypeIn: $marketProductTypeIn');
    buffer.writeln('  selfSchedMw: $selfSchedMw');
    buffer.writeln('  selfSchedMwIn: $selfSchedMwIn');
    buffer.writeln('  selfSchedMwGte: $selfSchedMwGte');
    buffer.writeln('  selfSchedMwLte: $selfSchedMwLte');
    buffer.writeln('  schBidTimeIntervalStart: $schBidTimeIntervalStart');
    buffer.writeln('  schBidTimeIntervalStartGte: $schBidTimeIntervalStartGte');
    buffer.writeln('  schBidTimeIntervalStartLt: $schBidTimeIntervalStartLt');
    buffer.writeln('  schBidTimeIntervalEnd: $schBidTimeIntervalEnd');
    buffer.writeln('  schBidTimeIntervalEndGte: $schBidTimeIntervalEndGte');
    buffer.writeln('  schBidTimeIntervalEndLt: $schBidTimeIntervalEndLt');
    buffer.writeln('  schBidXaxisData: $schBidXaxisData');
    buffer.writeln('  schBidXaxisDataIn: $schBidXaxisDataIn');
    buffer.writeln('  schBidXaxisDataGte: $schBidXaxisDataGte');
    buffer.writeln('  schBidXaxisDataLte: $schBidXaxisDataLte');
    buffer.writeln('  schBidY1axisData: $schBidY1axisData');
    buffer.writeln('  schBidY1axisDataIn: $schBidY1axisDataIn');
    buffer.writeln('  schBidY1axisDataGte: $schBidY1axisDataGte');
    buffer.writeln('  schBidY1axisDataLte: $schBidY1axisDataLte');
    buffer.writeln('  schBidY2axisData: $schBidY2axisData');
    buffer.writeln('  schBidY2axisDataIn: $schBidY2axisDataIn');
    buffer.writeln('  schBidY2axisDataGte: $schBidY2axisDataGte');
    buffer.writeln('  schBidY2axisDataLte: $schBidY2axisDataLte');
    buffer.writeln('  schBidCurveType: $schBidCurveType');
    buffer.writeln('  schBidCurveTypeIn: $schBidCurveTypeIn');
    buffer.writeln('  minEohStateOfCharge: $minEohStateOfCharge');
    buffer.writeln('  minEohStateOfChargeIn: $minEohStateOfChargeIn');
    buffer.writeln('  minEohStateOfChargeGte: $minEohStateOfChargeGte');
    buffer.writeln('  minEohStateOfChargeLte: $minEohStateOfChargeLte');
    buffer.writeln('  maxEohStateOfCharge: $maxEohStateOfCharge');
    buffer.writeln('  maxEohStateOfChargeIn: $maxEohStateOfChargeIn');
    buffer.writeln('  maxEohStateOfChargeGte: $maxEohStateOfChargeGte');
    buffer.writeln('  maxEohStateOfChargeLte: $maxEohStateOfChargeLte');
    return buffer.toString();
  }
}
