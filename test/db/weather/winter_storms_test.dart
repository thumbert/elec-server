library test.db.weather.winter_storms_test;

import 'package:elec_server/src/db/weather/winter_storms.dart';

winterStormTests() async {
  var archive = new WinterStormsArchive();

  await archive.setupDb();

  await archive.dbConfig.db.open();
  await archive.updateDb();
  await archive.dbConfig.db.close();

}


main() async {
  await winterStormTests();

}

