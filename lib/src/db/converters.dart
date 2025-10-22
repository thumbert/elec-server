import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

DateFormat _fmt = DateFormat('MM/dd/yyyy');

/// ISO dates are in mm/dd/yyyy.  Return a string in ISO format yyyy-mm-dd.
String formatDate(String mmddyyyy) {
  if (mmddyyyy.length == 10) {
    return '${mmddyyyy.substring(6, 10)}-${mmddyyyy.substring(0, 2)}-${mmddyyyy.substring(3, 5)}';
  } else {
    return _fmt.parse(mmddyyyy).toIso8601String().substring(0, 10);
  }
}

/// How to convert different columns.  CSV converter is pretty good with the
/// numerical values.  I want to convert the dates, etc.
Map conversions = {
  /// ISO usually keeps the dates in mm/dd/yyyy format.
  'toDate': (String x) {
    var year = int.parse(x.substring(6, 10));
    var month = int.parse(x.substring(0, 2));
    var day = int.parse(x.substring(3, 5));
    return Date.utc(year, month, day);
  },
  'toDateTime': (String localDate, String hourEnding) {
    parseHourEndingStamp(localDate, hourEnding);
  },
};
