// Auto-generated Dart stub for DuckDB table: emissions
// Created on 2026-05-27 with Dart package reduct

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:date/date.dart';

Future<List<String>> allFacilities({
  required String state,
  required String rootUrl,
  http.Client? client,
}) async {
  client ??= http.Client();
  final uri = Uri.parse(rootUrl).replace(
    path: '/epa/hourly_emissions/state/${state.toLowerCase()}/all_facilities',
  );
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to load records: ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.cast<String>();
}

Future<List<String>> allColumns({
  required String state,
  required String rootUrl,
  int? limit,
  http.Client? client,
}) async {
  client ??= http.Client();
  final uri = Uri.parse(rootUrl).replace(
    path: '/epa/hourly_emissions/state/${state.toLowerCase()}/all_columns',
  );
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to load records: ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.cast<String>();
}

Future<List<Map<String, dynamic>>> getData({
  required String state,
  required Term term,
  required List<String> facilityNames,
  required List<String> columns,
  required bool nonNullGenerationOnly,
  required String rootUrl,
  http.Client? client,
}) async {
  client ??= http.Client();
  final queryParams = <String,String>{
    if (facilityNames.isNotEmpty) 'facility_names': facilityNames.join('|'),
    if (columns.isNotEmpty) 'columns': columns.join('|'),
    if (nonNullGenerationOnly) 'non_null_generation_only': 'true',
  };

  final uri = Uri.parse(rootUrl).replace(
    path: '/epa/hourly_emissions/state/${state.toLowerCase()}'
      '/start/${term.startDate}/end/${term.endDate}',
    queryParameters: queryParams,
  );
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to load records: ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.cast<Map<String, dynamic>>();
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
    path: '/epa/hourly_emissions',
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
    required this.state,
    required this.facilityName,
    required this.facilityId,
    required this.unitId,
    required this.associatedStacks,
    required this.date,
    required this.hour,
    required this.operatingTime,
    required this.grossLoad,
    required this.steamLoad,
    required this.so2Mass,
    required this.so2MassMeasureIndicator,
    required this.so2Rate,
    required this.so2RateMeasureIndicator,
    required this.co2Mass,
    required this.co2MassMeasureIndicator,
    required this.co2Rate,
    required this.co2RateMeasureIndicator,
    required this.noxMass,
    required this.noxMassMeasureIndicator,
    required this.noxRate,
    required this.noxRateMeasureIndicator,
    required this.heatInput,
    required this.heatInputMeasureIndicator,
    required this.primaryFuelType,
    required this.secondaryFuelType,
    required this.unitType,
    required this.so2Controls,
    required this.noxControls,
    required this.pmControls,
    required this.hgControls,
    required this.programCode,
  });

  final String state;
  final String facilityName;
  final int facilityId;
  final String? unitId;
  final String? associatedStacks;
  final Date date;
  final int hour;
  final num? operatingTime;
  final int? grossLoad;
  final double? steamLoad;
  final num? so2Mass;
  final So2MassMeasureIndicator? so2MassMeasureIndicator;
  final num? so2Rate;
  final So2RateMeasureIndicator? so2RateMeasureIndicator;
  final num? co2Mass;
  final Co2MassMeasureIndicator? co2MassMeasureIndicator;
  final num? co2Rate;
  final Co2RateMeasureIndicator? co2RateMeasureIndicator;
  final num? noxMass;
  final NoxMassMeasureIndicator? noxMassMeasureIndicator;
  final num? noxRate;
  final NoxRateMeasureIndicator? noxRateMeasureIndicator;
  final num? heatInput;
  final HeatInputMeasureIndicator? heatInputMeasureIndicator;
  final String? primaryFuelType;
  final String? secondaryFuelType;
  final UnitType? unitType;
  final String? so2Controls;
  final String? noxControls;
  final String? pmControls;
  final String? hgControls;
  final String? programCode;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      state: json['state'] as String,
      facilityName: json['facility_name'] as String,
      facilityId: json['facility_id'] as int,
      unitId: json['unit_id'] as String?,
      associatedStacks: json['associated_stacks'] as String?,
      date: Date.parse(json['date'] as String),
      hour: json['hour'] as int,
      operatingTime: json['operating_time'] as num?,
      grossLoad: json['gross_load'] as int?,
      steamLoad: json['steam_load'] as double?,
      so2Mass: json['so2_mass'] as num?,
      so2MassMeasureIndicator: json['so2_mass_measure_indicator'] == null
          ? null
          : So2MassMeasureIndicator.parse(
              json['so2_mass_measure_indicator'] as String),
      so2Rate: json['so2_rate'] as num?,
      so2RateMeasureIndicator: json['so2_rate_measure_indicator'] == null
          ? null
          : So2RateMeasureIndicator.parse(
              json['so2_rate_measure_indicator'] as String),
      co2Mass: json['co2_mass'] as num?,
      co2MassMeasureIndicator: json['co2_mass_measure_indicator'] == null
          ? null
          : Co2MassMeasureIndicator.parse(
              json['co2_mass_measure_indicator'] as String),
      co2Rate: json['co2_rate'] as num?,
      co2RateMeasureIndicator: json['co2_rate_measure_indicator'] == null
          ? null
          : Co2RateMeasureIndicator.parse(
              json['co2_rate_measure_indicator'] as String),
      noxMass: json['nox_mass'] as num?,
      noxMassMeasureIndicator: json['nox_mass_measure_indicator'] == null
          ? null
          : NoxMassMeasureIndicator.parse(
              json['nox_mass_measure_indicator'] as String),
      noxRate: json['nox_rate'] as num?,
      noxRateMeasureIndicator: json['nox_rate_measure_indicator'] == null
          ? null
          : NoxRateMeasureIndicator.parse(
              json['nox_rate_measure_indicator'] as String),
      heatInput: json['heat_input'] as num?,
      heatInputMeasureIndicator: json['heat_input_measure_indicator'] == null
          ? null
          : HeatInputMeasureIndicator.parse(
              json['heat_input_measure_indicator'] as String),
      primaryFuelType: json['primary_fuel_type'] as String?,
      secondaryFuelType: json['secondary_fuel_type'] as String?,
      unitType: json['unit_type'] == null
          ? null
          : UnitType.parse(json['unit_type'] as String),
      so2Controls: json['so2_controls'] as String?,
      noxControls: json['nox_controls'] as String?,
      pmControls: json['pm_controls'] as String?,
      hgControls: json['hg_controls'] as String?,
      programCode: json['program_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'facility_name': facilityName,
      'facility_id': facilityId,
      'unit_id': unitId,
      'associated_stacks': associatedStacks,
      'date': date.toIso8601String(),
      'hour': hour,
      'operating_time': operatingTime,
      'gross_load': grossLoad,
      'steam_load': steamLoad,
      'so2_mass': so2Mass,
      'so2_mass_measure_indicator': so2MassMeasureIndicator?.toString(),
      'so2_rate': so2Rate,
      'so2_rate_measure_indicator': so2RateMeasureIndicator?.toString(),
      'co2_mass': co2Mass,
      'co2_mass_measure_indicator': co2MassMeasureIndicator?.toString(),
      'co2_rate': co2Rate,
      'co2_rate_measure_indicator': co2RateMeasureIndicator?.toString(),
      'nox_mass': noxMass,
      'nox_mass_measure_indicator': noxMassMeasureIndicator?.toString(),
      'nox_rate': noxRate,
      'nox_rate_measure_indicator': noxRateMeasureIndicator?.toString(),
      'heat_input': heatInput,
      'heat_input_measure_indicator': heatInputMeasureIndicator?.toString(),
      'primary_fuel_type': primaryFuelType,
      'secondary_fuel_type': secondaryFuelType,
      'unit_type': unitType?.toString(),
      'so2_controls': so2Controls,
      'nox_controls': noxControls,
      'pm_controls': pmControls,
      'hg_controls': hgControls,
      'program_code': programCode,
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
        other.state == state &&
        other.facilityName == facilityName &&
        other.facilityId == facilityId &&
        other.unitId == unitId &&
        other.associatedStacks == associatedStacks &&
        other.date == date &&
        other.hour == hour &&
        other.operatingTime == operatingTime &&
        other.grossLoad == grossLoad &&
        other.steamLoad == steamLoad &&
        other.so2Mass == so2Mass &&
        other.so2MassMeasureIndicator == so2MassMeasureIndicator &&
        other.so2Rate == so2Rate &&
        other.so2RateMeasureIndicator == so2RateMeasureIndicator &&
        other.co2Mass == co2Mass &&
        other.co2MassMeasureIndicator == co2MassMeasureIndicator &&
        other.co2Rate == co2Rate &&
        other.co2RateMeasureIndicator == co2RateMeasureIndicator &&
        other.noxMass == noxMass &&
        other.noxMassMeasureIndicator == noxMassMeasureIndicator &&
        other.noxRate == noxRate &&
        other.noxRateMeasureIndicator == noxRateMeasureIndicator &&
        other.heatInput == heatInput &&
        other.heatInputMeasureIndicator == heatInputMeasureIndicator &&
        other.primaryFuelType == primaryFuelType &&
        other.secondaryFuelType == secondaryFuelType &&
        other.unitType == unitType &&
        other.so2Controls == so2Controls &&
        other.noxControls == noxControls &&
        other.pmControls == pmControls &&
        other.hgControls == hgControls &&
        other.programCode == programCode &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      state,
      facilityName,
      facilityId,
      unitId,
      associatedStacks,
      date,
      hour,
      operatingTime,
      grossLoad,
      steamLoad,
      so2Mass,
      so2MassMeasureIndicator,
      so2Rate,
      so2RateMeasureIndicator,
      co2Mass,
      co2MassMeasureIndicator,
      co2Rate,
      co2RateMeasureIndicator,
      noxMass,
      noxMassMeasureIndicator,
      noxRate,
      noxRateMeasureIndicator,
      heatInput,
      heatInputMeasureIndicator,
      primaryFuelType,
      secondaryFuelType,
      unitType,
      so2Controls,
      noxControls,
      pmControls,
      hgControls,
      programCode,
    ]);
  }
}

enum So2MassMeasureIndicator {
  calculated,
  lme,
  measured,
  measuredAndSubstitute,
  other,
  substitute;

  static So2MassMeasureIndicator parse(String value) {
    return switch (value.toLowerCase()) {
      'calculated' => So2MassMeasureIndicator.calculated,
      'lme' => So2MassMeasureIndicator.lme,
      'measured' => So2MassMeasureIndicator.measured,
      'measured and substitute' =>
        So2MassMeasureIndicator.measuredAndSubstitute,
      'other' => So2MassMeasureIndicator.other,
      'substitute' => So2MassMeasureIndicator.substitute,
      _ => throw ArgumentError(
          "Invalid value for So2MassMeasureIndicator: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      So2MassMeasureIndicator.calculated => 'Calculated',
      So2MassMeasureIndicator.lme => 'LME',
      So2MassMeasureIndicator.measured => 'Measured',
      So2MassMeasureIndicator.measuredAndSubstitute =>
        'Measured and Substitute',
      So2MassMeasureIndicator.other => 'Other',
      So2MassMeasureIndicator.substitute => 'Substitute',
    };
  }
}

enum So2RateMeasureIndicator {
  calculated;

  static So2RateMeasureIndicator parse(String value) {
    return switch (value.toLowerCase()) {
      'calculated' => So2RateMeasureIndicator.calculated,
      _ => throw ArgumentError(
          "Invalid value for So2RateMeasureIndicator: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      So2RateMeasureIndicator.calculated => 'Calculated',
    };
  }
}

enum Co2MassMeasureIndicator {
  calculated,
  lme,
  measured,
  measuredAndSubstitute,
  other,
  substitute;

  static Co2MassMeasureIndicator parse(String value) {
    return switch (value.toLowerCase()) {
      'calculated' => Co2MassMeasureIndicator.calculated,
      'lme' => Co2MassMeasureIndicator.lme,
      'measured' => Co2MassMeasureIndicator.measured,
      'measured and substitute' =>
        Co2MassMeasureIndicator.measuredAndSubstitute,
      'other' => Co2MassMeasureIndicator.other,
      'substitute' => Co2MassMeasureIndicator.substitute,
      _ => throw ArgumentError(
          "Invalid value for Co2MassMeasureIndicator: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      Co2MassMeasureIndicator.calculated => 'Calculated',
      Co2MassMeasureIndicator.lme => 'LME',
      Co2MassMeasureIndicator.measured => 'Measured',
      Co2MassMeasureIndicator.measuredAndSubstitute =>
        'Measured and Substitute',
      Co2MassMeasureIndicator.other => 'Other',
      Co2MassMeasureIndicator.substitute => 'Substitute',
    };
  }
}

enum Co2RateMeasureIndicator {
  calculated;

  static Co2RateMeasureIndicator parse(String value) {
    return switch (value.toLowerCase()) {
      'calculated' => Co2RateMeasureIndicator.calculated,
      _ => throw ArgumentError(
          "Invalid value for Co2RateMeasureIndicator: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      Co2RateMeasureIndicator.calculated => 'Calculated',
    };
  }
}

enum NoxMassMeasureIndicator {
  calculated,
  lme,
  measured,
  measuredAndSubstitute,
  other,
  substitute;

  static NoxMassMeasureIndicator parse(String value) {
    return switch (value.toLowerCase()) {
      'calculated' => NoxMassMeasureIndicator.calculated,
      'lme' => NoxMassMeasureIndicator.lme,
      'measured' => NoxMassMeasureIndicator.measured,
      'measured and substitute' =>
        NoxMassMeasureIndicator.measuredAndSubstitute,
      'other' => NoxMassMeasureIndicator.other,
      'substitute' => NoxMassMeasureIndicator.substitute,
      _ => throw ArgumentError(
          "Invalid value for NoxMassMeasureIndicator: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      NoxMassMeasureIndicator.calculated => 'Calculated',
      NoxMassMeasureIndicator.lme => 'LME',
      NoxMassMeasureIndicator.measured => 'Measured',
      NoxMassMeasureIndicator.measuredAndSubstitute =>
        'Measured and Substitute',
      NoxMassMeasureIndicator.other => 'Other',
      NoxMassMeasureIndicator.substitute => 'Substitute',
    };
  }
}

enum NoxRateMeasureIndicator {
  calculated,
  lme,
  measured,
  measuredAndSubstitute,
  other,
  substitute;

  static NoxRateMeasureIndicator parse(String value) {
    return switch (value.toLowerCase()) {
      'calculated' => NoxRateMeasureIndicator.calculated,
      'lme' => NoxRateMeasureIndicator.lme,
      'measured' => NoxRateMeasureIndicator.measured,
      'measured and substitute' =>
        NoxRateMeasureIndicator.measuredAndSubstitute,
      'other' => NoxRateMeasureIndicator.other,
      'substitute' => NoxRateMeasureIndicator.substitute,
      _ => throw ArgumentError(
          "Invalid value for NoxRateMeasureIndicator: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      NoxRateMeasureIndicator.calculated => 'Calculated',
      NoxRateMeasureIndicator.lme => 'LME',
      NoxRateMeasureIndicator.measured => 'Measured',
      NoxRateMeasureIndicator.measuredAndSubstitute =>
        'Measured and Substitute',
      NoxRateMeasureIndicator.other => 'Other',
      NoxRateMeasureIndicator.substitute => 'Substitute',
    };
  }
}

enum HeatInputMeasureIndicator {
  calculated,
  lme,
  measured,
  measuredAndSubstitute,
  other,
  substitute;

  static HeatInputMeasureIndicator parse(String value) {
    return switch (value.toLowerCase()) {
      'calculated' => HeatInputMeasureIndicator.calculated,
      'lme' => HeatInputMeasureIndicator.lme,
      'measured' => HeatInputMeasureIndicator.measured,
      'measured and substitute' =>
        HeatInputMeasureIndicator.measuredAndSubstitute,
      'other' => HeatInputMeasureIndicator.other,
      'substitute' => HeatInputMeasureIndicator.substitute,
      _ => throw ArgumentError(
          "Invalid value for HeatInputMeasureIndicator: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      HeatInputMeasureIndicator.calculated => 'Calculated',
      HeatInputMeasureIndicator.lme => 'LME',
      HeatInputMeasureIndicator.measured => 'Measured',
      HeatInputMeasureIndicator.measuredAndSubstitute =>
        'Measured and Substitute',
      HeatInputMeasureIndicator.other => 'Other',
      HeatInputMeasureIndicator.substitute => 'Substitute',
    };
  }
}

enum UnitType {
  archFiredBoiler,
  bubblingFluidizedBedBoiler,
  cellBurnerBoiler,
  cementKiln,
  circulatingFluidizedBedBoiler,
  combinedCycle,
  combustionTurbine,
  cycloneBoiler,
  dryBottomTurboFiredBoiler,
  dryBottomVerticallyFiredBoiler,
  dryBottomWallFiredBoiler,
  integratedGasificationCombinedCycle,
  internalCombustionEngine,
  otherBoiler,
  otherTurbine,
  pressurizedFluidizedBedBoiler,
  processHeater,
  stoker,
  tangentiallyFired,
  wetBottomTurboFiredBoiler,
  wetBottomVerticallyFiredBoiler,
  wetBottomWallFiredBoiler;

  static UnitType parse(String value) {
    return switch (value.toLowerCase()) {
      'arch-fired boiler' => UnitType.archFiredBoiler,
      'bubbling fluidized bed boiler' => UnitType.bubblingFluidizedBedBoiler,
      'cell burner boiler' => UnitType.cellBurnerBoiler,
      'cement kiln' => UnitType.cementKiln,
      'circulating fluidized bed boiler' =>
        UnitType.circulatingFluidizedBedBoiler,
      'combined cycle' => UnitType.combinedCycle,
      'combustion turbine' => UnitType.combustionTurbine,
      'cyclone boiler' => UnitType.cycloneBoiler,
      'dry bottom turbo-fired boiler' => UnitType.dryBottomTurboFiredBoiler,
      'dry bottom vertically-fired boiler' =>
        UnitType.dryBottomVerticallyFiredBoiler,
      'dry bottom wall-fired boiler' => UnitType.dryBottomWallFiredBoiler,
      'integrated gasification combined cycle' =>
        UnitType.integratedGasificationCombinedCycle,
      'internal combustion engine' => UnitType.internalCombustionEngine,
      'other boiler' => UnitType.otherBoiler,
      'other turbine' => UnitType.otherTurbine,
      'pressurized fluidized bed boiler' =>
        UnitType.pressurizedFluidizedBedBoiler,
      'process heater' => UnitType.processHeater,
      'stoker' => UnitType.stoker,
      'tangentially-fired' => UnitType.tangentiallyFired,
      'wet bottom turbo-fired boiler' => UnitType.wetBottomTurboFiredBoiler,
      'wet bottom vertically-fired boiler' =>
        UnitType.wetBottomVerticallyFiredBoiler,
      'wet bottom wall-fired boiler' => UnitType.wetBottomWallFiredBoiler,
      _ => throw ArgumentError("Invalid value for UnitType: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      UnitType.archFiredBoiler => 'Arch-fired boiler',
      UnitType.bubblingFluidizedBedBoiler => 'Bubbling fluidized bed boiler',
      UnitType.cellBurnerBoiler => 'Cell burner boiler',
      UnitType.cementKiln => 'Cement Kiln',
      UnitType.circulatingFluidizedBedBoiler =>
        'Circulating fluidized bed boiler',
      UnitType.combinedCycle => 'Combined cycle',
      UnitType.combustionTurbine => 'Combustion turbine',
      UnitType.cycloneBoiler => 'Cyclone boiler',
      UnitType.dryBottomTurboFiredBoiler => 'Dry bottom turbo-fired boiler',
      UnitType.dryBottomVerticallyFiredBoiler =>
        'Dry bottom vertically-fired boiler',
      UnitType.dryBottomWallFiredBoiler => 'Dry bottom wall-fired boiler',
      UnitType.integratedGasificationCombinedCycle =>
        'Integrated gasification combined cycle',
      UnitType.internalCombustionEngine => 'Internal combustion engine',
      UnitType.otherBoiler => 'Other boiler',
      UnitType.otherTurbine => 'Other turbine',
      UnitType.pressurizedFluidizedBedBoiler =>
        'Pressurized fluidized bed boiler',
      UnitType.processHeater => 'Process Heater',
      UnitType.stoker => 'Stoker',
      UnitType.tangentiallyFired => 'Tangentially-fired',
      UnitType.wetBottomTurboFiredBoiler => 'Wet bottom turbo-fired boiler',
      UnitType.wetBottomVerticallyFiredBoiler =>
        'Wet bottom vertically-fired boiler',
      UnitType.wetBottomWallFiredBoiler => 'Wet bottom wall-fired boiler',
    };
  }
}

class QueryFilter {
  QueryFilter({
    this.state,
    this.stateLike,
    this.stateIn,
    this.facilityId,
    this.facilityIdIn,
    this.facilityIdGte,
    this.facilityIdLte,
    this.unitId,
    this.unitIdLike,
    this.unitIdIn,
    this.date,
    this.dateIn,
    this.dateGte,
    this.dateLte,
  });

  String? state;
  String? stateLike;
  List<String>? stateIn;
  int? facilityId;
  List<int>? facilityIdIn;
  int? facilityIdGte;
  int? facilityIdLte;
  String? unitId;
  String? unitIdLike;
  List<String>? unitIdIn;
  Date? date;
  List<Date>? dateIn;
  Date? dateGte;
  Date? dateLte;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (state != null) {
      params['state'] = state.toString();
    }
    if (stateLike != null) {
      params['state_like'] = stateLike.toString();
    }
    if (stateIn != null) {
      params['state_in'] = stateIn!.map((e) => e.toString()).join(',');
    }
    if (facilityId != null) {
      params['facility_id'] = facilityId.toString();
    }
    if (facilityIdIn != null) {
      params['facility_id_in'] =
          facilityIdIn!.map((e) => e.toString()).join(',');
    }
    if (facilityIdGte != null) {
      params['facility_id_gte'] = facilityIdGte.toString();
    }
    if (facilityIdLte != null) {
      params['facility_id_lte'] = facilityIdLte.toString();
    }
    if (unitId != null) {
      params['unit_id'] = unitId.toString();
    }
    if (unitIdLike != null) {
      params['unit_id_like'] = unitIdLike.toString();
    }
    if (unitIdIn != null) {
      params['unit_id_in'] = unitIdIn!.map((e) => e.toString()).join(',');
    }
    if (date != null) {
      params['date'] = date!.toIso8601String();
    }
    if (dateIn != null) {
      params['date_in'] = dateIn!.map((e) => e.toIso8601String()).join(',');
    }
    if (dateGte != null) {
      params['date_gte'] = dateGte!.toIso8601String();
    }
    if (dateLte != null) {
      params['date_lte'] = dateLte!.toIso8601String();
    }
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  state: $state');
    buffer.writeln('  stateLike: $stateLike');
    buffer.writeln('  stateIn: $stateIn');
    buffer.writeln('  facilityId: $facilityId');
    buffer.writeln('  facilityIdIn: $facilityIdIn');
    buffer.writeln('  facilityIdGte: $facilityIdGte');
    buffer.writeln('  facilityIdLte: $facilityIdLte');
    buffer.writeln('  unitId: $unitId');
    buffer.writeln('  unitIdLike: $unitIdLike');
    buffer.writeln('  unitIdIn: $unitIdIn');
    buffer.writeln('  date: $date');
    buffer.writeln('  dateIn: $dateIn');
    buffer.writeln('  dateGte: $dateGte');
    buffer.writeln('  dateLte: $dateLte');
    return buffer.toString();
  }
}
