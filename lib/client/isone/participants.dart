// Auto-generated Dart stub for DuckDB table: participants
// Created on 2026-07-05 with Dart package reduct

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:date/date.dart';

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
    path: '/isone/participant_list',
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
  Record({required this.asOf, required this.id, required this.customerName, required this.address1, required this.address2, required this.address3, required this.city, required this.state, required this.zip, required this.country, required this.phone, required this.status, required this.sector, required this.participantType, required this.classification, required this.subClassification, required this.hasVotingRights, required this.terminationDate, });

  final Date asOf;
  final int id;
  final String customerName;
  final String? address1;
  final String? address2;
  final String? address3;
  final String? city;
  final String? state;
  final String? zip;
  final String? country;
  final String? phone;
  final Status status;
  final Sector sector;
  final ParticipantType participantType;
  final Classification classification;
  final String? subClassification;
  final bool? hasVotingRights;
  final Date? terminationDate;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      asOf: Date.parse(json['as_of'] as String),
      id: json['id'] as int,
      customerName: json['customer_name'] as String,
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      address3: json['address3'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zip: json['zip'] as String?,
      country: json['country'] as String?,
      phone: json['phone'] as String?,
      status: Status.parse(json['status'] as String),
      sector: Sector.parse(json['sector'] as String),
      participantType: ParticipantType.parse(json['participant_type'] as String),
      classification: Classification.parse(json['classification'] as String),
      subClassification: json['sub_classification'] as String?,
      hasVotingRights: json['has_voting_rights'] as bool?,
      terminationDate: json['termination_date'] == null ? null : Date.parse(json['termination_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'as_of': asOf.toIso8601String(),
      'id': id,
      'customer_name': customerName,
      'address1': address1,
      'address2': address2,
      'address3': address3,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
      'phone': phone,
      'status': status.toString(),
      'sector': sector.toString(),
      'participant_type': participantType.toString(),
      'classification': classification.toString(),
      'sub_classification': subClassification,
      'has_voting_rights': hasVotingRights,
      'termination_date': terminationDate?.toIso8601String(),
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
        other.asOf == asOf &&
        other.id == id &&
        other.customerName == customerName &&
        other.address1 == address1 &&
        other.address2 == address2 &&
        other.address3 == address3 &&
        other.city == city &&
        other.state == state &&
        other.zip == zip &&
        other.country == country &&
        other.phone == phone &&
        other.status == status &&
        other.sector == sector &&
        other.participantType == participantType &&
        other.classification == classification &&
        other.subClassification == subClassification &&
        other.hasVotingRights == hasVotingRights &&
        other.terminationDate == terminationDate &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      asOf,
      id,
      customerName,
      address1,
      address2,
      address3,
      city,
      state,
      zip,
      country,
      phone,
      status,
      sector,
      participantType,
      classification,
      subClassification,
      hasVotingRights,
      terminationDate,
    ]);
  }
}

enum Status {
    active,
    suspended;

  static Status parse(String value) {
    return switch (value.toLowerCase()) {
      'active' => Status.active,
      'suspended' => Status.suspended,
      _ => throw ArgumentError("Invalid value for Status: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      Status.active => 'ACTIVE',
      Status.suspended => 'SUSPENDED',
    };
  }
}

enum Sector {
    alternativeResources,
    endUser,
    generation,
    marketParticipant,
    notApplicable,
    publiclyOwnedEntity,
    supplier,
    transmission;

  static Sector parse(String value) {
    return switch (value.toLowerCase()) {
      'alternative resources' => Sector.alternativeResources,
      'end user' => Sector.endUser,
      'generation' => Sector.generation,
      'market participant' => Sector.marketParticipant,
      'not applicable' => Sector.notApplicable,
      'publicly-owned entity' => Sector.publiclyOwnedEntity,
      'supplier' => Sector.supplier,
      'transmission' => Sector.transmission,
      _ => throw ArgumentError("Invalid value for Sector: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      Sector.alternativeResources => 'Alternative Resources',
      Sector.endUser => 'End User',
      Sector.generation => 'Generation',
      Sector.marketParticipant => 'Market Participant',
      Sector.notApplicable => 'Not applicable',
      Sector.publiclyOwnedEntity => 'Publicly-Owned Entity',
      Sector.supplier => 'Supplier',
      Sector.transmission => 'Transmission',
    };
  }
}

enum ParticipantType {
    nonParticipant,
    participant,
    poolOperator;

  static ParticipantType parse(String value) {
    return switch (value.toLowerCase()) {
      'non-participant' => ParticipantType.nonParticipant,
      'participant' => ParticipantType.participant,
      'pool operator' => ParticipantType.poolOperator,
      _ => throw ArgumentError("Invalid value for ParticipantType: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      ParticipantType.nonParticipant => 'Non-Participant',
      ParticipantType.participant => 'Participant',
      ParticipantType.poolOperator => 'Pool Operator',
    };
  }
}

enum Classification {
    governanceOnly,
    groupMember,
    localControlCenter,
    marketParticipant,
    other,
    publicUtilityCommission,
    transmissionOnly;

  static Classification parse(String value) {
    return switch (value.toLowerCase()) {
      'governance only' => Classification.governanceOnly,
      'group member' => Classification.groupMember,
      'local control center' => Classification.localControlCenter,
      'market participant' => Classification.marketParticipant,
      'other' => Classification.other,
      'public utility commission' => Classification.publicUtilityCommission,
      'transmission only' => Classification.transmissionOnly,
      _ => throw ArgumentError("Invalid value for Classification: $value"),
    };
  }

  @override
  String toString() {
    return switch (this) {
      Classification.governanceOnly => 'Governance Only',
      Classification.groupMember => 'Group Member',
      Classification.localControlCenter => 'Local Control Center',
      Classification.marketParticipant => 'Market Participant',
      Classification.other => 'Other',
      Classification.publicUtilityCommission => 'Public Utility Commission',
      Classification.transmissionOnly => 'Transmission Only',
    };
  }
}

class QueryFilter {
  QueryFilter({this.status, this.statusIn, });

  Status? status;
  List<Status>? statusIn;

  Map<String, String> toUriParams() {
    final params = <String, String>{};
    if (status != null) { params['status'] = status.toString();}
    if (statusIn != null) { params['status_in'] = statusIn!.map((e) => e.toString()).join(',');}
    return params;
  }

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.writeln('QueryFilter:');
    buffer.writeln('  status: $status');
    buffer.writeln('  statusIn: $statusIn');
    return buffer.toString();
  }
}
