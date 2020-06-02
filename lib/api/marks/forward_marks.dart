library api.other.forward_marks;

import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:elec/elec.dart';
import 'package:elec_server/src/db/marks/composite_curves.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:rpc/rpc.dart';
import 'package:date/date.dart';
import 'package:dama/dama.dart';
import 'package:timezone/timezone.dart';
import '../../src/utils/api_response.dart';
import 'package:elec_server/src/db/marks/curve_attributes.dart' as ca;

@ApiClass(name: 'forward_marks', version: 'v1')
class ForwardMarks {
  mongo.Db db;
  mongo.DbCollection coll;
  Map<String, Map<String, dynamic>> curveDefinitions;
  List<Map<String, dynamic>> compositeCurves;

  static final DateFormat _isoFmt = DateFormat('yyyy-MM');

  ForwardMarks(this.db) {
    coll = db.collection('forward_marks');

    /// should be in a database
    curveDefinitions = {
      /// default definition
      '_': {
        'location': 'US/Eastern',
        'bucketDefs': {
          'offpeak': ['2x16H', '7x8'],
          'wrap': ['2x16H', '7x8'],
          'atc': ['5x16', '2x16H', '7x8'],
          '7x24': ['5x16', '2x16H', '7x8'],
          'flat': ['5x16', '2x16H', '7x8'],
        },
      }
    };
    compositeCurves = getCompositeCurves();
  }

  /// Get all the existing curve ids in the database, sorted
  @ApiMethod(path: 'curveIds')
  Future<List<String>> getCurveIds() async {
    var aux = await coll.distinct('curveId');
    var res = <String>[...(aux['values'] as List),
      ...compositeCurves.map((e) => e['curveId'])];
    return res..sort();
  }

  /// Get all the curveIds that match a given pattern.
  @ApiMethod(path: 'curveIds/pattern/{pattern}')
  Future<List<String>> getCurveIdsContaining(String pattern) async {
    var aux = await coll.distinct('curveId');
    var res = <String>[
      ...(aux['values'] as List).where((e) => e.contains(pattern)),
      ...compositeCurves.map((e) => e['curveId'] as String)
          .where((e) => e.contains(pattern))
    ];
    return res..sort();
  }

  /// Get the dates when a given curve was marked
  @ApiMethod(path: 'curveId/{curveId}/fromDates')
  Future<List<String>> getFromDatesForCurveId(String curveId) async {
    var pipeline = [
      {
        '\$match': {
          'curveId': {'\$eq': curveId},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'fromDate': 1,
        }
      },
      {
        '\$sort': {'fromDate': -1},
      },
    ];
    return await coll
        .aggregateToStream(pipeline)
        .map((e) => e['fromDate'] as String)
        .toList();
  }

  /// Get all the curves that were marked on this date
  @ApiMethod(path: 'fromDate/{fromDate}/curveIds')
  Future<List<String>> getCurveIdsForFromDate(String fromDate) async {
    var pipeline = [
      {
        '\$match': {
          'fromDate': {'\$eq': Date.parse(fromDate).toString()},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'curveId': 1,
        }
      },
      {
        '\$sort': {'curveId': 1},
      },
    ];
    return await coll
        .aggregateToStream(pipeline)
        .map((e) => e['curveId'] as String)
        .toList();
  }

  /// Get the buckets marked for one curve.
  Future<Set<String>> getBucketsMarked(String curveId) async {
    var buckets = ca.getBucketsMarked(curveId);
    if (ca.getBucketsMarked(curveId).isNotEmpty) return buckets;

    // fall back procedure
    var query = mongo.where
      ..eq('curveId', curveId)
      ..excludeFields(['_id']);
    var res = await coll.findOne(query);
    if (res == null) return <String>{};
    if (res.containsKey('buckets')) {
      return res['buckets'].keys.toSet();
    } else if (res.containsKey('children')) {
      // if it's a composite curve, look at the first child
      return getBucketsMarked(res['children'].first);
    }

    return <String>{};
  }

  /// TODO:

  /// Get all the curves that were marked on a given asOfDate
//  @ApiMethod(path: 'curveIds/asOfDate/{asOfDate}')

  /// Get the forward prices for one curveId for two asOfDates
  /// Deal with spreads to hubs or composite curves (addition and multiplication).

  /// Get the forward curve as of a given date.  Return all marked buckets.
  @ApiMethod(path: 'curveId/{curveId}/asOfDate/{asOfDate}')
  Future<ApiResponse> getForwardCurve(String curveId, String asOfDate) async {
    var aux = await _getForwardCurve(asOfDate, curveId);
    return ApiResponse()..result = json.encode(aux);
  }

  /// Return one of the buckets for this curveId.
  /// Return a map with sorted keys {'2019-01': 87.13, '2019-02': 78.37, ...}
  /// If the bucket doesn't exist in the database, calculate it
  /// based on the curveDefinitions, for example calculate the offpeak and
  /// 7x24 bucket.
  @ApiMethod(path: 'curveId/{curveId}/bucket/{bucket}/asOfDate/{asOfDate}')
  Future<ApiResponse> getForwardCurveForBucket(
      String curveId, String bucket, String asOfDate) async {
    var data = await _getForwardCurveBuckets(asOfDate, curveId, [bucket]);
    return ApiResponse()..result = json.encode(data[bucket]);
  }

  /// Return the prices for this curveId for the buckets requested.
  /// [buckets] need to be separated by '_', e.g. '5x16_7x24_offpeak'
  /// Return a map of {bucket: {'yyyy-mm': value, ...}
  /// If the bucket doesn't exist in the database, calculate it
  /// based on the curveDefinitions, for example calculate the offpeak and
  /// 7x24 bucket.
  @ApiMethod(path: 'curveId/{curveId}/buckets/{buckets}/asOfDate/{asOfDate}')
  Future<ApiResponse> getForwardCurveForBuckets(
      String curveId, String buckets, String asOfDate) async {
    var _buckets = buckets.split('_');
    var data = await _getForwardCurveBuckets(asOfDate, curveId, _buckets);
    return ApiResponse()..result = json.encode(data);
  }


//  /// Calculate the curve value for a list of strips, e.g. 'Jan19-Feb19_Q1,2020'.
//  /// Strips should be a list of underscore separated terms.  If the curve
//  /// is not defined for some months in the strip, ignore that strip in the
//  /// response.
//  @ApiMethod(
//      path:
//          'curveId/{curveId}/bucket/{bucket}/asOfDate/{asOfDate}/strips/{strips}')
//  Future<ApiResponse> getForwardCurveForBucketStrips(
//      String curveId, String bucket, String asOfDate, String strips) async {
//    var data = await _getForwardCurveBuckets(asOfDate, curveId, [bucket]);
//    var _strips = strips.split('_');
//    var out = await _calculateBucketsStrips(curveId, data, _strips);
//    return ApiResponse()..result = json.encode(out);
//  }


  /// Calculate the curve value for a list of strips, e.g. 'Jan19-Feb19_Q1,2020'
  /// Strips should be a list of semicolon separated terms.  If the curve
  /// is not defined for some months in the strip, ignore that strip in the
  /// response.
  /// [buckets] is a list of '_' separated bucket names, e.g. '7x24_Offpeak_7x8'
  ///
  @ApiMethod(
      path:
      'curveId/{curveId}/buckets/{buckets}/asOfDate/{asOfDate}/strips/{strips}')
  Future<ApiResponse> getForwardCurveForBucketsStrips(
      String curveId, String buckets, String asOfDate, String strips) async {
    var _strips = strips.split('_');
    var _buckets = buckets.split('_');
    var data = await _getForwardCurveBuckets(asOfDate, curveId, _buckets);
    var out = await _calculateBucketsStrips(curveId, data, _strips);
    return ApiResponse()..result = json.encode(out);
  }


  /// Get a strip price (e.g. Jan20-Feb20) between a start and end date.
  /// If the bucket is not primary, then what?
//  @ApiMethod(
//      path:
//      'curveId/{curveId}/bucket/{bucket}/strip/{strip}/start/{startDate}/end/{endDate}')
//  Future<ApiResponse> getStripValueForDateRange(
//      String curveId, String bucket, String strip, String startDate, String endDate) async {
//    /// need to get the strip from the db for a series of dates
//  }


//  /// TODO:
//  Future<ApiResponse> getHistoricalValueForTermBucket(String asOfDate,
//      String curveId, String term, String bucket) async {
//    var query = where
//      ..gte('date', Date.parse(asOfDate).toString())
//      ..eq('curveId', curveId)
//      ..fields(['months', bucket]);
//    var res = await coll.find(query).toList();
//    return ApiResponse()..result = json.encode(res);
//  }

  // TODO: return only one bucket, & return only a month,bucket historically

  Future<Map<String,dynamic>> _getForwardCurve(
      String asOfDate, String curveId) async {
    var pipeline = [
      {
        '\$match': {
          'curveId': {'\$eq': curveId},
          'fromDate': {'\$lte': Date.parse(asOfDate).toString()},
        }
      },
      {
        '\$sort': {'fromDate': -1},
      },
      {
        '\$limit': 1,
      },
      {
        '\$project': {
          '_id': 0,
          'fromDate': 0,
          'curveId': 0,
        }
      },
    ];
    var aux = await coll.aggregateToStream(pipeline).toList();
    return aux.first;
  }

  /// Return a Map of maps, each entry is in the form {bucket: {'yyyy-mm': num}}
  Future<Map<String,Map<String,num>>> _getForwardCurveBuckets(
      String asOfDate, String curveId, List<String> buckets) async {
    var data = await _getForwardCurve(asOfDate, curveId);
    var out = <String,Map<String,num>>{};
    var months = data['months'] as List;
    var _buckets = (data['buckets'] as Map).keys;

    for (var bucket in buckets) {
      var one = <String,num>{};
      if (_buckets.contains(bucket)) {
        /// the bucket is stored in the db
        var values = data['buckets'][bucket] as List;
        for (var i = 0; i < months.length; i++) {
          one[months[i]] = values[i];
        }
      } else {
        /// the bucket must exist in the [curveDefinitions]
        /// if it doesn't exist, return empty {}
        var curveDefs = curveDefinitions[curveId] ?? curveDefinitions['_'];
        if (curveDefs['bucketDefs'].containsKey(bucket.toLowerCase())) {
          var location = getLocation(curveDefs['location']);
          var bucketNames = (curveDefs['bucketDefs'][bucket.toLowerCase()] as List).cast<String>();
          var buckets = bucketNames.map((name) => Bucket.parse(name));
          for (var i = 0; i < months.length; i++) {
            var month = Month.parse(months[i], fmt: _isoFmt, location: location);
            var hours = buckets.map((b) => b.countHours(month)).toList().cast<num>();
            var values = bucketNames.map((b) => data['buckets'][b][i] as num);
            one[months[i]] = weightedMean(values, hours);
          }
        }
      }
      out[bucket] = one;
    }

    return out;
  }

  /// Calculate the bucket prices for individual strips.  Return a Map of
  /// {bucket: {strip: value}} elements.
  /// [data] is the result of the _getForwardCurveBuckets
  /// If any of the strips aren't marked, don't return them.
  Future<Map<String,Map<String,num>>> _calculateBucketsStrips(String curveId,
      Map<String, Map<String,num>> data, List<String> strips) async {
    var out = <String,Map<String,num>>{};
    for (var bucket in data.keys) {
      var one = <String,num>{};
      var curveDef = curveDefinitions[curveId] ?? curveDefinitions['_'];
      var location = getLocation(curveDef['location']);
      var bucketObj = Bucket.parse(bucket);
      for (var term in strips) {
        try {
          var months = parseTerm(term.trim(), tzLocation: location)
              .splitLeft((dt) => Month.fromTZDateTime(dt));
          var values = months.map((month) => data[bucket][(month as Month).toIso8601String()]);
          var hours = months.map((month) => bucketObj.countHours(month));
          if (values.any((e) => e == null)) continue;
          one[term] = weightedMean(values, hours);
        } catch (e) {
          print(e);
        }
      }
      out[bucket] = one;
    }

    return out;
  }


}
