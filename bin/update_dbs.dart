import 'dart:io';

import 'package:args/args.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_dispatch_lost_opportunity_cost_report.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_economic_report.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_generator_performance_audit_report.dart';
import 'package:elec_server/src/db/isoexpress/ncpc_lscpr_report.dart';
import 'package:elec_server/src/db/lib_update_dbs.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/src/db/isoexpress/ncpc_rapid_response_pricing_report.dart';


void main(List<String> args) async {
  var parser = ArgParser()
    ..addOption('env', defaultsTo: 'prod', allowed: ['prod', 'test'])
    ..addFlag('help', abbr: 'h');

  var results = parser.parse(args);
  if (results['help']) {
    print('''
Value the weather instruments as of a given date and sends an email.  
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
  var days = Month.utc(2018, 1).days();

  await updateDailyArchive(NcpcEconomicReportArchive(), days);
  await updateDailyArchive(NcpcLscprReportArchive(), days);
  await updateDailyArchive(NcpcDlocReportArchive(), days);
  await updateDailyArchive(NcpcGpaReportArchive(), days);
  await updateDailyArchive(NcpcRapidResponsePricingReportArchive(), days);
}
