import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';

Future<void> main() async {
  initializeTimeZones();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name} (${record.time.toString().substring(0, 19)}) ${record.message}');
  });
  dotenv.load('.env/prod.env');

  // await updateNyisoPtidTable(download: true);
  await updateNyisoPtidTable(download: false);
}
