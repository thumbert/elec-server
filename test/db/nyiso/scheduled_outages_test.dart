import 'package:reduct/reduct.dart';
import 'package:timezone/data/latest.dart';

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS scheduled_outages (
    as_of DATE NOT NULL,
    ptid INT64 NOT NULL,
    outage_id VARCHAR NOT NULL,
    equipment_name VARCHAR NOT NULL,
    equipment_type VARCHAR NOT NULL,
    outage_start_date DATE NOT NULL,
    outage_time_out TIME NOT NULL,
    outage_end_date DATE NOT NULL,
    outage_time_in TIME NOT NULL,
    called_in_by VARCHAR NOT NULL,
    status VARCHAR,
    last_update TIMESTAMP,
    message VARCHAR,
    arr INT64
);''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/nyiso/transmission_outages/scheduled',
  );
  // print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

Future<void> main() async {
  initializeTimeZones();
  generateCode();
}
