// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: unnecessary_cast

library elec_server.da_energy_offer.v1;

import 'dart:async';
import 'dart:convert';
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

const String USER_AGENT = 'dart-api-client da_energy_offer/v1';

class DaEnergyOffers {
  static final location = getLocation('US/Eastern');
  String rootUrl;
  String servicePath;

  DaEnergyOffers(http.Client client, {this.rootUrl: "http://localhost:8080/",
      this.servicePath: "da_energy_offers/v1/"});

  /// Get all the energy offers for a given hour.  All assets.
  Future<List<Map<String,dynamic>>> getDaEnergyOffers(Hour hour) async {
    var aux = toIsoHourEndingStamp(hour.start);
    var startDate = aux[0];
    var hourEnding = aux[1];
    var _url = rootUrl + servicePath + 'date/' +
        commons.Escaper.ecapeVariable('${startDate}') +
        '/hourending/' +
        commons.Escaper.ecapeVariable('${hourEnding}');

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    var out = (json.decode(data['result']) as List).cast<Map<String,dynamic>>();

    return out;
  }

  /// Get the energy offers of an asset between a start/end date
  Future<List<Map<String, dynamic>>> getDaEnergyOffersForAsset(
      int maskedAssetId, Date start, Date end) async {
    var _url =  rootUrl + servicePath + 'assetId/${maskedAssetId.toString()}' +
        '/start/' +
        commons.Escaper.ecapeVariable('${start.toString()}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toString()}');

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    var out = (json.decode(data['result']) as List).cast<Map<String,dynamic>>();
    out.forEach((e) {
      e['hours'] = json.decode(e['hours']);
    });
    return out;
  }

  /// Get the generation stack for this hour
  Future<List<Map<String, dynamic>>> getGenerationStack(Hour hour) async {
    var aux = toIsoHourEndingStamp(hour.start);
    var startDate = aux[0];
    var hourEnding = aux[1];
    var _url = rootUrl + servicePath + 'stack/date/' +
        commons.Escaper.ecapeVariable('${startDate}') +
        '/hourending/' +
        commons.Escaper.ecapeVariable('${hourEnding}');

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    return (json.decode(data['result']) as List).cast<Map<String,dynamic>>();
  }

  /// Get the masked asset id and the masked participant id for this date.
  Future<List<Map<String, dynamic>>> assetsForDay(Date date) async {
    var _url =  rootUrl + servicePath + 'assets/day/'
        + commons.Escaper.ecapeVariable('${date.toString()}');
    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    return (json.decode(data['result']) as List).cast<Map<String,dynamic>>();
  }

  /// Get the masked asset ids of a masked participant id between a start and end date.
  Future<List<Map<String, dynamic>>> assetsForParticipantId(
      int maskedParticipantId, Date start, Date end) async {
    var _url = rootUrl + servicePath +
        'assets/participantId/${maskedParticipantId}' + '/start/' +
        commons.Escaper.ecapeVariable('${start.toString()}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toString()}');

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    return (json.decode(data['result']) as List).cast<Map<String,dynamic>>();
  }

  /// Get the daily variable between a start/end date
  Future<List<Map<String, dynamic>>> dailyVariable(String variable, Date start,
      Date end) async {
    var _url = rootUrl + servicePath + 'daily/variable/' +
        commons.Escaper.ecapeVariable('${variable}') +
        '/start/' +
        commons.Escaper.ecapeVariable('${start.toString()}') +
        '/end/' +
        commons.Escaper.ecapeVariable('${end.toString()}');

    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    return (json.decode(data['result']) as List).cast<Map<String,dynamic>>();
  }


  /// Get the last date inserted in the database
  Future<Date> lastDate() async {
    var _url = rootUrl + servicePath + 'lastday';
    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    return Date.parse(json.decode(data['result']));
  }
}

/// Take the historical energy offers of an asset as returned by
/// [getDaEnergyOffersForAsset] and create the timeseries of price offers.
/// First offer point for each hour forms the first TimeSeries, etc.
///
List<TimeSeries<Map<String, num>>> priceQuantityOffers(
    List<Map<String, dynamic>> energyOffers) {
  var out = <TimeSeries<Map<String, num>>>[];
  for (var row in energyOffers) {
    if (row['Unit Status'] == 'UNAVAILABLE') continue;
    var hourlyOffers = (row['hours'] as List).cast<Map<String, dynamic>>();
    for (var hourlyOffer in hourlyOffers) {
      int n = hourlyOffer['price'].length;
      while (n > out.length) {
        out.add(TimeSeries<Map<String, num>>());
      }
      var hour = Hour.beginning(TZDateTime.parse(
          DaEnergyOffers.location, hourlyOffer['hourBeginning']));
      for (int i = 0; i < n; i++) {
        out[i].add(IntervalTuple(hour, {
          'price': hourlyOffer['price'][i],
          'quantity': hourlyOffer['quantity'][i],
        }));
      }
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

  /// all pqOffers TimeSeries don't always have the same length need to merge
  var out = pqOffers.reduce((x,y) {
    var z = x.merge(y, joinType: JoinType.Outer, f: (a,b) {
      a ??= {'price': 0, 'quantity': 0};
      b ??= {'price': 0, 'quantity': 0};
      var totalQ = a['quantity'] + b['quantity'];
      return {
        'price': (a['price']*a['quantity'] + b['price']*b['quantity'])/totalQ,
        'quantity': totalQ,
      };
    });
    return z;
  });


  return out;
}
