library iso.isone.db.converters;

import 'package:date/date.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

/// ISO dates are in mm/dd/yyyy.  Return a string in ISO format yyyy-mm-dd.
String formatDate(String mmddyyyy) {
if (mmddyyyy.length == 10)
    return '${mmddyyyy.substring(6,10)}-${mmddyyyy.substring(0,2)}-${mmddyyyy.substring(3,5)}';
  else {
    // in case the format is not standard, e.g 10/5/2017 instead of 10/05/2017
    RegExp regExp = new RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})');
    var matches = regExp.allMatches(mmddyyyy);
    var match = matches.elementAt(0);
    return '${match.group(3)}-${match.group(1).padLeft(2,'0')}-${match.group(2).padLeft(2,'0')}';
  }
}


/// How to convert different columns.  CSV converter is pretty good with the
/// numerical values.  I want to convert the dates, etc.
Map conversions = {
  /// ISO usually keeps the dates in mm/dd/yyyy format.
  'toDate': (String x) {
    int year = int.parse(x.substring(6, 10));
    int month = int.parse(x.substring(0, 2));
    int day = int.parse(x.substring(3, 5));
    return new Date(year, month, day);
  },
  'toDateTime': (String localDate, String hourEnding) {
    parseHourEndingStamp(localDate, hourEnding);
  },
};



