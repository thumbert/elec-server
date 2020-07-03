library client.marks.curves.curve_id;

import 'dart:convert';
import 'package:http/http.dart' as http;

class CurveIdClient {
  String rootUrl;
  String servicePath;

  CurveIdClient(http.Client client,
      {this.rootUrl = 'http://localhost:8080/',
      this.servicePath = 'curve_ids/v1/'});

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

  Future<List<Map<String, dynamic>>> electricityDocuments(
      String region, String serviceType) async {
    var _url = rootUrl + servicePath + 'commodity/electricity/region';
    '/$region/serviceType/$serviceType';
    var _response = await http.get(_url);
    var data = json.decode(_response.body);
    return (json.decode(data['result']) as List).cast<Map<String, dynamic>>();
  }
}
