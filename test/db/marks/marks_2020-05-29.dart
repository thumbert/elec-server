library test.db.marks.marks_20200529;

import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

///
List<Map<String, dynamic>> marks20200529() {
  var fromDate = '2020-05-29';
  var location = getLocation('US/Eastern');
  var months = Term.parse('Jun20-Dec21', location)
      .interval
      .splitLeft((dt) => Month.fromTZDateTime(dt))
      .map((e) => e.toIso8601String())
      .toList();

  return <Map<String, dynamic>>[
    {
      'fromDate': fromDate,
      'curveId': 'isone_energy_4000_da_lmp',
      'months': months,
      'buckets': {
        '5x16': [
          22.2,
          25.4,
          25.3,
          22.65,
          22.5,
          34,
          49.25,
          58.25,
          55.75,
          40,
          30.75,
          26.15,
          27.25,
          32.5,
          31,
          26.75,
          27.25,
          37.25,
          51,
        ],
        '2x16H': [
          18.35,
          22.86,
          22.77,
          20.385,
          22.25,
          30.6,
          44.325,
          52.716,
          50.454,
          36,
          28.598,
          23.012,
          23.98,
          28.275,
          26.97,
          22.738,
          23.163,
          33.525,
          46,
        ],
        '7x8': [
          12.928,
          16.325,
          15.827,
          13.529,
          15.271,
          24.61,
          36.303,
          48.072,
          46.284,
          33.343,
          20.718,
          21.282,
          20.944,
          22.065,
          21.485,
          19.958,
          20.016,
          27.894,
          41.073,
        ]
      }
    },
    {
      'fromDate': fromDate,
      'curveId': 'isone_energy_4004_da_basis',
      'months': months,
      'buckets': {
        '5x16': [
          -0.05,
          0,
          0,
          -0.05,
          -0.2,
          -0.2,
          -0.25,
          -0.65,
          -0.65,
          -0.15,
          -0.05,
          0,
          0.05,
          0.1,
          0.1,
          0.05,
          -0.1,
          -0.1,
          -0.15,
        ],
        '2x16H': [
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.25,
          -0.55,
          -0.55,
          -0.17,
          -0.1,
          -0.1,
          -0.1,
          -0.05,
          -0.05,
          -0.1,
          -0.1,
          -0.1,
          -0.15,
        ],
        '7x8': [
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.25,
          -0.55,
          -0.55,
          -0.17,
          -0.1,
          -0.1,
          -0.1,
          -0.05,
          -0.05,
          -0.1,
          -0.1,
          -0.1,
          -0.15,
        ],
      }
    }
  ];
}
