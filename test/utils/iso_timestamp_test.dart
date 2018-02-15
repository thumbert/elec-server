library test.elec.iso_parsetime;

import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';



test_parseIsoTimestamp() {


  test('Parse ISO timestamp', () {
    List dts = [
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

    List res = [];
    dts.forEach((List inp) {
      DateTime hb = parseHourEndingStamp(inp[0], inp[1]);
      return res.add({
        'input': inp.take(2).join(' '),
        'utc_HB': hb,
        'utc_HE': inp[2]
      });
    });
    //res.forEach((e) => print(e));
    expect(dts.map((e)=>e[2]).toList(), res.map((e)=>e['utc_HB'].add(new Duration(hours: 1))).toList());
  });
}



main() async {
  await initializeTimeZone(getLocationTzdb());

  test_parseIsoTimestamp();
}
