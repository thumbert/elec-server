library client.marks.forward_marks2;

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:http/http.dart';
import 'package:elec/src/risk_system/marks/monthly_curve.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';

enum MarkType {
  price('price'),
  vol('vol');

  const MarkType(this.name);

  final String name;
}

class ForwardMarks2 {
  ForwardMarks2({required this.rootUrl, Client? client}) {
    _client = client ?? Client();
  }

  final String rootUrl;
  final String baseUrl = 'forward_marks/v2';
  late Client _client;

  /// A strategy to deduce the bucket from the [curveName].
  Bucket getBucket(String curveName) {
    if (curveName.startsWith('PWR')) {
      throw ArgumentError('Electricity curves not supported yet');
    } else {
      return Bucket.atc;
    }
  }

  Future<List<String>> getCurveNames(
      {required Date asOfDate, required MarkType markType}) async {
    var url =
        '$rootUrl/$baseUrl/${markType.name}/curvenames/asofdate/${asOfDate.toString()}';
    var res = await _client.get(Uri.parse(url));
    return (json.decode(res.body) as List).cast<String>();
  }

  /// Return the monthly forward price curve associated with a [curveName] as
  /// of a given date.
  ///
  /// Return a [TimeSeries] in with intervals in the [location] specified.
  ///
  Future<TimeSeries<num>> getPriceCurveForAsOfDate(
      {required String curveName,
      required Date asOfDate,
      required Location location}) async {
    var url =
        '$rootUrl/$baseUrl/price/curvename/$curveName/asofdate/${asOfDate.toString()}';
    var res = await _client.get(Uri.parse(url));
    var aux = json.decode(res.body) as Map<String, dynamic>;
    var months = (aux['terms'] as List).map((e) => location == UTC
        ? Month.utc(int.parse(e.substring(0, 4)), int.parse(e.substring(5)))
        : Month(int.parse(e.substring(0, 4)), int.parse(e.substring(5)),
            location: location));
    var values = (aux['values'] as List).cast<num>();
    return TimeSeries.from(months, values);
  }

  /// Get the strike ratios for a list of vol curves.
  Future<List<num>> getStrikeRatios(
      {required String curveName, required Date asOfDate}) async {
    var url =
        '$rootUrl/$baseUrl/vol/strike_ratios/curvename/$curveName/asofdate/${asOfDate.toString()}';
    var res = await _client.get(Uri.parse(url));
    var aux = json.decode(res.body) as List;
    return aux.expand((e) => e).toList().cast<num>();
  }

  /// Get the forward vol as of a given date for a list of curves.
  /// [curveNames] e.g. 'PWR_ISONE_HUB_DA_5x16_D_VOL', 'PWR_ISONE_HUB_DA_5x16_M_VOL'
  Future<Map<String, TimeSeries<num>>> getVolCurvesForAsOfDate(
      {required List<String> curveNames,
      required CallPut callPut,
      required num strikeRatio,
      required Date asOfDate}) async {
    var url =
        '$rootUrl/$baseUrl/vol/curvenames/${curveNames.join(',')}/option_type/${callPut.toString()}/strike_ratio/$strikeRatio/asofdate/${asOfDate.toString()}';
    var res = await _client.get(Uri.parse(url));
    var aux = json.decode(res.body) as List;
    var groups = groupBy<dynamic, String>(aux, (e) => e[0]);
    return Map.fromIterables(
        groups.keys, groups.values.map((e) => _processOne(e, skip: 1)));
  }

  /// Return the price for a strip between a start and end report dates.
  /// [strip] needs to be a month range
  /// Need the [location] info to get the correct price calculation.
  /// Need the [bucket] info to do the correct aggregation.
  /// Return a [TimeSeries] in with intervals in the [location] specified.
  Future<TimeSeries<num>> getCurveStrip({
    required String curveName,
    required Term strip,
    required Date startDate,
    required Date endDate,
    required MarkType markType,
    required Location location,
    required Bucket bucket,
  }) async {
    if (!(strip.isMonthRange() || strip.isOneMonth())) {
      throw ArgumentError(
          'Argument strip needs to be a month or a month range!  It is $strip');
    }
    var bucket = getBucketForCurveName(curveName);
    var contractStart = Month.utc(strip.startDate.year, strip.startDate.month);
    var contractEnd = Month.utc(strip.endDate.year, strip.endDate.month);
    var url = '$rootUrl/$baseUrl/${markType.name}/curvename/$curveName/'
        'contract_start/${contractStart.toIso8601String()}/'
        'contract_end/${contractEnd.toIso8601String()}/'
        'start/$startDate/'
        'end/$endDate';
    var res = await _client.get(Uri.parse(url));
    var aux = json.decode(res.body) as List;
    var groups = groupBy(aux, (e) => e[0]); // group by report date

    var termTz = Term.fromInterval(strip.interval.withTimeZone(location));
    var ts = TimeSeries<num>();
    for (String reportDay in groups.keys) {
      var date = Date.fromIsoString(reportDay, location: UTC);
      var ys = TimeSeries<num>.fromIterable(groups[reportDay]!.map((e) {
        var month = Month.fromIsoString(e[1], location: location);
        return IntervalTuple(month, e[2]);
      }));
      var price = MonthlyCurve(bucket, ys).aggregateMonths(termTz.interval);
      ts.add(IntervalTuple(date, price ?? double.nan));
    }

    return ts;
  }

  /// Get the forward price curve for several curves in one call.
  /// Note there is a limit on the number of curves you can get in one call
  /// because the url length is limited to 2048 characters.
  Future<Map<String, TimeSeries<num>>> getPriceCurvesForAsOfDate(
      {required List<String> curveNames, required Date asOfDate}) async {
    var url = '$rootUrl/$baseUrl/price/curvenames/'
        '${curveNames.join(',')}/asofdate/${asOfDate.toString()}';
    var res = await _client.get(Uri.parse(url));
    var aux = json.decode(res.body) as List;
    var groups = groupBy(aux, (e) => e[0] as String);
    return groups
        .map((key, value) => MapEntry(key, _processOne(value, skip: 1)));
  }

  /// Process one series
  /// Input list can be one of [20230301, 46.25] or
  /// ['PWR_ISONE_HUB_DA_5x16', 20230301, 46.25], etc.
  ///
  TimeSeries<num> _processOne(List xs, {required int skip}) {
    var s1 = skip + 1;
    var ts = xs.map((e) {
      /// data should be monthly only (check
      var day = e[skip] % 100;
      if (day != 1) {
        throw StateError('Unexpected daily data! $e');
      }
      var year = e[skip] ~/ 10000;
      var mm = (e[skip] % 10000) ~/ 100;
      var month = Month.utc(year, mm);
      return IntervalTuple<num>(month, e[s1]);
    });
    return TimeSeries.fromIterable(ts);
  }

  Bucket getBucketForCurveName(String curveName) {
    return Bucket.atc;
  }
}

/// Get the (yyyy, mm, dd) from a date input, e.g.
/// Return [2023, 3, 5] for input 20230305
List<int> _ymd(int yyyymmdd) {
  var day = yyyymmdd % 100;
  var month = (yyyymmdd % 10000) ~/ 100;
  var year = yyyymmdd ~/ 10000;
  return <int>[year, month, day];
}
