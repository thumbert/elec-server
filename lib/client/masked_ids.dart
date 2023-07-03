library client.isone.masked_ids.v1;

import 'dart:convert';
import 'dart:async';
import 'package:elec/elec.dart';
import 'package:http/http.dart' as http;

class MaskedIds {
  final Iso iso;
  final String rootUrl;
  final String servicePath;

  MaskedIds(http.Client client,
      {required this.iso,
      this.rootUrl = 'http://localhost:8080',
      this.servicePath = '/masked_ids/v1/'}) {
    if (!_isoMap.keys.contains(iso)) {
      throw ArgumentError('Iso $iso is not supported');
    }
  }

  final _isoMap = <Iso, String>{
    Iso.newEngland: '/isone',
    Iso.newYork: '/nyiso',
  };

  /// Request parameters:
  ///
  /// [type] - can be one of 'generator', 'location', 'participant'
  ///
  Future<List<Map<String, dynamic>>> getAssets({String? type}) async {
    late String url;
    if (type == null) {
      url = 'all';
    } else {
      url = 'type/${Uri.encodeComponent(type)}';
    }
    var response =
        await http.get(Uri.parse(rootUrl + _isoMap[iso]! + servicePath + url));
    var data = json.decode(response.body);
    return (data as List).cast<Map<String, dynamic>>();
  }
}
