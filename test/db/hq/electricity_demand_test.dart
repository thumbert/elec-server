import 'package:reduct/reduct.dart';
import 'package:timezone/data/latest.dart';


void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS total_demand (
    start_15min TIMESTAMPTZ NOT NULL,
    value DECIMAL(9,2) NOT NULL,
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/hq/total_demand',
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}


Future<void> main() async {
  initializeTimeZones();
  generateCode();

}
