// Auto-generated Dart stub for DuckDB table: contracts
// Created on 2026-05-01 with Dart package reduct

import 'dart:convert';

import 'package:http/http.dart' as http;

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
    path: '/nodal/contracts',
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
  Record({required this.physicalCommodityCode, required this.contractLongName, required this.contractShortName, required this.productType, required this.productGroup, required this.settlementType, required this.lotLimitGroup, required this.groupCommodityCode, required this.countOfExpiries, required this.blockExchangeFee, required this.screenExchangeFee, required this.efpExchangeFee, required this.clearingFee, required this.settlementOrOptionExerciseAssignmentFee, required this.gmiExch, required this.gmiFc, required this.description, required this.reportingLevel, required this.spotMonthPositionLimitLots, required this.singleMonthAccountabilityLevelLots, required this.allMonthAccountabilityLevelLots, required this.aggregationGroup, required this.aggregationGroupType, required this.parentContractFlag, required this.cftcReferencedContract, });

  final String physicalCommodityCode;
  final String contractLongName;
  final String contractShortName;
  final String productType;
  final String productGroup;
  final String settlementType;
  final String lotLimitGroup;
  final String groupCommodityCode;
  final int countOfExpiries;
  final num blockExchangeFee;
  final num screenExchangeFee;
  final num? efpExchangeFee;
  final num clearingFee;
  final num settlementOrOptionExerciseAssignmentFee;
  final String gmiExch;
  final String gmiFc;
  final String description;
  final String? reportingLevel;
  final int spotMonthPositionLimitLots;
  final int singleMonthAccountabilityLevelLots;
  final int allMonthAccountabilityLevelLots;
  final int? aggregationGroup;
  final String? aggregationGroupType;
  final bool? parentContractFlag;
  final bool cftcReferencedContract;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      physicalCommodityCode: json['physical_commodity_code'] as String,
      contractLongName: json['contract_long_name'] as String,
      contractShortName: json['contract_short_name'] as String,
      productType: json['product_type'] as String,
      productGroup: json['product_group'] as String,
      settlementType: json['settlement_type'] as String,
      lotLimitGroup: json['lot_limit_group'] as String,
      groupCommodityCode: json['group_commodity_code'] as String,
      countOfExpiries: json['count_of_expiries'] as int,
      blockExchangeFee: json['block_exchange_fee'] as num,
      screenExchangeFee: json['screen_exchange_fee'] as num,
      efpExchangeFee: json['efp_exchange_fee'] as num?,
      clearingFee: json['clearing_fee'] as num,
      settlementOrOptionExerciseAssignmentFee: json['settlement_or_option_exercise_assignment_fee'] as num,
      gmiExch: json['gmi_exch'] as String,
      gmiFc: json['gmi_fc'] as String,
      description: json['description'] as String,
      reportingLevel: json['reporting_level'] as String?,
      spotMonthPositionLimitLots: json['spot_month_position_limit_lots'] as int,
      singleMonthAccountabilityLevelLots: json['single_month_accountability_level_lots'] as int,
      allMonthAccountabilityLevelLots: json['all_month_accountability_level_lots'] as int,
      aggregationGroup: json['aggregation_group'] as int?,
      aggregationGroupType: json['aggregation_group_type'] as String?,
      parentContractFlag: json['parent_contract_flag'] as bool?,
      cftcReferencedContract: json['cftc_referenced_contract'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'physical_commodity_code': physicalCommodityCode,
      'contract_long_name': contractLongName,
      'contract_short_name': contractShortName,
      'product_type': productType,
      'product_group': productGroup,
      'settlement_type': settlementType,
      'lot_limit_group': lotLimitGroup,
      'group_commodity_code': groupCommodityCode,
      'count_of_expiries': countOfExpiries,
      'block_exchange_fee': blockExchangeFee,
      'screen_exchange_fee': screenExchangeFee,
      'efp_exchange_fee': efpExchangeFee,
      'clearing_fee': clearingFee,
      'settlement_or_option_exercise_assignment_fee': settlementOrOptionExerciseAssignmentFee,
      'gmi_exch': gmiExch,
      'gmi_fc': gmiFc,
      'description': description,
      'reporting_level': reportingLevel,
      'spot_month_position_limit_lots': spotMonthPositionLimitLots,
      'single_month_accountability_level_lots': singleMonthAccountabilityLevelLots,
      'all_month_accountability_level_lots': allMonthAccountabilityLevelLots,
      'aggregation_group': aggregationGroup,
      'aggregation_group_type': aggregationGroupType,
      'parent_contract_flag': parentContractFlag,
      'cftc_referenced_contract': cftcReferencedContract,
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
        other.physicalCommodityCode == physicalCommodityCode &&
        other.contractLongName == contractLongName &&
        other.contractShortName == contractShortName &&
        other.productType == productType &&
        other.productGroup == productGroup &&
        other.settlementType == settlementType &&
        other.lotLimitGroup == lotLimitGroup &&
        other.groupCommodityCode == groupCommodityCode &&
        other.countOfExpiries == countOfExpiries &&
        other.blockExchangeFee == blockExchangeFee &&
        other.screenExchangeFee == screenExchangeFee &&
        other.efpExchangeFee == efpExchangeFee &&
        other.clearingFee == clearingFee &&
        other.settlementOrOptionExerciseAssignmentFee == settlementOrOptionExerciseAssignmentFee &&
        other.gmiExch == gmiExch &&
        other.gmiFc == gmiFc &&
        other.description == description &&
        other.reportingLevel == reportingLevel &&
        other.spotMonthPositionLimitLots == spotMonthPositionLimitLots &&
        other.singleMonthAccountabilityLevelLots == singleMonthAccountabilityLevelLots &&
        other.allMonthAccountabilityLevelLots == allMonthAccountabilityLevelLots &&
        other.aggregationGroup == aggregationGroup &&
        other.aggregationGroupType == aggregationGroupType &&
        other.parentContractFlag == parentContractFlag &&
        other.cftcReferencedContract == cftcReferencedContract &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      physicalCommodityCode,
      contractLongName,
      contractShortName,
      productType,
      productGroup,
      settlementType,
      lotLimitGroup,
      groupCommodityCode,
      countOfExpiries,
      blockExchangeFee,
      screenExchangeFee,
      efpExchangeFee,
      clearingFee,
      settlementOrOptionExerciseAssignmentFee,
      gmiExch,
      gmiFc,
      description,
      reportingLevel,
      spotMonthPositionLimitLots,
      singleMonthAccountabilityLevelLots,
      allMonthAccountabilityLevelLots,
      aggregationGroup,
      aggregationGroupType,
      parentContractFlag,
      cftcReferencedContract,
    ]);
  }
}

class QueryFilter {
  QueryFilter({this.productGroup, this.productGroupLike, this.productGroupIn, });

  String? productGroup;
  String? productGroupLike;
  List<String>? productGroupIn;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (productGroup != null) { params['product_group'] = (productGroup).toString();}
    if (productGroupLike != null) { params['product_group_like'] = (productGroupLike).toString();}
    if (productGroupIn != null) { params['product_group_in'] = productGroupIn!.map((e) => e.toString()).join(',');}
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  productGroup: $productGroup');
    buffer.writeln('  productGroupLike: $productGroupLike');
    buffer.writeln('  productGroupIn: $productGroupIn');
    return buffer.toString();
  }
}
