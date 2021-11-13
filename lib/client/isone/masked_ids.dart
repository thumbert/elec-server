library client.isone.masked_ids.v1;

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class IsoNewEnglandMaskedAssets {
  final String rootUrl;
  final String servicePath;

  IsoNewEnglandMaskedAssets(http.Client client,
      {this.rootUrl = 'http://localhost:8080',
      this.servicePath = '/isone_masked_ids/v1/'});

  /// Request parameters:
  ///
  /// [type] - can be one of 'generator', 'location', 'participant'
  ///
  Future<List<Map<String, dynamic>>> getAssets({String? type}) async {
    var _url;
    if (type == null) {
      _url = 'all';
    } else {
      _url = 'type/' + Uri.encodeComponent(type);
    }
    var _response = await http.get(Uri.parse(rootUrl + servicePath + _url));
    var data = json.decode(_response.body);
    return (data as List).cast<Map<String, dynamic>>();
  }
}
