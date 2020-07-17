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
      var mh5x16 = await client.getMonthlyForwardCurveForBucket(
          curveId, IsoNewEngland.bucket5x16, Date(2020, 5, 29),
          tzLocation: location);
      expect(mh5x16.domain, Term.parse('Jun20-Dec21', location).interval);
    });
    test('get mh curve as of 5/29/2020 for all buckets', () async {
      var curveId = 'isone_energy_4000_da_lmp';
      var res = await client.getMonthlyForwardCurve(
          curveId, Date(2020, 5, 29), tzLocation: location);
      expect(res.length, 19);
      var jan21 = res.observationAt(Month(2021, 1, location: location));
      expect(jan21.value[IsoNewEngland.bucket5x16], 58.25);
    });
    test('get mh hourly shape as of 5/29/2020 for all buckets', () async {
      var curveId = 'isone_energy_4000_hourlyshape';
      var res = await client.getHourlyShape(
          curveId, Date(2020, 5, 29), tzLocation: location);
      expect(res.buckets.length, 3);
    });



  });
}

void main() async {
  await initializeTimeZones();
  await tests('http://localhost:8080/');
}
