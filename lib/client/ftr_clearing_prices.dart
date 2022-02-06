library client.ftr_clearing_prices.v1;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:elec/elec.dart';

/// A Dart client for pulling FTR/TCC clearing prices from Mongo supporting
/// several regions.
class FtrClearingPrices {
  final String rootUrl;
  final Iso iso;

  FtrClearingPrices(http.Client client,
      {required this.iso, this.rootUrl = 'http://localhost:8080'});

  final _isoMap = <Iso, String>{
    Iso.newEngland: '/isone/ftr_clearing_prices/v1',
    Iso.newYork: '/nyiso/tcc_clearing_prices/v1',
  };

  /// Get all clearing prices for all auctions in the database for one ptid
  /// Return a list with elements
  /// ```
  /// {
  ///   'auctionName': 'X21-6M-R5',
  ///   'bucket': '7x24',
  ///   'clearingPriceHour': 3.98567,
  /// }
  /// ```
  /// The clearing price is in $/MWh, ATC
  Future<List<Map<String, dynamic>>> getClearingPricesForPtid(int ptid) async {
    var _url = rootUrl + _isoMap[iso]! + '/ptid/$ptid';

    var _response = await http.get(Uri.parse(_url));
    var data = json.decode(_response.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  /// Get all clearing prices for all auctions in the database for several
  /// ptids.  Probably you should limit the number of ptids to less than 30.
  /// At some point the url becomes too long!
  ///
  /// Return a list with elements
  /// ```
  /// {
  ///   'ptid': 61752,
  ///   'auctionName': 'X21-6M-R5',
  ///   'bucket': '7x24',
  ///   'clearingPriceHour': 3.98567,
  /// }
  /// ```
  /// The clearing price is in $/MWh, ATC
  Future<List<Map<String, dynamic>>> getClearingPricesForPtids(
      List<int> ptids) async {
    var _url = rootUrl + _isoMap[iso]! + '/ptids/${ptids.join(',')}';

    var _response = await http.get(Uri.parse(_url));
    var data = json.decode(_response.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  /// Get the clearing price for one auction for all the nodes in the pool.
  /// Return a list of Map of this form
  /// ```
  /// {
  ///   'ptid': 61752,
  ///   'auctionName': 'X21-6M-R5',
  ///   'bucket': '7x24',
  ///   'clearingPriceHour': 3.98567,
  /// }, ...
  /// ```
  /// The clearing price is in $/MWh, ATC

  Future<List<Map<String, dynamic>>> getClearingPricesForAuction(
      String auctionName) async {
    var _url = rootUrl + _isoMap[iso]! + '/auction/$auctionName';

    var _response = await http.get(Uri.parse(_url));
    var data = json.decode(_response.body) as List;
    return data.cast<Map<String, dynamic>>();
  }
}
