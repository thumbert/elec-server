import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/da_lmp_hourly.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> insertDays(DailyIsoExpressReport archive, List<Date> days) async {
  await archive.dbConfig.db.open();
  for (var day in days) {
    print('Working on $day');
    await archive.downloadDay(day);
    await archive.insertDay(day);
  }
  await archive.dbConfig.db.close();
}

Future<void> tests() async {
  var location = getLocation('America/New_York');

  var days = Date.today(location: location).next.previousN(4);
  // var days = Term.parse('Mar21-Jul21', UTC).days();
  await insertDays(DaLmpHourlyArchive(), days);


}

void main() async {
  initializeTimeZones();

  ///
  /// See bin/setup_db.dart on how to update a database
  ///

  await tests();
}
