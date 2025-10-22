import 'dart:convert';
import 'package:http/http.dart' as http;

class CurveIdClient {
  String rootUrl;
  String servicePath;

  CurveIdClient(http.Client client,
      {this.rootUrl = 'http://localhost:8000',
      this.servicePath = '/curve_ids/v1/'});

  /// Get all curveIds in the database.
  Future<List<String>> curveIds({String? pattern}) async {
    var url = '$rootUrl${servicePath}curveIds';
    if (pattern != null) {
      url += '/pattern/$pattern';
    }
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    return data.cast<String>();
  }

  /// Get all commodities.
  Future<List<String>> commodities() async {
    var url = '$rootUrl${servicePath}commodities';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    return data.cast<String>();
  }

  /// Get all regions.
  Future<List<String>> regions(String commodity) async {
    var url = '$rootUrl${servicePath}commodity/$commodity/regions';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    return data.cast<String>();
  }

  /// Get all serviceTypes.
  /// As of 2021-05, some curves don't have serviceType specified, for example
  /// the hourlyShape curves.
  Future<List<String?>> serviceTypes(String commodity, String region) async {
    var url =
        '$rootUrl${servicePath}commodity/$commodity/region/$region/serviceTypes';
    var response = await http.get(Uri.parse(url));
    var data = json.decode(response.body) as List;
    return data.cast<String?>();
  }

  /// Get all electricity documents for a region, serviceType.
  Future<List<Map<String, dynamic>>> electricityDocuments(
      String region, String serviceType) async {
    var url =
        '$rootUrl${servicePath}data/commodity/electricity/region/$region/serviceType/$serviceType';
    var response = await http.get(Uri.parse(url));
    return (json.decode(response.body) as List).cast<Map<String, dynamic>>();
  }

  /// Get one curveId document.  If it doesn't exist return an empty Map.
  Future<Map<String, dynamic>> getCurveId(String curveId) async {
    var url = '$rootUrl${servicePath}data/curveId/$curveId';
    var response = await http.get(Uri.parse(url));
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Get several curveId documents
  Future<List<Map<String, dynamic>>> getCurveIds(List<String> curveIds) async {
    var ids = curveIds.join('|');
    var url = '$rootUrl${servicePath}data/curveIds/$ids';
    var response = await http.get(Uri.parse(url));
    return (json.decode(response.body) as List).cast<Map<String, dynamic>>();
  }
}
