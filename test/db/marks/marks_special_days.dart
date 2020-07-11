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
      'markType': 'monthly',
      'terms': months,
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
      'markType': 'monthly',
      'terms': months,
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
List<Map<String, dynamic>> marks20200706() {
  var fromDate = '2020-07-06';
  var location = getLocation('US/Eastern');
  var months = Term.parse('Aug20-Dec21', location)
      .interval
      .splitLeft((dt) => Month.fromTZDateTime(dt))
      .map((e) => e.toIso8601String())
      .toList();
  var days = Term.parse('7Jul20-31Jul20', location).days()
      .map((e) => e.toString())
      .toList();

  return <Map<String, dynamic>>[
    {
      'fromDate': fromDate,
      'curveId': 'isone_energy_4000_da_lmp',
      'markType': 'daily',
      'terms': days,
      'buckets': {
        '5x16': [
          23.48, 23.48, 23.48, 23.48, null, null,
          25.1, 25.1, 25.1, 25.1, 25.1, null, null,
          27.5, 27.5, 27.5, 27.5, 27.5, null, null,
          30, 30, 30, 30, 30,
        ],
        '2x16H': [
          null, null, null, null, 21.25, 21.25,
          null, null, null, null, null, 23.4, 23.4,
          null, null, null, null, null, 25.25, 25.25,
          null, null, null, null, null,
        ],
        '7x8': List.filled(25, 15.5),
      }
    },
    {
      'fromDate': fromDate,
      'curveId': 'isone_energy_4000_da_lmp',
      'markType': 'monthly',
      'terms': months,
      'buckets': {
        '5x16': [
          26.8,
          25.3,
          23.75,
          33.1,
          49.25,
          60.7,
          57.2,
          40.75,
          31.45,
          26.75,
          27.85,
          33.3,
          32.05,
          27.15,
          27.85,
          36.3,
          51,
        ],
        '2x16H': [
          24.12,
          22.77,
          21.38,
          29.79,
          44.33,
          54.93,
          51.77,
          36.68,
          29.25,
          23.54,
          24.51,
          28.97,
          27.88,
          23.08,
          23.67,
          32.67,
          45.9,
        ],
        '7x8': [
          16.35,
          15.30,
          15.65,
          25.15,
          35.67,
          48.89,
          46.16,
          33.37,
          20.82,
          20.22,
          19.97,
          22.68,
          21.59,
          20.15,
          19.69,
          30,
          40.37,
        ]
      }
    },
  ];
}
