import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:elec_server/src/db/marks/curves/forward_marks.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';
import '../test/db/marks/marks_special_days.dart';

/// Create the MongoDb from scratch to pass all tests.  This script is useful
/// if you update the MongoDb installation and all the data is erased.
///


void insertDays(archive, List<Date> days) async {
  await archive.dbConfig.db.open();
  for (var day in days) {
    print('Working on $day');
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

void insertForwardMarks() async {
  var archive = ForwardMarksArchive();
  await archive.db.open();
  var data = marks20200529();
  await archive.insertData(data);
  await archive.db.close();
}


void insertIsoExpress() async {
  var location = getLocation('US/Eastern');
  var archive = DaEnergyOfferArchive();
  await insertDays(archive, Term.parse('Jul17', location).days());
}


void main() async {
  await initializeTimeZones();

//  await insertIsoExpress();
  await insertForwardMarks();
}