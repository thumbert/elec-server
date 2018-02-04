library api.isone_energyoffers;

import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:more/ordering.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';

@ApiClass(name: 'da_energy_offers', version: 'v1')
class DaEnergyOffers {
  DbCollection coll;
  Location location;
  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
  String collectionName = 'da_energy_offer';
  Ordering ordering;

  DaEnergyOffers(Db db) {
    coll = db.collection(collectionName);
    location = getLocation('US/Eastern');
    /// create an ordering by price and assetId to use when sorting the stack
    var natural = new Ordering.natural();
    var byPrice = natural.onResultOf((Map e) => e['price']);
    var byAssetId = natural.onResultOf((Map e) => e['assetId']);
    ordering = byPrice.compound(byAssetId);
  }

  //http://localhost:8080/da_energy_offers/v1/stack/date/20170701/hourending/16
  @ApiMethod(path: 'stack/date/{date}/hourending/{hourending}')
  /// return the stack
  Future<List<Map<String,String>>> getGenerationStack(String date, String hourending) async {
    var stack = [];
    List eo = await getEnergyOffers(date, hourending);
    /// get rid of the unavailable units (some still submit offers!), and make
    /// the must run units have $-150 prices in the first block only.
    var gEo = _groupBy(eo.where((Map e) => e['Unit Status'] != 'UNAVAILABLE'),
        (Map e) => e['assetId']);
    gEo.keys.forEach((assetId) {
      List offers = gEo[assetId];
      if (offers.first['Unit Status'] == 'MUST_RUN') {
        /// need to sort them just in case ...
        offers.sort((a,b) => a['price'].compareTo(b['price']));
        offers.first['price'] = -150;
      }
      stack.addAll(offers);
    });
    ordering.sort(stack);
    num cumMWh = 0;
    stack.forEach((Map e) {
      cumMWh += e['quantity'];
      e['cumulative qty'] = cumMWh;
    });
    return stack;
  }

  //http://localhost:8080/da_energy_offers/v1/date/20170701/hourending/16
  @ApiMethod(path: 'date/{date}/hourending/{hourending}')
  /// Return the energy offers (price/quantity pairs) for a given datetime.
  Future<List<Map<String, String>>> getEnergyOffers(String date, String hourending) async {
    if (hourending.length == 1)
      hourending = hourending.padLeft(2, '0');
    Date day = Date.parse(date);
    TZDateTime dt = parseHourEndingStamp(mmddyyyy(day), hourending);
    List pipeline = [];
    Map match = {
      'date': {
        '\$eq': day.toString(),
      }
    };
    Map project = {
      '_id': 0,
      'Masked Asset ID': 1,
      'Unit Status': 1,
      'hours': {
        '\$filter': {
          'input': '\$hours',
          'as': 'hour',
          'cond': {'\$eq': ['\$\$hour.hourBeginning', dt]}
        }
      },
    };
    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    pipeline.add({'\$unwind': '\$hours'});
    var res = coll.aggregateToStream(pipeline);
    /// flatten the map in Dart
    List out = [];
    List keys = ['assetId', 'Unit Status', 'hourBeginning', 'price', 'quantity'];
    await for (Map e in res) {
      //print(e);
      List prices = e['hours']['price'];
      for (int i=0; i<prices.length; i++) {
        out.add(new Map.fromIterables(keys, [
          e['Masked Asset ID'],
          e['Unit Status'],
          new TZDateTime.from(e['hours']['hourBeginning'], location).toString(),
          e['hours']['price'][i],
          e['hours']['quantity'][i]
        ]));
      }
    }
    return out;
  }

  //http://localhost:8080/da_energy_offers/v1/assetId/41406/variable/Economic Maximum/start/20170701/end/20171001
  @ApiMethod(path: 'assetId/{assetId}/variable/{variable}/start/{start}/end/{end}')
  /// Get one variable between a start and end date for one asset.
  Future<List<Map<String, String>>> oneAssetVariable(String assetId,
      String variable, String start, String end) async {
    List pipeline = [];
    Map match = {
      'date': {
        '\$gte': Date.parse(start).toString(),
        '\$lte': Date.parse(end).toString(),
      },
      'Masked Asset ID': {
        '\$eq': int.parse(assetId)
      }
    };
    Map project = {
      '_id': 0,
      'date': 1,
    };
    project[variable] = 1;
    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    pipeline.add({
      '\$sort': {'date': 1}
    });
    return coll.aggregateToStream(pipeline).toList();
  }


  //http://localhost:8080/da_energy_offers/v1/variable/Economic Maximum/start/20170701/end/20171001
  @ApiMethod(path: 'variable/{variable}/start/{start}/end/{end}')
  /// Get a variable between a start and end date for all the assets.
  Future<List<Map<String, String>>> oneVariable(
      String variable, String start, String end) async {
    List pipeline = [];
    Map match = {
      'date': {
        '\$gte': Date.parse(start).toString(),
        '\$lte': Date.parse(end).toString(),
      }
    };
    Map project = {
      '_id': 0,
      'date': 1,
      'Masked Asset ID': 1,
    };
    project[variable] = 1;
    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    pipeline.add({
      '\$sort': {'date': 1}
    });
    return coll.aggregateToStream(pipeline).toList();
  }

  //http://localhost:8080/da_energy_offers/v1/daily_data/day/20170701
  @ApiMethod(path: 'daily_data/day/{day}')
  Future<List<Map<String, String>>> dailyData(String day) async {
    List pipeline = [];
    Map match = {
      'date': {
        '\$eq': Date.parse(day).toString(),
      }
    };
    Map project = {
      '_id': 0,
      'date': 1,
      'Masked Asset ID': 1,
      'Must Take Energy': 1,
      'Maximum Daily Energy Available': 1,
      'Economic Maximum': 1,
      'Economic Minimum': 1,
      'Cold Startup Price': 1,
      'Intermediate Startup Price': 1,
      'Hot Startup Price': 1,
      'No Load Price': 1,
      'Unit Status': 1,
      'Claim 10': 1,
      'Claim 30': 1,
    };
    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    pipeline.add({
      '\$sort': {'date': 1}
    });
    return coll.aggregateToStream(pipeline).toList();
  }

  /// http://localhost:8080/da_energy_offers/v1/assets/day/20170301
  @ApiMethod(path: 'assets/day/{day}')
  Future<List<Map<String, String>>> assetsByDay(String day) async {
    List pipeline = [];
    Map match = {
      'date': {'\$eq': Date.parse(day).toString()}
    };
    Map project = {
      '_id': 0,
      'Masked Asset ID': 1,
      'Masked Lead Participant ID': 1
    };
    pipeline.add({'\$match': match});
    pipeline.add({'\$project': project});
    return coll.aggregateToStream(pipeline).toList();
  }


}


Map _groupBy(Iterable x, Function f) {
  Map result = new Map();
  x.forEach((v) => result.putIfAbsent(f(v), () => []).add(v));
  return result;
}
