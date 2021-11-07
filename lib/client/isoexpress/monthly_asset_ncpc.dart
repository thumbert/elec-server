library client.isoexpress.monthly_ncpc_asset;

import 'dart:convert';

import 'package:date/date.dart';
import 'package:dama/dama.dart';
import 'package:elec/risk_system.dart';
import 'package:http/http.dart' as http;
import 'package:table/table.dart';

class MonthlyAssetNcpc {
  MonthlyAssetNcpc(this.client,
      {this.rootUrl = 'http://localhost:8000',
      this.servicePath = '/monthly_asset_ncpc/v1/'});

  final http.Client client;
  final String rootUrl;
  final String servicePath;

  /// Return data in the form
  /// ```
  ///  {
  ///    'month': '2021-01',
  ///    'assetId': 321,
  ///    'name': 'MANCHESTER 10/10A CC',
  ///    'zoneId': 4005,
  ///    'market': Market.da,
  ///    'value': 0,
  ///  }, ...
  /// ```
  Future<List<Map<String, dynamic>>> getAllAssets(
      Month start, Month end) async {
    var _url = rootUrl +
        servicePath +
        'all/start/${start.toIso8601String()}'
            '/end/${end.toIso8601String()}';

    var _response = await client.get(Uri.parse(_url));
    var xs = (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
    // denormalize the table
    var out = <Map<String, dynamic>>[];
    for (var x in xs) {
      var daNcpc = x.remove('daNcpc');
      var rtNcpc = x.remove('rtNcpc');
      out.add({
        ...x,
        'market': Market.da,
        'value': daNcpc,
      });
      out.add({
        ...x,
        'market': Market.rt,
        'value': rtNcpc,
      });
    }
    return out;
  }

  /// Summarize the data according to some filters and checkboxes.
  /// For example if the filter [zoneId] is null, it means all zones,
  /// if the checkbox [byZoneId] is true, it will aggregate the data by zone, etc.
  /// Valid zone values are: 'Maine', 'NH', 'VT', ... , 'WCMA', 'NEMA'.
  ///
  List<Map<String, dynamic>> summary(Iterable<Map<String, dynamic>> data,
      {int? zoneId,
      bool byZoneId = false,
      Market? market,
      bool byMarket = false,
      String? assetName,
      bool byAssetName = false,
      bool byMonth = false}) {
    var levelNames = <String>[];
    var nest = Nest();
    if (byZoneId) {
      nest.key((e) => e['zoneId']);
      levelNames.add('zone');
    }
    if (byMarket) {
      nest.key((e) => e['market']);
      levelNames.add('market');
    }
    if (byAssetName) {
      nest.key((e) => e['name']);
      levelNames.add('name');
    }
    if (byMonth) {
      nest.key((e) => e['month']);
      levelNames.add('month');
    }
    if (zoneId != null) {
      data = data.where((e) => e['zoneId'] == zoneId);
    }
    if (market != null) {
      data = data.where((e) => e['market'] == market);
    }
    if (assetName != null) {
      data = data.where((e) => e['name'] == assetName);
    }
    nest.rollup((List xs) => sum(xs.map((e) => e['value'] as num)).round());
    var aux = nest.map(data.toList());

    List<Map<String, dynamic>> out;
    if (levelNames.isNotEmpty) {
      out = flattenMap(aux, levelNames..add('value'))!;
    } else {
      out = [
        {'value': aux}
      ];
    }

    return out;
  }
}
