library test.db.marks.marks_20200529;

import 'dart:convert';
import 'dart:io';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:timeseries/timeseries.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

/// Mark all remaining days in May20 the same value, and then monthly values.
List<Map<String, dynamic>> marks20200529() {
  var fromDate = '2020-05-29';
  var location = getLocation('America/New_York');
  var months = Term.parse('May20-Dec26', location)
      .interval
      .splitLeft((dt) => Month.fromTZDateTime(dt))
      .map((e) => e.toIso8601String())
      .toList();

  return <Map<String, dynamic>>[
    {
      'fromDate': fromDate,
      'curveId': 'isone_energy_4000_da_lmp',
      'terms': months,
      'buckets': {
        '5x16': [
          27.25,
          22.2,
          25.4,
          25.3,
          22.65,
          22.5,
          34,
          49.25,
          // 2021
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
          // 2022
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
          // 2023
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
          // 2024
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
          // 2025
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
          // 2026
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
          19.25,
          18.35,
          22.86,
          22.77,
          20.385,
          22.25,
          30.6,
          44.325,
          // 2021
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
          // 2022
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
          // 2023
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
          // 2024
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
          // 2025
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
          // 2026
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
          14.151,
          12.928,
          16.325,
          15.827,
          13.529,
          15.271,
          24.61,
          36.303,
          // 2021
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
          // 2022
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
          // 2023
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
          // 2024
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
          // 2025
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
          // 2026
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
      'terms': months,
      'buckets': {
        '5x16': [
          -0.10,
          -0.05,
          0,
          0,
          -0.05,
          -0.2,
          -0.2,
          -0.25,
          // 2021
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
          // 2022
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
          // 2023
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
          // 2024
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
          // 2025
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
          // 2026
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
          -0.15,
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.25,
          // 2021
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
          // 2022
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
          // 2023
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
          // 2024
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
          // 2025
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
          // 2026
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
          -0.15,
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.2,
          -0.25,
          // 2021
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
          // 2022
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
          // 2023
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
          // 2024
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
          // 2025
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
          // 2026
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

/// Mark both daily and monthly terms.
List<Map<String, dynamic>> marks20200706() {
  var fromDate = '2020-07-06';
  var location = getLocation('America/New_York');
  var months = Term.parse('Aug20-Dec25', location)
      .interval
      .splitLeft((dt) => Month.fromTZDateTime(dt))
      .map((e) => e.toIso8601String())
      .toList();
  var days = Term.parse('7Jul20-31Jul20', location)
      .days()
      .map((e) => e.toString())
      .toList();

  return <Map<String, dynamic>>[
    {
      'fromDate': fromDate,
      'curveId': 'isone_energy_4000_da_lmp',
      'terms': [
        ...days,
        ...months,
      ],
      'buckets': {
        '5x16': [
          23.48,
          23.48,
          23.48,
          23.48,
          null,
          null,
          25.1,
          25.1,
          25.1,
          25.1,
          25.1,
          null,
          null,
          27.5,
          27.5,
          27.5,
          27.5,
          27.5,
          null,
          null,
          30,
          30,
          30,
          30,
          30,
          26.8,
          25.3,
          23.75,
          33.1,
          49.25,
          // 2021
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
          // 2022
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
          // 2023
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
          // 2024
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
          // 2025
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
          null,
          null,
          null,
          null,
          21.25,
          21.25,
          null,
          null,
          null,
          null,
          null,
          23.4,
          23.4,
          null,
          null,
          null,
          null,
          null,
          25.25,
          25.25,
          null,
          null,
          null,
          null,
          null,
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
          // 2022
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
          // 2023
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
          // 2024
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
          // 2025
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
          ...List.filled(25, 15.5),
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
          // 2022
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
          // 2023
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
          // 2024
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
          // 2025
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

/// A generic historical hourly shape to be applied to all future years.
List<Map<String, dynamic>> hourlyShape20191231() {
  var aux = File('test/db/marks/hourly_shape.json').readAsStringSync();
  var x0 = json.decode(aux);
  // extend it to Dec26
  var months = Term.parse('Jan20-Dec26', UTC)
      .interval
      .splitLeft((dt) => Month.fromTZDateTime(dt))
      .map((e) => e.toIso8601String())
      .toList();
  x0['terms'] = months;
  for (var bucket in ['7x8', '2x16H', '5x16']) {
    x0['buckets'][bucket] = List.generate(7, (i) => x0['buckets'][bucket])
        .expand((e) => e)
        .toList();
  }
  return <Map<String, dynamic>>[
    {
      'fromDate': '2019-12-31',
      'curveId': 'isone_energy_4000_hourlyshape',
      ...x0,
    }
  ];
}

/// A made up volatility surface
List<Map<String, dynamic>> volatilitySurface() {
  var aux = File('test/db/marks/volatility_surface.json').readAsStringSync();
  var x0 =
      (json.decode(aux) as List).first as Map<String, dynamic>; // daily isone
  // add the '2x16H' and '7x8' bucket
  var _terms = (x0['terms'] as List).map((e) => Month.parse(e)).toList();
  x0['buckets']['2x16H'] = <List<num>>[];
  x0['buckets']['7x8'] = <List<num>>[];
  for (var i = 0; i < _terms.length; i++) {
    x0['buckets']['2x16H'].add((x0['buckets']['5x16'][i] as List)
        .map((e) => (e as num) * 0.85)
        .toList());
    x0['buckets']['7x8'].add((x0['buckets']['5x16'][i] as List)
        .map((e) => (e as num) * 0.5)
        .toList());
  }
  // extend it to Dec26, decaying yoy by 90%
  var location = getLocation('America/New_York');
  var vs = VolatilitySurface.fromJson(x0, location: location);
  var vsX = vs.extendPeriodicallyByYear(Month(2026, 12, location: location),
      f: (x) => 0.9 * x);

  var fromDate = Date.parse(x0['fromDate']);
  var out = vsX.toMongoDocument(fromDate, x0['curveId']);
  return [out];
}
