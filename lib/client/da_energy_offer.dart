import 'dart:async';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';

/// Get the data from the server that uses DuckDB.
///
/// Each element of returned [offers] is in this form for ISONE:
/// ```dart
/// {
///   'masked_asset_id': 75431,
///   'unit_status': 'Economic',
///   'timestamp_s': 1672549200,
///   'segment': 0,
///   'quantity': 21.3,
///   'price': -120.0,
/// }
/// ```
///
///
/// and this for NYISO:
/// ```dart
/// {
///   "masked_asset_id": 35537750,
///   "timestamp_s": 1709269200,
///   "segment": 0,
///   "price": 15.6,
///   "quantity": 150
/// },
/// ```
///
Future<List<Map<String, dynamic>>> getEnergyOffers(
    {required Iso iso,
    required Market market,
    required Term term,
    required List<int> maskedAssetIds,
    required String rootUrl}) async {
  final mkt = switch (iso.name) {
    'ISONE' => switch (market) {
        Market.da => 'da',
        Market.rt => 'rt',
        _ => throw StateError('Market $market is not supported'),
      },
    'NYISO' => switch (market) {
        Market.da => 'dam',
        Market.rt => 'ham',
        _ => throw StateError('Market $market is not supported'),
      },
    _ => throw ArgumentError('ISO $iso not supported yet!')
  };
  final url = [
    '$rootUrl/${iso.name.toLowerCase()}',
    '/energy_offers/$mkt',
    '/start/${term.startDate}/end/${term.endDate}',
    if (maskedAssetIds.isNotEmpty)
      '?masked_asset_ids=${maskedAssetIds.join(',')}'
  ].join();
  var aux = await http.get(Uri.parse(url));
  var offers = (json.decode(aux.body) as List).cast<Map<String, dynamic>>();
  return offers;
}

/// Each element looks something like this for ISONE:
/// ```dart
///{
///   "masked_asset_id": 42103,
///   "unit_status": "MustRun",
///   "timestamp_s": 1709269200,
///   "segment": 0,
///   "price": -150,
///   "quantity": 8
/// },
///```
///
/// And like this for NYISO:
/// ```dart
///{
///   "masked_asset_id": 90926750,
///   "timestamp_s": 1709269200,
///   "segment": 0,
///   "price": -1000,
///   "quantity": 9
/// },
///```
///
Future<List<Map<String, dynamic>>> getStack(
    {required Iso iso,
    required Market market,
    required List<TZDateTime> hourBeginning,
    required String rootUrl}) async {
  final mkt = switch (iso.name) {
    'ISONE' => switch (market) {
        Market.da => 'da',
        Market.rt => 'rt',
        _ => throw StateError('Market $market is not supported'),
      },
    'NYISO' => switch (market) {
        Market.da => 'dam',
        Market.rt => 'ham',
        _ => throw StateError('Market $market is not supported'),
      },
    _ => throw ArgumentError('ISO $iso not supported yet!')
  };
  final timestamps = hourBeginning
      .map((e) => (e.millisecondsSinceEpoch / 1000).round())
      .join(',');
  final url = [
    '$rootUrl/${iso.name.toLowerCase()}',
    '/energy_offers/$mkt',
    '/stack/timestamps/$timestamps',
  ].join();
  var aux = await http.get(Uri.parse(url));
  var stack = (json.decode(aux.body) as List).cast<Map<String, dynamic>>();
  return stack;
}

/// Given the offers from ONE unit, create a list of timeseries associated
/// with each offer segment.  So, first element of the list is the timeseries
/// from segment 0 offers, etc.
///
/// Each element of [offers] is in this form:
/// ```dart
/// {
///   'masked_asset_id': 75431,
///   'unit_status': 'Economic',
///   'timestamp_s': 1672549200,
///   'segment': 0,
///   'quantity': 21.3,
///   'price': -120.0,
/// }
/// ```
/// Skip over elements with 'unit_status' == 'Unavailable'.
///
///
List<TimeSeries<Map<String, num>>> makeTimeSeriesFromOffers(
    List<Map<String, dynamic>> offers, Iso iso) {
  var out = <TimeSeries<Map<String, num>>>[];
  if (iso == Iso.newEngland) {
    var groups = groupBy(offers, (e) => e['segment']);
    for (var segment in groups.keys) {
      var one = TimeSeries<Map<String, num>>();
      for (var e in groups[segment]!) {
        if (e['unit_status'] == 'Unavailable') continue;
        int millis = e['timestamp_s'] * 1000;
        var start = TZDateTime.fromMillisecondsSinceEpoch(
            IsoNewEngland.location, millis);
        one.add(IntervalTuple(Hour.beginning(start),
            {'quantity': e['quantity'], 'price': e['price']}));
      }
      out.add(one);
    }
    //
    //
  } else if (iso == Iso.newYork) {
    var groups = groupBy(offers, (e) => e['segment']);
    for (var segment in groups.keys) {
      var one = TimeSeries<Map<String, num>>();
      for (var e in groups[segment]!) {
        int millis = e['timestamp_s'] * 1000;
        var start = TZDateTime.fromMillisecondsSinceEpoch(
            IsoNewEngland.location, millis);
        one.add(IntervalTuple(Hour.beginning(start),
            {'quantity': e['quantity'], 'price': e['price']}));
      }
      out.add(one);
    }
    //
    //
  } else {
    throw ArgumentError('$iso is not supported yet');
  }
  return out;
}

@Deprecated('Please use the functionality built around DuckDb')
class DaEnergyOffers {
  static final location = getLocation('America/New_York');
  final Iso iso;
  String rootUrl;
  String servicePath;

  DaEnergyOffers(http.Client client,
      {required this.iso,
      this.rootUrl = 'http://localhost:8080/',
      this.servicePath = '/da_energy_offers/v1/'}) {
    if (!_isoMap.keys.contains(iso)) {
      throw ArgumentError('Iso $iso is not supported');
    }
  }

  final _isoMap = <Iso, String>{
    Iso.newEngland: '',
    Iso.newYork: '/nyiso',
  };

  /// Get all the energy offers for a given hour.  All assets.
  Future<List<Map<String, dynamic>>> getDaEnergyOffers(Hour hour) async {
    var date = Date.fromTZDateTime(hour.start);
    var hours = date.hours();
    var hourIndex = hours.indexWhere((e) => e == hour);
    var _url =
        '$rootUrl${_isoMap[iso]!}${servicePath}date/${date.toString()}/hourindex/$hourIndex';
    var _response = await http.get(Uri.parse(_url));
    var out =
        (json.decode(_response.body) as List).cast<Map<String, dynamic>>();

    return out;
  }

  /// Get the energy offers of an asset between a start/end date.
  /// Note that the segment prices are monotonically increasing, and that a
  /// segment quantity is incremental to the previous segment quantity.
  /// Return a list with elements containing at least
  /// ```
  /// {
  ///   'date': '2021-01-01',
  ///   'Masked Asset ID': <int>,
  ///   'Masked Participant ID': <int>,
  ///   'hours': [
  ///     {
  ///       'price': <num>[...],
  ///       'quantity': <num>[...],
  ///       ... // other fields too
  ///     }, ...
  ///   ]
  /// }
  /// ```
  Future<List<Map<String, dynamic>>> getDaEnergyOffersForAsset(
      int maskedAssetId, Date start, Date end) async {
    var _url =
        '$rootUrl${_isoMap[iso]!}${servicePath}assetId/${maskedAssetId.toString()}/start/${start.toString()}/end/${end.toString()}';
    var _response = await http.get(Uri.parse(_url));
    var out =
        (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
    for (var e in out) {
      e['hours'] = json.decode(e['hours']);
    }
    return out;
  }

  /// Get the generation stack for this hour.
  @Deprecated('Use getStack() from the same library!')
  Future<List<Map<String, dynamic>>> getGenerationStack(Hour hour) async {
    var date = Date.fromTZDateTime(hour.start);
    var hours = date.hours();
    var hourIndex = hours.indexWhere((e) => e == hour);
    var _url =
        '$rootUrl${_isoMap[iso]!}${servicePath}stack/date/${date.toString()}/hourindex/$hourIndex';

    var _response = await http.get(Uri.parse(_url));
    return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
  }

  /// Get the masked asset id and the masked participant id for this date.
  Future<List<Map<String, dynamic>>> assetsForDay(Date date) async {
    var _url =
        '$rootUrl${_isoMap[iso]!}${servicePath}assets/day/${date.toString()}';
    var _response = await http.get(Uri.parse(_url));
    return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
  }

  /// Get the masked asset ids of a masked participant id between a start and end date.
  Future<List<Map<String, dynamic>>> assetsForParticipantId(
      int maskedParticipantId, Date start, Date end) async {
    var _url =
        '$rootUrl${_isoMap[iso]!}${servicePath}assets/participantId/$maskedParticipantId/start/${start.toString()}/end/${end.toString()}';

    var _response = await http.get(Uri.parse(_url));
    return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
  }

  /// Get the daily variable between a start/end date
  Future<List<Map<String, dynamic>>> dailyVariable(
      String variable, Date start, Date end) async {
    var _url =
        '$rootUrl${_isoMap[iso]!}${servicePath}daily/variable/${Uri.decodeComponent(variable)}/start/${start.toString()}/end/${end.toString()}';

    var _response = await http.get(Uri.parse(_url));
    return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
  }
}

/// Take the historical energy offers of an asset as returned by
/// [getDaEnergyOffersForAsset] and create the timeseries of price offers.
/// First offer point for each hour forms the first TimeSeries, etc.
///
/// For ISONE, the quantity for segment 1 is incremental to the quantity in
/// segment 0, etc.  That is not the case for NYISO.  Process the data such that
/// the return timeseries for NYISO follow the same incremental convention.
///
List<TimeSeries<Map<String, num>>> priceQuantityOffers(
    List<Map<String, dynamic>> energyOffers,
    {required Iso iso}) {
  var out = <TimeSeries<Map<String, num>>>[];
  for (var row in energyOffers) {
    if (row['Unit Status'] == 'UNAVAILABLE') continue; // only in ISONE
    var hourlyOffers = (row['hours'] as List).cast<Map<String, dynamic>>();
    var hour = Hour.beginning(
        TZDateTime.parse(iso.preferredTimeZoneLocation, row['date']));
    for (var hourlyOffer in hourlyOffers) {
      int n = hourlyOffer['price'].length;
      while (n > out.length) {
        out.add(TimeSeries<Map<String, num>>());
      }
      out[0].add(IntervalTuple(hour, {
        'price': hourlyOffer['price'][0],
        'quantity': hourlyOffer['quantity'][0],
      }));
      for (var i = 1; i < n; i++) {
        out[i].add(IntervalTuple(hour, {
          'price': hourlyOffer['price'][i],
          'quantity': hourlyOffer['quantity'][i],
        }));
      }
      hour = hour.add(1);
    }
  }
  return out;
}

/// Calculate the quantity weighted average price of the offers.  This is a
/// convenient way to compare energy offers accross different power plants.
///
/// Input [pqOffers] is the output of the [priceQuantityOffers] function.
TimeSeries<Map<String, num>> averageOfferPrice(
    List<TimeSeries<Map<String, num>>> pqOffers) {
  if (pqOffers.isEmpty) return TimeSeries();

  /// all pqOffers TimeSeries don't always have the same length need to merge
  var out = pqOffers.reduce((x, y) {
    var z = x.merge(y, joinType: JoinType.Outer, f: (a, dynamic b) {
      a ??= {'price': 0, 'quantity': 0};
      b ??= {'price': 0, 'quantity': 0};
      var totalQ = a['quantity']! + b['quantity'];
      return {
        'price': (a['price']! * a['quantity']! + b['price'] * b['quantity']) /
            totalQ,
        'quantity': totalQ,
      };
    });
    return z;
  });

  return out;
}
