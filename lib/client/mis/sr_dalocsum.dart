// Auto-generated Dart stub for DuckDB table: tab1
// Created on 2026-09-14 with Dart package reduct

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:date/date.dart';
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
  final uri = Uri.parse(rootUrl)
      .replace(path: '/mis/sr_dalocsum/tab1', queryParameters: queryParams);
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to load records: ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.map((json) => Record.fromJson(json)).toList();
}

class Record {
  Record({
    required this.reportDate,
    required this.version,
    required this.accountId,
    required this.subaccountId,
    required this.subaccountName,
    required this.hourBeginning,
    required this.locationId,
    required this.locationName,
    required this.locationType,
    required this.daClearedGeneration,
    required this.daClearedIncrements,
    required this.daClearedImports,
    required this.daGenerationObligation,
    required this.daClearedDemandBids,
    required this.daClearedDecrements,
    required this.daClearedExports,
    required this.daLoadObligation,
    required this.daInternalBilateralForPurchases,
    required this.daInternalBilateralForSales,
    required this.daAdjustedLoadObligation,
    required this.daAdjustedNetInterchange,
    required this.daEnergyComponent,
    required this.daCongestionComponent,
    required this.daMarginalLossComponent,
    required this.daEnergyChargeOrCredit,
    required this.daCongestionChargeOrCredit,
    required this.daMarginalLossChargeOrCredit,
    required this.daClearedAssetRelatedDemandBids,
    required this.daLoadObligationForChargeAllocation,
    required this.daDemandReduction,
    required this.daDemandReductionObligation,
    required this.daClearedSoderaLoad,
    required this.daClearedSoderaGeneration,
  });

  final Date reportDate;
  final DateTime version;
  final int accountId;
  final int? subaccountId;
  final String? subaccountName;
  final TZDateTime hourBeginning;
  final int locationId;
  final String locationName;
  final LocationType? locationType;
  final double? daClearedGeneration;
  final double? daClearedIncrements;
  final double? daClearedImports;
  final double? daGenerationObligation;
  final double? daClearedDemandBids;
  final double? daClearedDecrements;
  final double? daClearedExports;
  final double? daLoadObligation;
  final double? daInternalBilateralForPurchases;
  final double? daInternalBilateralForSales;
  final double? daAdjustedLoadObligation;
  final double? daAdjustedNetInterchange;
  final double? daEnergyComponent;
  final double? daCongestionComponent;
  final double? daMarginalLossComponent;
  final double? daEnergyChargeOrCredit;
  final double? daCongestionChargeOrCredit;
  final double? daMarginalLossChargeOrCredit;
  final double? daClearedAssetRelatedDemandBids;
  final double? daLoadObligationForChargeAllocation;
  final double? daDemandReduction;
  final double? daDemandReductionObligation;
  final double? daClearedSoderaLoad;
  final double? daClearedSoderaGeneration;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      reportDate: Date.parse(json['report_date'] as String),
      version: DateTime.parse(json['version'] as String),
      accountId: json['account_id'] as int,
      subaccountId: json['subaccount_id'] as int?,
      subaccountName: json['subaccount_name'] as String?,
      hourBeginning: TZDateTime.parse(
        getLocation('America/New_York'),
        json['hour_beginning'] as String,
      ),
      locationId: json['location_id'] as int,
      locationName: json['location_name'] as String,
      locationType: json['location_type'] == null
          ? null
          : LocationType.parse(json['location_type'] as String),
      daClearedGeneration: json['da_cleared_generation'] as double?,
      daClearedIncrements: json['da_cleared_increments'] as double?,
      daClearedImports: json['da_cleared_imports'] as double?,
      daGenerationObligation: json['da_generation_obligation'] as double?,
      daClearedDemandBids: json['da_cleared_demand_bids'] as double?,
      daClearedDecrements: json['da_cleared_decrements'] as double?,
      daClearedExports: json['da_cleared_exports'] as double?,
      daLoadObligation: json['da_load_obligation'] as double?,
      daInternalBilateralForPurchases:
          json['da_internal_bilateral_for_purchases'] as double?,
      daInternalBilateralForSales:
          json['da_internal_bilateral_for_sales'] as double?,
      daAdjustedLoadObligation: json['da_adjusted_load_obligation'] as double?,
      daAdjustedNetInterchange: json['da_adjusted_net_interchange'] as double?,
      daEnergyComponent: json['da_energy_component'] as double?,
      daCongestionComponent: json['da_congestion_component'] as double?,
      daMarginalLossComponent: json['da_marginal_loss_component'] as double?,
      daEnergyChargeOrCredit: json['da_energy_charge_or_credit'] as double?,
      daCongestionChargeOrCredit:
          json['da_congestion_charge_or_credit'] as double?,
      daMarginalLossChargeOrCredit:
          json['da_marginal_loss_charge_or_credit'] as double?,
      daClearedAssetRelatedDemandBids:
          json['da_cleared_asset_related_demand_bids'] as double?,
      daLoadObligationForChargeAllocation:
          json['da_load_obligation_for_charge_allocation'] as double?,
      daDemandReduction: json['da_demand_reduction'] as double?,
      daDemandReductionObligation:
          json['da_demand_reduction_obligation'] as double?,
      daClearedSoderaLoad: json['da_cleared_sodera_load'] as double?,
      daClearedSoderaGeneration:
          json['da_cleared_sodera_generation'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_date': reportDate.toIso8601String(),
      'version': version.toIso8601String(),
      'account_id': accountId,
      'subaccount_id': subaccountId,
      'subaccount_name': subaccountName,
      'hour_beginning': hourBeginning.toIso8601String(),
      'location_id': locationId,
      'location_name': locationName,
      'location_type': locationType?.toString(),
      'da_cleared_generation': daClearedGeneration,
      'da_cleared_increments': daClearedIncrements,
      'da_cleared_imports': daClearedImports,
      'da_generation_obligation': daGenerationObligation,
      'da_cleared_demand_bids': daClearedDemandBids,
      'da_cleared_decrements': daClearedDecrements,
      'da_cleared_exports': daClearedExports,
      'da_load_obligation': daLoadObligation,
      'da_internal_bilateral_for_purchases': daInternalBilateralForPurchases,
      'da_internal_bilateral_for_sales': daInternalBilateralForSales,
      'da_adjusted_load_obligation': daAdjustedLoadObligation,
      'da_adjusted_net_interchange': daAdjustedNetInterchange,
      'da_energy_component': daEnergyComponent,
      'da_congestion_component': daCongestionComponent,
      'da_marginal_loss_component': daMarginalLossComponent,
      'da_energy_charge_or_credit': daEnergyChargeOrCredit,
      'da_congestion_charge_or_credit': daCongestionChargeOrCredit,
      'da_marginal_loss_charge_or_credit': daMarginalLossChargeOrCredit,
      'da_cleared_asset_related_demand_bids': daClearedAssetRelatedDemandBids,
      'da_load_obligation_for_charge_allocation':
          daLoadObligationForChargeAllocation,
      'da_demand_reduction': daDemandReduction,
      'da_demand_reduction_obligation': daDemandReductionObligation,
      'da_cleared_sodera_load': daClearedSoderaLoad,
      'da_cleared_sodera_generation': daClearedSoderaGeneration,
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
        other.reportDate == reportDate &&
        other.version == version &&
        other.accountId == accountId &&
        other.subaccountId == subaccountId &&
        other.subaccountName == subaccountName &&
        other.hourBeginning == hourBeginning &&
        other.locationId == locationId &&
        other.locationName == locationName &&
        other.locationType == locationType &&
        other.daClearedGeneration == daClearedGeneration &&
        other.daClearedIncrements == daClearedIncrements &&
        other.daClearedImports == daClearedImports &&
        other.daGenerationObligation == daGenerationObligation &&
        other.daClearedDemandBids == daClearedDemandBids &&
        other.daClearedDecrements == daClearedDecrements &&
        other.daClearedExports == daClearedExports &&
        other.daLoadObligation == daLoadObligation &&
        other.daInternalBilateralForPurchases ==
            daInternalBilateralForPurchases &&
        other.daInternalBilateralForSales == daInternalBilateralForSales &&
        other.daAdjustedLoadObligation == daAdjustedLoadObligation &&
        other.daAdjustedNetInterchange == daAdjustedNetInterchange &&
        other.daEnergyComponent == daEnergyComponent &&
        other.daCongestionComponent == daCongestionComponent &&
        other.daMarginalLossComponent == daMarginalLossComponent &&
        other.daEnergyChargeOrCredit == daEnergyChargeOrCredit &&
        other.daCongestionChargeOrCredit == daCongestionChargeOrCredit &&
        other.daMarginalLossChargeOrCredit == daMarginalLossChargeOrCredit &&
        other.daClearedAssetRelatedDemandBids ==
            daClearedAssetRelatedDemandBids &&
        other.daLoadObligationForChargeAllocation ==
            daLoadObligationForChargeAllocation &&
        other.daDemandReduction == daDemandReduction &&
        other.daDemandReductionObligation == daDemandReductionObligation &&
        other.daClearedSoderaLoad == daClearedSoderaLoad &&
        other.daClearedSoderaGeneration == daClearedSoderaGeneration &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      reportDate,
      version,
      accountId,
      subaccountId,
      subaccountName,
      hourBeginning,
      locationId,
      locationName,
      locationType,
      daClearedGeneration,
      daClearedIncrements,
      daClearedImports,
      daGenerationObligation,
      daClearedDemandBids,
      daClearedDecrements,
      daClearedExports,
      daLoadObligation,
      daInternalBilateralForPurchases,
      daInternalBilateralForSales,
      daAdjustedLoadObligation,
      daAdjustedNetInterchange,
      daEnergyComponent,
      daCongestionComponent,
      daMarginalLossComponent,
      daEnergyChargeOrCredit,
      daCongestionChargeOrCredit,
      daMarginalLossChargeOrCredit,
      daClearedAssetRelatedDemandBids,
      daLoadObligationForChargeAllocation,
      daDemandReduction,
      daDemandReductionObligation,
      daClearedSoderaLoad,
      daClearedSoderaGeneration,
    ]);
  }
}

enum LocationType {
  drrAGGREGATIONZONE,
  hub,
  loadZONE,
  networkNODE;

  static LocationType parse(String value) {
    return switch (value.toLowerCase()) {
      'drr aggregation zone' => LocationType.drrAGGREGATIONZONE,
      'hub' => LocationType.hub,
      'load zone' => LocationType.loadZONE,
      'network node' => LocationType.networkNODE,
      _ => throw ArgumentError("Invalid value for LocationType: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      LocationType.drrAGGREGATIONZONE => 'DRR AGGREGATION ZONE',
      LocationType.hub => 'HUB',
      LocationType.loadZONE => 'LOAD ZONE',
      LocationType.networkNODE => 'NETWORK NODE',
    };
  }
}

class QueryFilter {
  QueryFilter({
    this.reportDate,
    this.reportDateIn,
    this.reportDateGte,
    this.reportDateLte,
    this.accountId,
    this.accountIdIn,
    this.accountIdGte,
    this.accountIdLte,
    this.subaccountId,
    this.subaccountIdIn,
    this.subaccountIdGte,
    this.subaccountIdLte,
  });

  Date? reportDate;
  List<Date>? reportDateIn;
  Date? reportDateGte;
  Date? reportDateLte;
  int? accountId;
  List<int>? accountIdIn;
  int? accountIdGte;
  int? accountIdLte;
  int? subaccountId;
  List<int>? subaccountIdIn;
  int? subaccountIdGte;
  int? subaccountIdLte;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (reportDate != null) {
      params['report_date'] = reportDate!.toIso8601String();
    }
    if (reportDateIn != null) {
      params['report_date_in'] = reportDateIn!
          .map((e) => e.toIso8601String())
          .join(',');
    }
    if (reportDateGte != null) {
      params['report_date_gte'] = reportDateGte!.toIso8601String();
    }
    if (reportDateLte != null) {
      params['report_date_lte'] = reportDateLte!.toIso8601String();
    }
    if (accountId != null) {
      params['account_id'] = accountId.toString();
    }
    if (accountIdIn != null) {
      params['account_id_in'] = accountIdIn!.map((e) => e.toString()).join(',');
    }
    if (accountIdGte != null) {
      params['account_id_gte'] = accountIdGte.toString();
    }
    if (accountIdLte != null) {
      params['account_id_lte'] = accountIdLte.toString();
    }
    if (subaccountId != null) {
      params['subaccount_id'] = subaccountId.toString();
    }
    if (subaccountIdIn != null) {
      params['subaccount_id_in'] = subaccountIdIn!
          .map((e) => e.toString())
          .join(',');
    }
    if (subaccountIdGte != null) {
      params['subaccount_id_gte'] = subaccountIdGte.toString();
    }
    if (subaccountIdLte != null) {
      params['subaccount_id_lte'] = subaccountIdLte.toString();
    }
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  reportDate: $reportDate');
    buffer.writeln('  reportDateIn: $reportDateIn');
    buffer.writeln('  reportDateGte: $reportDateGte');
    buffer.writeln('  reportDateLte: $reportDateLte');
    buffer.writeln('  accountId: $accountId');
    buffer.writeln('  accountIdIn: $accountIdIn');
    buffer.writeln('  accountIdGte: $accountIdGte');
    buffer.writeln('  accountIdLte: $accountIdLte');
    buffer.writeln('  subaccountId: $subaccountId');
    buffer.writeln('  subaccountIdIn: $subaccountIdIn');
    buffer.writeln('  subaccountIdGte: $subaccountIdGte');
    buffer.writeln('  subaccountIdLte: $subaccountIdLte');
    return buffer.toString();
  }
}
