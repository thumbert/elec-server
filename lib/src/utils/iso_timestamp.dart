library elec.iso_timestamp;

import 'package:date/date.dart';
import 'package:timezone/standalone.dart';

Location _eastern = getLocation('US/Eastern');

/// Convert from an ISONE string tuple.
/// [localDate] is a String in format 'mm/dd/yyyy'
/// [hourEnding] is of the form '01', '02', '02X', '03', ... '24'
/// Return an hour beginning US/Eastern DateTime
TZDateTime parseHourEndingStamp(String localDate, String hourEnding) {
  TZDateTime res = new TZDateTime(
          _eastern,
          int.parse(localDate.substring(6, 10)),
          int.parse(localDate.substring(0, 2)),
          int.parse(localDate.substring(3, 5)),
          int.parse(hourEnding.substring(0, 2)) - 1)
      .toUtc();

  if (hourEnding == '02X') {
    // you are at a transition point
    res = res.add(new Duration(hours: 1));
  }

  return res;
}

/// Convert an hour beginning timestamp to the ISO hour ending format.
/// The [hourBeginning] timestamp needs to be in the eastern time zone.
/// Return a two element list with the date and hour ending.
/// E.g. ['2018-02-01', '03'], ['2018-02-11', '24'].
List<String> toIsoHourEndingStamp(TZDateTime hourBeginning) {
  Hour hour = new Hour.beginning(hourBeginning);
  int offsetStart = hour.start.timeZoneOffset.inHours;
  bool isFallBack = isFallBackDate(new Date(
      hourBeginning.year, hourBeginning.month, hourBeginning.day));
  List res = [hour.start.toString().substring(0,10)];

  if (hourBeginning.hour == 23)
    res.add('24');
  else {
    if (isFallBack) {
      if (hour.start.hour == 0) res.add('01');
      else if (hour.start.hour == 1 && offsetStart == -4) res.add('02');
      else if (hour.start.hour == 1 && offsetStart == -5) res.add('02X');
      else res.add(hour.end.hour.toString().padLeft(2, '0'));
    } else {
      res.add(hour.end.hour.toString().padLeft(2, '0'));
    }
  }

  return res;
}

/// Check if this date is a fall back date.  Return true if it is.
bool isFallBackDate(Date date) {
  int offsetStart = new TZDateTime(_eastern, date.year, date.month, date.day)
      .timeZoneOffset
      .inHours;
  int offsetEnd = new TZDateTime(_eastern, date.year, date.month, date.day, 23)
      .timeZoneOffset
      .inHours;
  bool res = false;
  if (offsetStart == -4 && offsetEnd == -5) res = true;
  return res;
}

/// When you read the reports with csv, the hour ending is an integer.
/// Fix it with this function.
String stringHourEnding(dynamic hourEnding) {
  if (hourEnding is int) {
    hourEnding = hourEnding.toString().padLeft(2, '0');
  }
  return hourEnding;
}

/// Convert this date to the ISONE preferred date format, e.g. 11/26/2016.
String mmddyyyy(Date date) {
  String mm = date.month.toString().padLeft(2, '0');
  String dd = date.day.toString().padLeft(2, '0');
  return '$mm/$dd/${date.year}';
}
