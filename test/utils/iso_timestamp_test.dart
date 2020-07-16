library test.elec.iso_parsetime;

import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

testParseIsoTimestamp() {
  Location location = getLocation('America/New_York');

  List<List> dts = [
    ['03/08/2015', '01', new TZDateTime.utc(2015, 3, 8, 6)],
    ['03/08/2015', '03', new TZDateTime.utc(2015, 3, 8, 7)],
    ['03/08/2015', '04', new TZDateTime.utc(2015, 3, 8, 8)],
    ['03/08/2015', '05', new TZDateTime.utc(2015, 3, 8, 9)],
    ['11/01/2015', '01', new TZDateTime.utc(2015, 11, 1, 5)],
    ['11/01/2015', '02', new TZDateTime.utc(2015, 11, 1, 6)],
    ['11/01/2015', '02X', new TZDateTime.utc(2015, 11, 1, 7)],
    ['11/01/2015', '03', new TZDateTime.utc(2015, 11, 1, 8)],
    ['11/01/2015', '04', new TZDateTime.utc(2015, 11, 1, 9)],
    ['11/02/2015', '01', new TZDateTime.utc(2015, 11, 2, 6)],
    ['11/02/2015', '02', new TZDateTime.utc(2015, 11, 2, 7)],
    ['11/02/2015', '03', new TZDateTime.utc(2015, 11, 2, 8)],
  ];

  test('Parse ISO timestamp', () {
    List res = dts.map((List inp) {
      DateTime hb = parseHourEndingStamp(inp[0], inp[1]);
      return {'input': inp.take(2).join(' '), 'utc_HB': hb, 'utc_HE': inp[2]};
    }).toList();
    expect(dts.map((e) => e[2]).toList(),
        res.map((e) => e['utc_HB'].add(new Duration(hours: 1))).toList());
  });

  test('to ISO timestamp, spring ahead', () {
    var hB = new Interval(new TZDateTime(location, 2015, 3, 8),
            new TZDateTime(location, 2015, 3, 8, 5))
        .splitLeft((dt) => new Hour.beginning(dt));
    List out = [
      ['2015-03-08', '01'],
      ['2015-03-08', '03'],
      ['2015-03-08', '04'],
      ['2015-03-08', '05'],
    ];
    for (int i=0; i<4; i++) {
      expect(toIsoHourEndingStamp(hB[i].start), out[i]);
    }
  });

  test('to ISO timestamp, fall back', () {
    var hB = new Interval(new TZDateTime(location,2015,11,1),
        new TZDateTime(location,2015,11,1,4))
        .splitLeft((dt) => new Hour.beginning(dt));
    List out = [
      ['2015-11-01', '01'],
      ['2015-11-01', '02'],
      ['2015-11-01', '02X'],
      ['2015-11-01', '03'],
      ['2015-11-01', '04'],
    ];
    for (int i=0; i<5; i++) {
      expect(toIsoHourEndingStamp(hB[i].start), out[i]);
    }
  });

  test('to ISO timestamp, regular day', () {
    var hB = new Interval(new TZDateTime(location,2015,1,1),
        new TZDateTime(location,2015,1,1,4))
        .splitLeft((dt) => new Hour.beginning(dt)).cast<Hour>();
    hB.add(new Hour.beginning(new TZDateTime(location,2015,1,1,23)));
    List out = [
      ['2015-01-01', '01'],
      ['2015-01-01', '02'],
      ['2015-01-01', '03'],
      ['2015-01-01', '04'],
      ['2015-01-01', '24'],
    ];
    for (int i=0; i<out.length; i++) {
      expect(toIsoHourEndingStamp(hB[i].start), out[i]);
    }
  });


}

main() async {
  await initializeTimeZone();

  testParseIsoTimestamp();
}
