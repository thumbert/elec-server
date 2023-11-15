library test.elec.iso_parsetime;

import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

void tests() {
  var location = getLocation('America/New_York');

  var dts = <List>[
    ['03/08/2015', '01', TZDateTime.utc(2015, 3, 8, 6)],
    ['03/08/2015', '03', TZDateTime.utc(2015, 3, 8, 7)],
    ['03/08/2015', '04', TZDateTime.utc(2015, 3, 8, 8)],
    ['03/08/2015', '05', TZDateTime.utc(2015, 3, 8, 9)],
    ['11/01/2015', '01', TZDateTime.utc(2015, 11, 1, 5)],
    ['11/01/2015', '02', TZDateTime.utc(2015, 11, 1, 6)],
    ['11/01/2015', '02X', TZDateTime.utc(2015, 11, 1, 7)],
    ['11/01/2015', '03', TZDateTime.utc(2015, 11, 1, 8)],
    ['11/01/2015', '04', TZDateTime.utc(2015, 11, 1, 9)],
    ['11/02/2015', '01', TZDateTime.utc(2015, 11, 2, 6)],
    ['11/02/2015', '02', TZDateTime.utc(2015, 11, 2, 7)],
    ['11/02/2015', '03', TZDateTime.utc(2015, 11, 2, 8)],
  ];

  test('Parse ISO timestamp', () {
    var res = dts.map((List inp) {
      var hb = parseHourEndingStamp(inp[0], inp[1]);
      return {'input': inp.take(2).join(' '), 'utc_HB': hb, 'utc_HE': inp[2]};
    }).toList();
    expect(dts.map((e) => e[2]).toList(),
        res.map((e) => e['utc_HB'].add(Duration(hours: 1))).toList());
  });

  test('to ISO timestamp, spring ahead', () {
    var hB = Interval(TZDateTime(location, 2015, 3, 8),
            TZDateTime(location, 2015, 3, 8, 5))
        .splitLeft((dt) => Hour.beginning(dt));
    var out = [
      ['2015-03-08', '01'],
      ['2015-03-08', '03'],
      ['2015-03-08', '04'],
      ['2015-03-08', '05'],
    ];
    for (var i = 0; i < 4; i++) {
      expect(toIsoHourEndingStamp(hB[i].start), out[i]);
    }
  });

  test('to ISO timestamp, fall back', () {
    var hB = Interval(TZDateTime(location, 2015, 11, 1),
            TZDateTime(location, 2015, 11, 1, 4))
        .splitLeft((dt) => Hour.beginning(dt));
    var out = [
      ['2015-11-01', '01'],
      ['2015-11-01', '02'],
      ['2015-11-01', '02X'],
      ['2015-11-01', '03'],
      ['2015-11-01', '04'],
    ];
    for (var i = 0; i < 5; i++) {
      expect(toIsoHourEndingStamp(hB[i].start), out[i]);
    }
  });

  test('to ISO timestamp, regular day', () {
    var hB = Interval(TZDateTime(location, 2015, 1, 1),
            TZDateTime(location, 2015, 1, 1, 4))
        .splitLeft((dt) => Hour.beginning(dt))
        .cast<Hour>();
    hB.add(Hour.beginning(TZDateTime(location, 2015, 1, 1, 23)));
    var out = [
      ['2015-01-01', '01'],
      ['2015-01-01', '02'],
      ['2015-01-01', '03'],
      ['2015-01-01', '04'],
      ['2015-01-01', '24'],
    ];
    for (var i = 0; i < out.length; i++) {
      expect(toIsoHourEndingStamp(hB[i].start), out[i]);
    }
  });

  test('is fallback date?', () {
    expect(isFallBackDate(Date(2015, 11, 1, location: location)), true);
    expect(isFallBackDate(Date(2015, 11, 2, location: location)), false);
    expect(isFallBackDate(Date.utc(2020, 3, 8)), false);
    expect(isFallBackDate(Date.utc(2020, 11, 1)), true);
  });
}

void main() async {
  initializeTimeZones();

  tests();
}
