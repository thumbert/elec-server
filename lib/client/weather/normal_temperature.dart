import 'dart:convert';
import 'package:http/http.dart' as http;

class NormalTemperature {
  NormalTemperature(this.client, {this.rootUrl = 'http://localhost:8080'});

  final http.Client client;
  final String rootUrl;
  final String servicePath = '/normal_temperature/v1/';

  /// Return normal temperatures 366 values for a given 3 letter [airportCode].
  /// For example, Boston is 'BOS'.  Temperature is in Fahrenheit.
  /// If the [airportCode] is not in the database, fail with null exception.
  /// These values are supposed to be 're-calibrated' on a periodic basis.
  Future<List<num>> getNormalTemperature(String airportCode) async {
    var url = '$rootUrl${servicePath}airport/$airportCode';
    var response = await client.get(Uri.parse(url));
    var xs = json.decode(response.body) as List;
    if (xs.isEmpty) return [];
    return (xs.first['normalTemperature'] as List).cast<num>();
  }
}
