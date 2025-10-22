import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

final Location _eastern = getLocation('America/New_York');

/// Convert from an ISONE string tuple.
/// [localDate] is a String in format 'mm/dd/yyyy'
/// [hourEnding] is of the form '01', '02', '02X', '03', ... '24'
/// Return an hour beginning UTC TZDateTime
TZDateTime parseHourEndingStamp(String localDate, String hourEnding) {
  var res = TZDateTime(
          _eastern,
          int.parse(localDate.substring(6, 10)),
          int.parse(localDate.substring(0, 2)),
          int.parse(localDate.substring(3, 5)),
          int.parse(hourEnding.substring(0, 2)) - 1)
      .toUtc();

  if (hourEnding == '02X') {
    // you are at a transition point
    res = res.add(Duration(hours: 1));
  }

  return res;
}

/// Convert an hour beginning timestamp to the ISO hour ending format.
/// The [hourBeginning] timestamp needs to be in the eastern time zone.
/// Return a two element list with the date and hour ending.
/// E.g. ['2018-02-01', '03'], ['2018-02-11', '24'].
List<String> toIsoHourEndingStamp(TZDateTime hourBeginning) {
  var hour = Hour.beginning(hourBeginning);
  var offsetStart = hour.start.timeZoneOffset.inHours;
  var isFallBack = isFallBackDate(
      Date.utc(hourBeginning.year, hourBeginning.month, hourBeginning.day));
  var res = [hour.start.toString().substring(0, 10)];

  if (hourBeginning.hour == 23) {
    res.add('24');
  } else {
    if (isFallBack) {
      if (hour.start.hour == 0) {
        res.add('01');
      } else if (hour.start.hour == 1 && offsetStart == -4) {
        res.add('02');
      } else if (hour.start.hour == 1 && offsetStart == -5) {
        res.add('02X');
      } else {
        res.add(hour.end.hour.toString().padLeft(2, '0'));
      }
    } else {
      res.add(hour.end.hour.toString().padLeft(2, '0'));
    }
  }

  return res;
}

/// Check if this date is a fall back date for the America/New_York time zone.
/// Return true if it is.
bool isFallBackDate(Date date) {
  var offsetStart = TZDateTime(_eastern, date.year, date.month, date.day)
      .timeZoneOffset
      .inHours;
  var offsetEnd = TZDateTime(_eastern, date.year, date.month, date.day, 23)
      .timeZoneOffset
      .inHours;
  var res = false;
//  if (offsetStart == -4 && offsetEnd == -5) res = true; // for US/Eastern
  if (offsetStart > offsetEnd) res = true;
  return res;
}

/// When you read the MIS reports with csv, the hour ending is an integer.
/// Fix it with this function.
String? stringHourEnding(dynamic hourEnding) {
  if (hourEnding is int) {
    hourEnding = hourEnding.toString().padLeft(2, '0');
  }
  return hourEnding;
}

/// Convert this date to the ISONE preferred date format, e.g. 11/26/2016.
String mmddyyyy(Date date) {
  var mm = date.month.toString().padLeft(2, '0');
  var dd = date.day.toString().padLeft(2, '0');
  return '$mm/$dd/${date.year}';
}

/// Convert an mm/dd/yyyy string to a UTC date.
/// For example '11/26/2016' -> Date.utc(2016, 11, 26)
/// Note: will fail on '10/3/2016'.  Needs to be '10/03/2016'!
Date parseMmddyyy(String mmddyyyy) {
  return Date.utc(int.parse(mmddyyyy.substring(6, 10)),
      int.parse(mmddyyyy.substring(0, 2)), int.parse(mmddyyyy.substring(3, 5)));
}
