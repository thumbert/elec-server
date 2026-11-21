import 'dart:io';

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/timezone.dart';

/// This job is not set to run automatically. 
void main(List<String> args) async {
  final logger = Logger('update nyiso masked energy offers');
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  logger.info('Starting ${DateTime.now()}');
  logger.info('Pid: $pid');
  dotenv.load('.env/prod.env');

  initializeTimeZones();
  final location = getLocation('America/New_York');
  final months = [Month.current(location: location).subtract(4)];
  await updateNyisoEnergyOffers(months: months, download: true);

  logger.info('Done at ${DateTime.now().toString()}');
  exit(0);
}
