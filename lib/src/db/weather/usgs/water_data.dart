import 'dart:convert';

import 'package:date/date.dart';
import 'package:http/http.dart' as http;

class WaterDataArchive {
  WaterDataArchive(this.client);

  final http.Client client;

  /// Fetch daily mean discharge (USGS parameter 00060, statistic 00003).
  ///
  /// Dates are inclusive and use the YYYY-MM-DD format. The returned maps are
  /// the USGS feature properties, including `time`, `value`, `unit_of_measure`,
  /// and `approval_status`. Values remain strings to preserve their precision;
  /// provisional observations can be revised.
  ///
  /// Returns a list of daily discharge observations for the specified station 
  /// and date range.
  ///
  /// The `monitoringLocationId` parameter specifies the USGS station for which 
  ///    to fetch data, e.g. 'USGS-01576000' for Susquehanna River at Marietta, 
  ///    PA.
  /// 
  /// 
  /// The `term` parameter specifies the date range for which to fetch data.
  ///
  ///
  /// For the requested station and dates:
  Future<List<Map<String, dynamic>>> getDailyDischarge({
    String monitoringLocationId = 'USGS-01576000',
    required Term term,
  }) async {
    Uri? next = Uri.https(
      'api.waterdata.usgs.gov',
      '/ogcapi/v1/collections/daily/items',
      {
        'f': 'json',
        'monitoring_location_id': monitoringLocationId,
        'parameter_code': '00060',
        'statistic_id': '00003',
        'time':
            '${term.startDate.toIso8601String()}/${term.endDate.toIso8601String()}',
        'limit': '500',
      },
    );
    final visited = <Uri>{};
    final observations = <Map<String, dynamic>>[];
    while (next != null) {
      final uri = next;
      if (!visited.add(uri)) {
        throw StateError('USGS API returned a repeated next-page link: $uri');
      }
      final response = await client.get(uri);
      if (response.statusCode != 200) {
        throw http.ClientException(
          'USGS API returned HTTP ${response.statusCode}: ${response.body}',
          uri,
        );
      }
      final page = jsonDecode(response.body) as Map<String, dynamic>;
      for (final feature in page['features'] as List<dynamic>) {
        observations.add(
          Map<String, dynamic>.from(
            (feature as Map<String, dynamic>)['properties'] as Map,
          ),
        );
      }
      next = null;
      for (final link in page['links'] as List<dynamic>) {
        final item = link as Map<String, dynamic>;
        if (item['rel'] == 'next') {
          next = uri.resolve(item['href'] as String);
          break;
        }
      }
    }
    observations.sort(
      (a, b) => (a['time'] as String).compareTo(b['time'] as String),
    );
    return observations;
  }
}
