import 'dart:io';

import 'package:args/args.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timezone/timezone.dart';

void main(List<String> args) async {
  final logger = Logger('update_dbs');
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  logger.info('Starting ${DateTime.now()}');
  logger.info('Pid: $pid');

  var parser = ArgParser()
    ..addOption('env', defaultsTo: 'prod', allowed: ['prod', 'test', 'local'])
    ..addFlag('help', abbr: 'h');

  var results = parser.parse(args);
  if (results['help']) {
    print('''
Ingest MIS reports and other data into Mongo.  
Flags:
--help or -h
  Display this message. 
--env=<environment>
  Specify the environment to run.  Loads the corresponding .env file.  Supports
  'prod' and 'test' values.        
''');
    exit(0);
  }

  initializeTimeZones();
  var location = getLocation('America/New_York');
  var now = TZDateTime.now(location);

  dotenv.load('.env/${results['env']}.env');
  print('Mongo is set to: ${dotenv.env['MONGO_CONNECTION']}');
  DbProd(connection: dotenv.env['MONGO_CONNECTION']!);
  final currentMonth = Month(now.year, now.month, location: location);
  final errors = <String>[];

  /// masked data comes with a 4 months lag
  final focusMonth = currentMonth.subtract(4);
  // final focusMonth = Month(2024, 9, location: location);
  print('Focus month: $focusMonth');
  try {
    await updateIsoneMonthlyAssetNcpc(months: [focusMonth], download: true);
  } catch (e) {
    errors.add('=======================================================');
    errors.add('Failed to update monthly asset NCPC for $focusMonth');
    errors.add(e.toString());
  }

  /// DA energy offers
  try {
    await updateIsoneDaEnergyOffers(months: [focusMonth], download: true);
  } catch (e) {
    errors.add('=======================================================');
    errors.add('Failed to update ISONE DA masked energy offers $focusMonth');
    errors.add(e.toString());
  }

  /// RT energy offers
  try {
    await updateIsoneRtEnergyOffers(months: [focusMonth], download: true);
  } catch (e) {
    errors.add('=======================================================');
    errors.add('Failed to update ISONE RT masked energy offers $focusMonth');
    errors.add(e.toString());
  }

  /// demand bids
  try {
    await updateIsoneDemandBids(months: [focusMonth], download: true);
  } catch (e) {
    errors.add('=======================================================');
    errors.add('Failed to update ISONE demand bids for $focusMonth');
    errors.add(e.toString());
  }

  /// MRA bids/offers
  try {
    await updateIsoneMraCapacityBidOffer(months: [focusMonth], download: true);
  } catch (e) {
    errors.add('=======================================================');
    errors.add('Failed to update MRA bids/offers for $focusMonth');
    errors.add(e.toString());
  }

  if (errors.isNotEmpty) {
    throw StateError(errors.join('\n'));
  }

  print('Done at ${DateTime.now().toString()}');
  exit(0);
}
