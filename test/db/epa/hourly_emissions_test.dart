import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/epa/hourly_emissions.dart';
import 'package:reduct/reduct.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  group('EPA Emissions API', () {
    test('Get all the facilities for one state', () async {
      final res =
          await allFacilities(state: 'MA', rootUrl: dotenv.env['RUST_SERVER']!);
      expect(res.contains('Mystic'), isTrue);
      // res.forEach(print);
    });
    test('Get all the available columns for one state', () async {
      final res =
          await allColumns(state: 'MA', rootUrl: dotenv.env['RUST_SERVER']!);
      expect(res.contains('gross_load'), isTrue);
    });
    test('Get some data for a specific term and facilities', () async {
      final term = Term.parse('Jan25', UTC);
      final res = await getData(
        state: 'MA',
        term: term,
        facilityNames: ['Fore River Energy Center'],
        columns: ['date', 'hour', 'unit_id', 'gross_load'],
        nonNullGenerationOnly: true,
        rootUrl: dotenv.env['RUST_SERVER']!,
      );
      expect(res.isNotEmpty, isTrue);
    });
  });
}

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS emissions (
    state VARCHAR(2) NOT NULL,
    facility_name VARCHAR NOT NULL,
    facility_id UINTEGER NOT NULL,
    unit_id VARCHAR,
    associated_stacks VARCHAR,
    date DATE NOT NULL,
    hour UTINYINT NOT NULL,
    -- Fraction of the hour that the unit was operating, from 0 to 1.
    operating_time DECIMAL(3, 2),
    gross_load USMALLINT,
    steam_load FLOAT,
    so2_mass DECIMAL(9, 4),
    so2_mass_measure_indicator ENUM(
        'Calculated',
        'Measured',
        'Substitute',
        'Measured and Substitute',
        'LME', 
        'Other'
    ),
    so2_rate DECIMAL(9, 4),
    so2_rate_measure_indicator ENUM('Calculated'),
    co2_mass DECIMAL(9, 5),
    co2_mass_measure_indicator ENUM(
        'Calculated',
        'Measured',
        'Substitute',
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    co2_rate DECIMAL(9, 6),
    co2_rate_measure_indicator ENUM('Calculated'),
    nox_mass DECIMAL(9, 4),
    nox_mass_measure_indicator ENUM(
        'Calculated', 
        'Measured', 
        'Substitute', 
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    nox_rate DECIMAL(9, 6),
    nox_rate_measure_indicator ENUM(
        'Measured',
        'Substitute',
        'Calculated',
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    heat_input DECIMAL(9, 4),
    heat_input_measure_indicator ENUM(
        'Measured',
        'Substitute',
        'Calculated',
        'Measured and Substitute',
        'LME',
        'Other'
    ),
    primary_fuel_type VARCHAR,
    secondary_fuel_type VARCHAR,
    unit_type ENUM(
        'Arch-fired boiler',
        'Bubbling fluidized bed boiler',
        'Cyclone boiler',
        'Cell burner boiler',
        'Combined cycle',
        'Circulating fluidized bed boiler',
        'Combustion turbine',
        'Dry bottom wall-fired boiler',
        'Dry bottom turbo-fired boiler',
        'Dry bottom vertically-fired boiler',
        'Internal combustion engine',
        'Integrated gasification combined cycle',
        'Cement Kiln',
        'Other boiler',
        'Other turbine',
        'Pressurized fluidized bed boiler',
        'Process Heater',
        'Stoker',
        'Tangentially-fired',
        'Wet bottom wall-fired boiler',
        'Wet bottom turbo-fired boiler',
        'Wet bottom vertically-fired boiler',
    ),
    so2_controls VARCHAR,
    nox_controls VARCHAR,
    pm_controls VARCHAR,
    hg_controls VARCHAR,
    program_code VARCHAR,
);''';
  final generator = CodeGenerator(
    sql,
    apiRoute: '/epa/hourly_emissions',
    requiredFilters: ['state', 'facility_id'],
    onlyFilters: ['state', 'facility_id', 'unit_id', 'date'],
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

Future<void> main() async {
  initializeTimeZones();
  // generateCode();

  dotenv.load('.env/prod.env');
  await tests(dotenv.env['ROOT_URL']!);
}
