import 'package:reduct/reduct.dart';
import 'package:timezone/data/latest.dart';

void generateCode() {
  final sql = '''
CREATE TABLE IF NOT EXISTS ttc_limits (
    hour_beginning TIMESTAMPTZ NOT NULL,
    interface_name VARCHAR NOT NULL,
    flow_direction ENUM('import', 'export') NOT NULL,
    flow int64 NOT NULL,
);
''';
  final generator = CodeGenerator(
    sql,
    timezoneName: 'America/New_York',
    apiRoute: '/isone/ttc',
  );
  print(generator.generateCode(Language.rust));
  print(generator.generateHtmlDocs());
  print(generator.generateCode(Language.dart));
}

Future<void> main() async {
  initializeTimeZones();
  generateCode();


  // dotenv.load('.env/prod.env');
  // DbProd();
  // await tests(dotenv.env['ROOT_URL']!);

}
