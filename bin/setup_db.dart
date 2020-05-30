import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_energy_offer.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

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

void main() async {
  await initializeTimeZones();
  var location = getLocation('US/Eastern');

  var archive = DaEnergyOfferArchive();
  /// Currently there is a bug in mongo_dart driver that doesn't allow to
  /// set the index!
//  await archive.setupDb();
  await insertDays(archive, Term.parse('Jul17', location).days());
//  await insertDays(archive, Term.parse('Apr18', location).days());



}