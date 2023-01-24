library db.utilities.eversource.rate_board;

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/db/config.dart';
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:elec_server/client/utilities/retail_offers/retail_supply_offer.dart';
import 'package:http/http.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:path/path.dart';
import 'package:timezone/timezone.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:html/parser.dart' show parse;

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
        // Eversource Residential plan, doesn't have a rate.
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
  {
    'state': 'MA',
    'queries': [
      {
        'stateId': '23', // MA
        'utilityId': '51', // Eversource NEMA
        'type': 'residential',
        'zip': '02110', // Boston
      },
      {
        'stateId': '23', // MA
        'utilityId': '51', // Eversource SEMA
        'type': 'residential',
        'zip': '02740', // New Bedford
      },
      {
        'stateId': '23', // MA
        'utilityId': '51', // Eversource WCMA
        'type': 'residential',
        'zip': '01128', // Springfield
      },
      {
        'stateId': '23', // MA
        'utilityId': '52', // NGrid NEMA
        'type': 'residential',
        'zip': '01936', // Hamilton
      },
      {
        'stateId': '23', // MA
        'utilityId': '52', // NGrid SEMA
        'type': 'residential',
        'zip': '02302', // Brockton
      },
      {
        'stateId': '23', // MA
        'utilityId': '59', // NGrid WCMA
        'type': 'residential',
        'zip': '01450', // Groton
      },
      {
        'stateId': '23', // MA
        'utilityId': '60', // Unitil WCMA
        'type': 'residential',
        'zip': '01462', // Lunenburg
      },
    ],
  },
];

void repairCtOfferFile(Date date) {
  var archive = RetailSuppliersOffersArchive();
  var file = File(join(archive.dir, '${date}_ct.json'));

  if (file.existsSync()) {
    var data = (json.decode(file.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    for (var e in data) {
      if (!e.containsKey('asOfDate')) {
        e['asOfDate'] = date.toString();
      }
    }

    /// The offers downloaded are not unique.  Save only a unique set to file
    var groups = groupBy(data, (Map e) => e['id']);
    var res = <Map<String, dynamic>>[];
    for (var xs in groups.values) {
      res.add(xs.first);
    }

    final js = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(js.convert(res));
  }
}

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

  Future<void> saveCurrentRatesToFile({List<String>? states}) async {
    states ??= ['CT', 'MA'];
    if (states.contains('CT')) await _getRatesCt();
    if (states.contains('MA')) await _getRatesMa();
  }

  /// Get the CT offers from the website and write the offers as json file
  /// https://energizect.com/rate-board/compare-energy-supplier-rates?customerClass=1201&monthlyUsage=750&planTypeEdc=1191
  /// https://energizect.com/ectr_search_api/offers?customerClass[]=1201&monthlyUsage=750&page=2&planTypeEdc[]=1191&
  /// https://energizect.com/ectr_search_api/offers?customerClass[]=1201&monthlyUsage=750&planTypeEdc[]=1196
  Future<void> _getRatesCt() async {
    var today = Date.today(location: UTC).toString();
    var allOffers = <Map<String, dynamic>>[];
    var queries =
        _config.firstWhere((e) => e['state'] == 'CT')['queries'] as List;
    for (Map<String,dynamic> query in queries) {
      for (var page = 1; page<10; page++) {
        query['page'] = page.toString();
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
        if (offers.isEmpty) {
          break;
        }

        var rateClass = '';
        if (query.containsKey('planType')) {
          rateClass = (query['planType'] as String).split(' ').last;
        }
        for (var e in offers) {
          e['asOfDate'] = today;
          e['rateClass'] = rateClass;
        }
        allOffers.addAll(offers);
      }
    }

    /// The offers downloaded are not unique.  Save only a unique set to file
    var groups = groupBy(allOffers, (Map e) => e['id']);
    var res = <Map<String, dynamic>>[];
    for (var xs in groups.values) {
      res.add(xs.first);
    }
    var file = File(join(dir, '${Date.today(location: UTC)}_ct.json'));
    final js = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(js.convert(res));

  }

  Future<void> _getRatesMa() async {
    await _getResidentialRatesMa();
    await _getSmallCommercialRatesMa();
  }

  /// Get residential rates in MA.
  Future<void> _getResidentialRatesMa() async {
    var allOffers = <Map<String, dynamic>>[];
    var queries =
        _config.firstWhere((e) => e['state'] == 'MA')['queries'] as List;

    var browser = await puppeteer.launch();
    var page = await browser.newPage();

    for (var query in queries) {
      print('Working on MA residential customers, utilityId: '
          '${utilityIdToUtility[query['utilityId']]}, zip: ${query['zip']}');
      await page.goto('https://www.massenergyrates.com');
      await page.select('select#utility_id', [query['utilityId']]);
      await page.select('select#type', ['residential']);
      await page.type('input#zip', query['zip']);
      await page.clickAndWaitForNavigation('.search-form-btn');
      var content = await page.content;
      var document = parse(content);

      var today = Date.today(location: UTC).toString();
      var offers = <Map<String, dynamic>>[];

      // /// Get the utility prevailing rate
      // var rate = document.querySelectorAll('input').first.attributes['value']!;
      // var utilityPlan = {
      //   'region': 'ISONE',
      //   'state': 'MA',
      //   'utility': utilityIdToUtility[query['utilityId']],
      //   'loadZone': zipToLoadzone[query['zip']],
      //   'accountType': 'Residential',
      //   'supplierName': utilityIdToUtility[query['utilityId']],
      //   'rate': num.parse(rate) * 10,
      //   'rateUnit': '\$/MWh',
      //   'planFeatures': 'Utility standard offer plan',
      // };
      // utilityPlan['offerId'] =
      //     'ma-${sha1.convert(utilityPlan.toString().codeUnits)}';
      // offers.add(utilityPlan);

      /// Get the competitive providers
      var table = document.querySelector('.energy-provider-table');
      var tbody = table!.querySelector('tbody');
      var rows = tbody!.querySelectorAll('tr');

      for (var row in rows) {
        var xs = row.querySelectorAll('td');
        var supplier = xs[0].querySelector('img')!.attributes['title'];
        var termDetails = xs[1].querySelector('span')!.text;
        var countOfCycles = int.parse(termDetails.split(' ').first);
        var planFeatures = xs[2]
            .children
            .expand((e) => e.text.trim().split('\n'))
            .where((e) => e != '')
            .toList();
        var rate =
            num.parse(xs[3].querySelector('span')!.text.split(' ').first) * 10;
        var one = {
          'region': 'ISONE',
          'state': 'MA',
          'utility': utilityIdToUtility[query['utilityId']],
          'loadZone': zipToLoadzone[query['zip']],
          'accountType': 'Residential',
          'rateClass': '',
          'countOfBillingCycles': countOfCycles,
          'offerType':
              termDetails.toLowerCase().contains('fixed') ? 'Fixed' : '?',
          'rate': rate,
          'rateUnit': '\$/MWh',
          'supplierName': supplier,
          'termDetails': termDetails,
          'planFeatures': planFeatures,
        };
        one['offerId'] = 'ma-${sha1.convert(one.toString().codeUnits)}';
        one['asOfDate'] = today;
        offers.add(one);
      }

      allOffers.addAll(offers);
    }
    await browser.close();

    var file =
        File(join(dir, '${Date.today(location: UTC)}_ma_residential.json'));
    final json = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(json.convert(allOffers));
  }

  /// 'small_commercial' customers have a different website than 'residential'
  /// https://www.massenergyrates.com/compare-mass-electricity-rates?ucd=NSTAR#/
  Future<void> _getSmallCommercialRatesMa() async {
    var allOffers = <Map<String, dynamic>>[];

    var file = File(
        join(dir, '${Date.today(location: UTC)}_ma_small_commercial.json'));
    if (allOffers.isNotEmpty) file.writeAsStringSync(json.encode(allOffers));
  }

  /// Input [data] needs to have the same 'state' and 'asOfDate' values for all
  /// elements.
  ///
  /// Only insert if there is a new [offerId] which is not in the database
  /// already.  Update already existing offers by incrementing the
  /// 'lastDateOnWebsite' field.
  ///
  @override
  Future<int> insertData(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return Future.value(0);
    var state = data.map((e) => e['state']).toSet();
    if (state.length != 1) {
      throw StateError('Only offers from 1 state at a time.  Found $state');
    }
    var asOf = data.map((e) => e['asOfDate']).toSet();
    if (asOf.length != 1) {
      throw StateError('Only offers from one asOfDate at a time.  Found $asOf');
    }
    String asOfDate = data.first['asOfDate'];

    /// TODO: get the existing offers for only this state!
    var aux = await dbConfig.coll.distinct('offerId');
    var allOfferIds = <String>{...aux['values']};
    if (allOfferIds.length > 100000) {
      print('WARNING:  Consider changing the algorithm.  Too many elements.');
    }

    var offerIds = data.map((e) => e['offerId']).toSet();
    var newOfferIds = offerIds.difference(allOfferIds);
    if (newOfferIds.isNotEmpty) {
      /// insert the new offers, also set the
      /// 'firstDateOnWebsite', 'lastDateOnWebsite' fields to current day
      try {
        var xs = data.where((e) => newOfferIds.contains(e['offerId'])).toList();
        for (var x in xs) {
          x['firstDateOnWebsite'] = x['asOfDate'];
          x['lastDateOnWebsite'] = x['asOfDate'];
          x.remove('asOfDate');
        }

        await dbConfig.coll.insertAll(xs);
        print(
            '--->  Inserted ${xs.length} new retail offers for ${state.first} successfully');
      } catch (e) {
        print('XXX $e');
        return Future.value(1);
      }
    } else {
      print('No new competitive retail offers to insert for ${state.first}');
    }

    /// Update the 'lastDateOnWebsite' field for all the exiting offers
    var existingOfferIds = offerIds.intersection(allOfferIds);
    if (existingOfferIds.isNotEmpty) {
      try {
        var query = where
          ..oneFrom('offerId', existingOfferIds.toList())
          ..excludeFields(['_id']);
        var docs = await dbConfig.coll.find(query).toList();
        for (var x in docs) {
          if (asOfDate.compareTo(x['lastDateOnWebsite']) == 1) {
            x['lastDateOnWebsite'] = asOfDate;
          }
        }
        await dbConfig.coll.remove(query);
        await dbConfig.coll.insertAll(docs);
      } catch (e) {
        print(
            'Error incrementing the lastDateOnWebsite field for existingOffers in ${state.first}');
      }
    }

    return Future.value(0);
  }

  @override
  List<Map<String, dynamic>> processFile(File file) {
    var data = json.decode(file.readAsStringSync()) as List;
    if (basename(file.path).endsWith('_ct.json')) {
      return data.map((e) => CtSupplyOffer.toMongo(e)).toList();
    } else if (basename(file.path).endsWith('_ma_residential.json')) {
      return data.cast<Map<String, dynamic>>();
    } else {
      throw StateError('File ${basename(file.path)} not supported yet');
    }
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
