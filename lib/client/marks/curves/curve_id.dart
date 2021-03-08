library client.marks.curves.curve_id;

import 'dart:convert';
import 'package:http/http.dart' as http;

class CurveIdClient {
  String rootUrl;
  String servicePath;

  CurveIdClient(http.Client client,
      {this.rootUrl = 'http://localhost:8000',
      this.servicePath = '/curve_ids/v1/'});

  /// Get all curveIds in the database.
  Future<List<String>> curveIds({String pattern}) async {
    var _url = rootUrl + servicePath + 'curveIds';
    if (pattern != null) {
      _url += '/pattern/$pattern';
    }
    var _response = await http.get(_url);
    var data = json.decode(_response.body) as List;
    return data.cast<String>();
  }

  /// Get all commodities.
  Future<List<String>> commodities() async {
    var _url = rootUrl + servicePath + 'commodities';
    var _response = await http.get(_url);
    var data = json.decode(_response.body) as List;
    return data.cast<String>();
  }

  /// Get all regions.
  Future<List<String>> regions(String commodity) async {
    var _url = rootUrl + servicePath + 'commodity/$commodity/regions';
    var _response = await http.get(_url);
    var data = json.decode(_response.body) as List;
    return data.cast<String>();
  }

  /// Get all serviceTypes.
  Future<List<String>> serviceTypes(String commodity, String region) async {
    var _url = rootUrl +
        servicePath +
        'commodity/$commodity/region/$region/serviceTypes';
    var _response = await http.get(_url);
    var data = json.decode(_response.body) as List;
    return data.cast<String>();
  }

  /// Get all electricity documents for a region, serviceType.
  Future<List<Map<String, dynamic>>> electricityDocuments(
      String region, String serviceType) async {
    var _url = rootUrl +
        servicePath +
        'data/commodity/electricity/region'
            '/$region/serviceType/$serviceType';
    var _response = await http.get(_url);
    return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
  }

  /// Get one curveId document
  Future<Map<String, dynamic>> getCurveId(String curveId) async {
    var _url = rootUrl + servicePath + 'data/curveId/$curveId';
    var _response = await http.get(_url);
    return json.decode(_response.body) as Map<String, dynamic>;
  }

  /// Get several curveId documents
  Future<List<Map<String, dynamic>>> getCurveIds(List<String> curveIds) async {
    var _ids = curveIds.join('|');
    var _url = rootUrl + servicePath + 'data/curveIds/$_ids';
    var _response = await http.get(_url);
    return (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
  }
}
