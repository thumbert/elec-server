library utils.timezone_utils;

import 'dart:io';

/// get the location of the timezone database, until the package figures out a
/// a better way.
String getLocationTzdb() {
  String tzdb = 'hosted/pub.dartlang.org/timezone-0.4.3/lib/data/2015b.tzf';
  if (Platform.isWindows) {
    tzdb = Platform.environment['USERPROFILE'] + '/AppData/Roaming/Pub/Cache/' + tzdb;
  } else if (Platform.isLinux) {
    tzdb = Platform.environment['HOME'] + '/.pub-cache/' + tzdb;
  }
  return tzdb;
}
