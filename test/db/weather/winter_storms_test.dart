library test.db.weather.winter_storms_test;

import 'package:timezone/timezone.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:elec_server/elec-server.dart';
import 'package:elec_server/src/db/weather/winter_storms.dart';

winterStormTests() async {
  var archive = new WinterStormsArchive();

  await archive.setupDb();

  await archive.dbConfig.db.open();
  await archive.updateDb();
  await archive.dbConfig.db.close();

}


main() async {
  await initializeTimeZone();
  await winterStormTests();
  
//  var date = '4/19/2018';
//  var time = ' 700 AM';
//  var fmt1 = new DateFormat('M/dd/yyyy');
//  print(fmt1.parse(date));
//
//  var fmt2 = new DateFormat('M/dd/yyyy h:mm a');
//  print(fmt2.parse('4/19/2018 7:00 AM'));


  //print(dt);

}

