library test.db.isoexpress.zonal_demand_test;

import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/zonal_demand.dart';
import '../../../bin/setup_db.dart';

void tests() async {

}


void main() async {
  initializeTimeZones();

  /// recreate the database (3 min)
  await insertZonalDemand();

}