import 'dart:io';

import 'package:args/args.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/timezone.dart';

void main(List<String> args) async {
  final logger = Logger('update isone morning report');
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  logger.info('Starting ${DateTime.now()}');
  logger.info('Pid: $pid');
  var parser = ArgParser()
    ..addOption('env', defaultsTo: 'prod', allowed: ['prod', 'test'])
    ..addFlag('help', abbr: 'h');

  var results = parser.parse(args);
  if (results['help']) {
    print('''
Archive ISONE morning report.  
Flags:
--help or -h
  Display this message. 
--env=<environment>
  Specify the environment to run.  Loads the corresponding .env file.  Supports
  'prod' and 'test' values.        
''');
    exit(0);
  }
  dotenv.load('.env/${results['env']}.env');

  initializeTimeZones();
  final location = getLocation('America/New_York');
  final now = TZDateTime.now(location);
  var month = Month(now.year, now.month, location: location);

  if (now.day < 5) {
    logger.info('running it for month ${month.previous}');
    await updateIsoneMorningReport(months: [month.previous], download: true);
  }

  await updateIsoneMorningReport(months: [month], download: true);
  logger.info('Done at ${DateTime.now().toString()}');
  exit(0);
}
