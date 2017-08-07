library test.db.isone_dam_lmp_test;

import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:date/date.dart';

import 'package:elec_server/src/db/isone_da_lmp.dart';
import 'package:elec_server/src/db/config.dart';


setupArchive(Config config) async {
  DamArchive arch = new DamArchive();
  await arch.setup();

  await arch.updateDb(new Date(2017,1,1), new Date(2017,3,30));
}

testNepoolDamArchive() async {
  DamArchive arch = new DamArchive();

  await arch.db.open();
  Date end = await arch.lastDayInserted();
  print('Last day inserted is: $end');
  await arch.removeDataForDay(end);
  print('Last day inserted is: ${await arch.lastDayInserted()}');
  await arch.db.close();
}




main() async {

  Map env = Platform.environment;

  Config config = new TestConfig();
  config.isone_dam_lmp_hourly
    ..DIR = env['HOME'] + '/Downloads/Archive/DA_LMP/Raw/Csv';
  await setupArchive(config);



//  await config.open();

//  await config.close();

  //await testNepoolDamArchive();

  //await testNepoolDam();

//  await testMonthlyLmp();
//
//  await config.close();
}