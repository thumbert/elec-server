import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';

Future<void> tests() async {
  final archive = getIsoneSevenDayCapacityForecastArchive();
  group('Seven day capacity forecast tests:', () {
    test('read file for 2024-06-17', () async {
      var file = archive.getFilename(Date.utc(2024, 6, 17));
      var data = archive.processFile(file);
      expect(data.length, 6);
    });
  });
  //
  //
}

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS capacity_forecast (
    creation_time TIMESTAMPTZ NOT NULL,
    for_day DATE NOT NULL,
    day_index UINT8 NOT NULL,
    cso_mw INT,
    cold_weather_outages_mw INT,
    other_gen_outages_mw INT,
    delist_mw INT,
    total_available_gen_mw INT,
    peak_import_mw INT,
    total_available_gen_import_mw INT,
    peak_load_mw INT,
    replacement_reserve_req_mw INT,
    required_reserve_mw INT,
    required_reserve_incl_replacement_mw INT,
    total_load_plus_required_reserve_mw INT,
    drr_mw INT,
    surplus_deficiency_mw INT,
    is_power_watch BOOLEAN,
    is_power_warn BOOLEAN, 
    is_cold_weather_watch BOOLEAN,
    is_cold_weather_warn BOOLEAN,
    is_cold_weather_event BOOLEAN,
    boston_high_temp_f INT1,
    boston_dew_point_f INT1,
    hartford_high_temp_f INT1,
    hartford_dew_point_f INT1,
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/isone/7day_capacity_forecast',
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}


Future<void> main() async {
  initializeTimeZones();
  // await tests();
  generateCode();
}
