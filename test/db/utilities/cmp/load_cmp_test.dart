import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/client/utilities/cmp/cmp.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:http/http.dart';
import 'package:timezone/data/latest.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:test/test.dart';
import 'package:timezone/timezone.dart';

Future<void> tests() async {
  group('CMP load archive tests', () {
    var archive = getCmpLoadArchive();
    test('read files 2020', () {
      var data = archive.processFile(
          year: 2020,
          customerClass: CmpCustomerClass.residentialAndSmallCommercial);
      expect(data.length, 366);
      expect(data.first.keys.toSet(), {'date', 'class', 'settlement', 'mwh'});
      var x1101 = data.firstWhere((e) => e['date'] == '2020-11-01');
      expect(x1101['mwh'].take(4).toList(), [
        414.104,
        386.323,
        384.478,
        371.304,
      ]);
    });

    test('read files 2021', () {
      var data = archive.processFile(
          year: 2021,
          customerClass: CmpCustomerClass.residentialAndSmallCommercial);
      expect(data.length, 365);
      expect(data.first.keys.toSet(), {'date', 'class', 'settlement', 'mwh'});
      var x1107 = data.firstWhere((e) => e['date'] == '2021-11-07');
      expect(x1107['mwh'].take(4).toList(), [
        415.755,
        396.970,
        389.098,
        378.509,
      ]);
    });

    test('read files 2022', () {
      var data = archive.processFile(
          year: 2022,
          customerClass: CmpCustomerClass.residentialAndSmallCommercial);
      expect(data.length, 365);
      expect(data.first.keys.toSet(), {'date', 'class', 'settlement', 'mwh'});
      var x1106 = data.firstWhere((e) => e['date'] == '2022-11-06');
      expect(x1106['mwh'].take(4).toList(), [
        295.438,
        274.852,
        272.428,
        261.073,
      ]);
    });

    test('read files 2023', () {
      var data = archive.processFile(
          year: 2023,
          customerClass: CmpCustomerClass.residentialAndSmallCommercial);
      expect(data.first.keys.toSet(), {'date', 'class', 'settlement', 'mwh'});
      expect(data.first['class'], 'residentialAndSmallCommercial');
      expect(data.first['settlement'], 'final');
      var x0101 = data.firstWhere((e) => e['date'] == '2023-01-01');
      expect(x0101['mwh'].take(4).toList(), [
        427.530,
        392.027,
        372.903,
        363.066,
      ]);
      var x0204 = data.firstWhere((e) => e['date'] == '2023-02-04');
      expect(x0204['mwh'][17], 1004.551);
    });
  });
  group('CMP load api tests', () {
    test('get load', () async {
      var url = '${dotenv.env['ROOT_URL']}/utility/v1/cmp/load/class'
          '/residentialAndSmallCommercial/start/2022-01-01/end/2022-01-10'
          '/settlement/final';
      var res = await get(Uri.parse(url));
      var data = json.decode(res.body) as List;
      expect(data.length, 10);
      expect((data.first as Map).keys.toSet(), {'date', 'mwh'});
    });
  });

  group('CMP load client tests', () {
    var client = Cmp(rootUrl: dotenv.env['ROOT_URL']!);
    test('get load', () async {
      var term = Term.parse('1Jan22-10Jan22', IsoNewEngland.location);
      var data = await client.getHourlyLoad(
          term, CmpCustomerClass.residentialAndSmallCommercial);
      expect(data.length, 240);
      expect(data.first.interval, Hour.beginning(TZDateTime(IsoNewEngland.location, 2022)));
      expect(data.first.value, 469.064);
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  await tests();
}
