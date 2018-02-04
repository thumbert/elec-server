library elec.iso_timestamp;

import 'package:date/date.dart';
import 'package:timezone/standalone.dart';

Location _eastern = getLocation('US/Eastern');


/// Convert from an ISONE string tuple.
/// [localDate] is a String in format 'mm/dd/yyyy'
/// [hourEnding] is of the form '01', '02', '02X', '03', ... '24'
/// Return an hour beginning UTC DateTime
TZDateTime parseHourEndingStamp(String localDate, String hourEnding) {
  // the result is an hour beginning
  TZDateTime res = new TZDateTime(
      _eastern,
      int.parse(localDate.substring(6, 10)),
      int.parse(localDate.substring(0, 2)),
      int.parse(localDate.substring(3, 5)),
      int.parse(hourEnding.substring(0, 2)) - 1).toUtc();

  if (hourEnding == '02X') {
    // you are at a transition point
    res = res.add(new Duration(hours: 1));
  }

  return res;
}

/// When you read the reports with csv, the hour ending is an integer.
/// Fix it with this function.
String stringHourEnding(dynamic hourEnding) {
  if (hourEnding is int) {
    hourEnding = hourEnding.toString().padLeft(2,'0');
  }
  return hourEnding;
}


/// Convert this date to the ISONE preferred date format, e.g. 11/26/2016.
String mmddyyyy(Date date) {
  String mm = date.month.toString().padLeft(2,'0');
  String dd = date.day.toString().padLeft(2,'0');
  return '$mm/$dd/${date.year}';
}