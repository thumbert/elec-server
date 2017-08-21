library test.db.isone_dam_lmp_test;

import 'dart:io';
import 'dart:async';
import 'package:test/test.dart';
import 'package:date/date.dart';

import 'package:elec_server/src/db/isone_da_lmp.dart';
import 'package:elec_server/src/db/config.dart';


downloadPrices() async {
  Date start = new Date(2016,1,1);
  Date end = new Date(2016,12,31);
  DamArchive arch = new DamArchive();

  var days = new TimeIterable(start, end).toList();
  for (var day in days) {
    await arch.oneDayDownload(day);
  }
}

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

//  Map env = Platform.environment;
//  Config config = new TestConfig();
//  config.isone_dam_lmp_hourly
//    ..DIR = env['HOME'] + '/Downloads/Archive/DA_LMP/Raw/Csv';
//  await setupArchive(config);

  downloadPrices();


//  await config.open();

//  await config.close();

  //await testNepoolDamArchive();

  //await testNepoolDam();

//  await testMonthlyLmp();
//
//  await config.close();
}