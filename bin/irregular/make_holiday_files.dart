import 'dart:io';

import 'package:date/date.dart';
import 'package:elec/time.dart';
import 'package:table/table_base.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

///
void makeNercHolidays() {
  final years = List.generate(36, (i) => 2002 + i);
  var data = <Map<String, dynamic>>[];
  final calendar = Calendar.nerc;
  for (var year in years) {
    final term = Term.parse('Cal $year', UTC);
    final days = term.days();
    for (var day in days) {
      if (calendar.isHoliday(day)) {
        data.add({'date': day.toString()});
      }
    }
  }
  final file = File(
      '${Platform.environment['HOME']}/Downloads/Archive/Calendars/nerc_holidays.csv');
  final tbl = Table.from(data);
  file.writeAsStringSync(tbl.toCsv());
}

void main() {
  initializeTimeZones();
  makeNercHolidays();
}
