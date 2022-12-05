library db.utilities.eversource.rate_board;

import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:elec_server/client/utilities/retail_offers/retail_supply_offer.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:timezone/timezone.dart';

final _config = <Map<String, dynamic>>[
  {
    'state': 'CT',
    'queries': [
      {
        'customerClass[]': '1206',
        'monthlyUsage': '2000',
        'planType': 'ES Rate 30',
        'planTypeEdc[]': '1191',
      },
      {
        'customerClass[]': '1206',
        'monthlyUsage': '2000',
        'planType': 'ES Rate 35',
        'planTypeEdc[]': '1191',
      },
      {
        'customerClass[]': '1201',
        'monthlyUsage': '750',
        'planTypeEdc[]': '1191',
      },
      {
        'customerClass[]': '1206',
        'monthlyUsage': '2000',
        'planType': 'UI Rate GS',
        'planTypeEdc[]': '1196',
      },
      {
        'customerClass[]': '1206',
        'monthlyUsage': '2000',
        'planType': 'UI Rate GST',
        'planTypeEdc[]': '1196',
      },
      {
        'customerClass[]': '1201',
        'monthlyUsage': '750',
        'planType': 'UI Rate R',
        'planTypeEdc[]': '1196',
      },
      {
        'customerClass[]': '1201',
        'monthlyUsage': '750',
        'planType': 'UI Rate RT',
        'planTypeEdc[]': '1196',
      },
    ],
  },
];

class RetailSuppliersOffersArchive extends IsoExpressReport {
  RetailSuppliersOffersArchive({ComponentConfig? dbConfig}) {
    this.dbConfig = dbConfig ??
        ComponentConfig(
            host: '127.0.0.1',
            dbName: 'retail_suppliers',
            collectionName: 'historical_offers');
    dir = '$baseDir../RateBoardOffers/Raw/';
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
  }

  /// Currently only for CT, implement other states too
  /// Write the offers as json file
  /// https://energizect.com/rate-board/compare-energy-supplier-rates?customerClass=1201&monthlyUsage=750&planTypeEdc=1191
  Future<void> saveCurrentRatesToFile() async {
    /// for CT
    var allOffers = <Map<String, dynamic>>[];
    var queries =
        _config.firstWhere((e) => e['state'] == 'CT')['queries'] as List;
    for (var query in queries) {
      var url = Uri(
          scheme: 'https',
          host: 'energizect.com',
          path: '/ectr_search_api/offers',
          queryParameters: query);
      var res = await get(url);
      if (res.statusCode != 200) {
        throw StateError('Error downloading data from $url');
      }
      var aux = json.decode(res.body);
      var offers = (aux['results'] as List).cast<Map<String, dynamic>>();
      allOffers.addAll(offers);
    }
    var file = File(join(dir, '${Date.today(location: UTC)}_ct.json'));
    file.writeAsStringSync(json.encode(allOffers));
  }

  /// Only insert if there is a new [offerId] which is not in the database
  /// already.
  ///
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    var aux = await dbConfig.coll.distinct('offerId');
    var existingOfferIds = <String>{...aux['values']};

    var offerIds = data.map((e) => e['offerId']).toSet();
    var offersToInsert = offerIds.difference(existingOfferIds);
    if (offersToInsert.isNotEmpty) {
      try {
        for (var x in data.where((e) => offersToInsert.contains(e['offerId']))) {
          await dbConfig.coll.insert(x);
        }
        print('--->  Inserted new offers successfully');
      } catch (e) {
        print('XXX $e');
        return Future.value(1);
      }
    } else {
      print('No new competitive offers to insert');
    }
    return Future.value(0);
  }



  /// Return *unique* offers data ready to insert into Mongo
  @override
  List<Map<String, dynamic>> processFile(File file) {
    var data = json.decode(file.readAsStringSync()) as List;

    // Sometimes the offers are not unique in the file.  Upload only one
    var offers = <RetailSupplyOffer>{};
    for (var one in data) {
      if (basename(file.path).endsWith('_ct.json')) {
        offers.add(CtSupplyOffer.fromRawData(one));
      } else {
        throw StateError('File ${basename(file.path)} not supported yet');
      }
    }
    return offers.map((e) => e.toMongo()).toList();
  }

  @override
  Future<void> setupDb() async {
    await dbConfig.db.open();
    await dbConfig.db.createIndex(dbConfig.collectionName,
        keys: {'offerId': 1}, unique: true);
    await dbConfig.db.createIndex(dbConfig.collectionName, keys: {'region': 1});
    await dbConfig.db.close();
  }

  @override
  Map<String, dynamic> converter(List<Map<String, dynamic>> rows) {
    // TODO: implement converter
    throw UnimplementedError();
  }
}
