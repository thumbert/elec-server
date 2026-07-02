import 'dart:io';

import 'package:args/args.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/timezone.dart';

/// Run this every month on the 28th or so.
void main(List<String> args) async {
  final logger = Logger('update isone mra results');
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  logger.info('Starting ${DateTime.now()}');
  logger.info('Pid: $pid');
  var parser = ArgParser()
    ..addOption('env', defaultsTo: 'prod', allowed: ['prod', 'test'])
    ..addOption('month',
        abbr: 'm',
        help:
            'Month to process in yyyy-mm format, e.g. 2025-06.  Defaults to next month.')
    ..addFlag('help', abbr: 'h');

  var results = parser.parse(args);
  if (results['help']) {
    print('''
Archive ISONE MRA results.  
Flags:
--help or -h
  Display this message. 
--env=<environment>
  Specify the environment to run.  Loads the corresponding .env file.  Supports
  'prod' and 'test' values.
--month or -m
  Month to process in yyyy-mm format, e.g. 2025-06.  Defaults to two months ahead.        
''');
    exit(0);
  }
  dotenv.load('.env/${results['env']}.env');

  initializeTimeZones();
  final location = getLocation('America/New_York');
  final List<Month> months;
  if (results['month'] != null) {
    months = [Month.parse(results['month'], location: location)];
  } else {
    final now = TZDateTime.now(location);
    months = [Month(now.year, now.month, location: location).next.next];
  }

  await updateIsoneMraCapacityResults(months: months, download: true);
  logger.info('Done at ${DateTime.now().toString()}');
  exit(0);
}
