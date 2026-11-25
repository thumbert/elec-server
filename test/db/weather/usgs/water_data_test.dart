
import 'package:date/date.dart';
import 'package:elec_server/src/db/weather/usgs/water_data.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void main() {
  initializeTimeZones();

  group('WaterDataArchive daily discharge', () {
    test(
      'requests the specified data and follows pages in date order',
      () async {
        final client = http.Client();
        final monitoringLocationId = 'USGS-01576000';
        final term = Term.parse('Jan26', UTC);
        final result = await WaterDataArchive(client).getDailyDischarge(
          monitoringLocationId: monitoringLocationId,
          term: term,
        );
        expect(result.length, 31);
        expect(result.first['time'], '2026-01-01');
        expect(result.first['value'], '20800');
      },
    );
  });
}
