import 'package:reduct/reduct.dart';
import 'package:timezone/data/latest.dart';


void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS zonal_uplift (
    day DATE NOT NULL,
    ptid VARCHAR NOT NULL,
    name VARCHAR NOT NULL,
    uplift_category VARCHAR NOT NULL,
    uplift_payment DECIMAL(18,2) NOT NULL,
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/nyiso/zonal_uplift',
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

Future<void> main() async {
  initializeTimeZones();
  generateCode();
}
