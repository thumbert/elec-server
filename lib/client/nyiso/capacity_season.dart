// Auto-generated Dart stub for DuckDB table: capacity_seasons
// Created on 2026-07-06 with Dart package reduct

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Function to query records from the DuckDB table via REST API
/// [rootUrl] is the base URL of the API endpoint.
/// Optional [limit] can be provided to limit the number of records.
///
Future<List<Record>> queryRecords({
  required String rootUrl,
  int? limit,
  http.Client? client,
}) async {
  client ??= http.Client();
  final queryParams = <String, String>{};
  if (limit != null) {
    queryParams['_limit'] = limit.toString();
  }
  final uri = Uri.parse(rootUrl).replace(
    path: '/nyiso/capacity_seasons',
    queryParameters: queryParams,
  );
  final response = await client.get(uri);
  if (response.statusCode != 200) {
    throw Exception('Failed to load records: ${response.statusCode}');
  }
  final List<dynamic> jsonList = jsonDecode(response.body);
  return jsonList.map((json) => Record.fromJson(json)).toList();
}

///
///```dart
/// {
//   "id": 704686,
//   "description": "Winter 2025-2026"
// },
///```
///
class Record {
  Record({
    required this.id,
    required this.description,
  });

  final int id;
  final String description;

  static Record fromJson(Map<String, dynamic> json) {
    return Record(
      id: json['id'] as int,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
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
        other.id == id &&
        other.description == description &&
        true;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      description,
    ]);
  }
}
