import 'dart:io';

import 'package:args/args.dart';
import 'package:date/date.dart';
import 'package:elec/nyiso.dart';
import 'package:elec_server/client/nyiso/capacity_season.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/timezone.dart';

final _cache = <String, int>{};

/// Get the mapping from capability period descriptions to season IDs.
/// e.g. 'Summer 2026' -> 705094
Future<void> populateCache() async {
  final client = http.Client();
  final records =
      await queryRecords(rootUrl: dotenv.env['RUST_SERVER']!, client: client);
  for (var record in records) {
    _cache[record.description] = record.id;
  }
}

int getSeasonId(CapabilityPeriod capabilityPeriod) {
  return _cache[capabilityPeriod.toString()]!;
}

void main(List<String> args) async {
  final logger = Logger('update nyiso monthly capacity auction results');
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
Archive NYISO monthly capacity auction results.  
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
  await populateCache();
  final archive = getNyisoCapacityPricesMonthlyArchive();

  // process next month (usually data available by the 15th of the month)
  final month = Month.current(location: location).next;
  final months = [month];
  for (var month in months) {
    logger.info('Month to process: ${month.toString()}');
    final capabilityPeriod = CapabilityPeriod.containing(month);
    logger.info('Capability period: ${capabilityPeriod.toString()}');
    final seasonId = getSeasonId(capabilityPeriod);
    logger.info('Season ID: $seasonId');

    final records =
        await archive.downloadPricesToCsv(seasonId: seasonId, month: month);
    if (records.isEmpty) {
      logger.warning('No prices found for month: ${month.toString()}');
    } else {
      logger.info('Downloaded prices for month: ${month.toString()}');
    }
  }

  logger.info('Done at ${DateTime.now().toString()}');
  exit(0);
}
