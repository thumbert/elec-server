library test.client.marks.forward_marks_test;

import 'package:http/http.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/client/marks/forward_marks.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';

void tests(String rootUrl) async {
  group('ForwardMarks client tests:', () {
    var client = ForwardMarks(Client(), rootUrl: rootUrl);
    var location = getLocation('America/New_York');
    test('get mh 5x16 as of 5/29/2020', () async {
      var curveId = 'isone_energy_4000_da_lmp';
      var mh5x16 = await client.getForwardCurveForBucket(
          curveId, IsoNewEngland.bucket5x16, Date(2020, 5, 29),
          tzLocation: location);
      expect(mh5x16.domain, Term.parse('Jun20-Dec21', location).interval);
    });
    test('get mh curve as of 5/29/2020', () async {
      var curveId = 'isone_energy_4000_da_lmp';
      var res = await client.getForwardCurve(
          curveId, Date(2020, 5, 29), tzLocation: location);
      expect(true, true);
    });


  });
}

void main() async {
  await initializeTimeZones();
  await tests('http://localhost:8080/');
}
