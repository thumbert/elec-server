import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';

class PtidsApi {
  PtidsApi(http.Client client,
      {this.rootUrl = 'http://localhost:8000',
      this.servicePath = '/ptids/v1/'});

  final String rootUrl;
  final String servicePath;

  /// current ptid table cached
  Map<int, Map<String, dynamic>> _ptidTableCache = {};

  /// Get ptid table.
  /// [asOfDate] - Path parameter: 'asOfDate'.  If [null] return the last
  /// date in the database.
  /// [region] can be 'isone', 'nyiso', 'pjm'.
  /// Results are not really standardized between regions.  Typically, each
  /// element with contain the keys: 'ptid', 'name' and other ones.
  Future<List<Map<String, dynamic>>> getPtidTable(
      {Date? asOfDate, String region = 'isone'}) async {
    region = region.toLowerCase();
    var url = StringBuffer()..write(rootUrl);
    if (region != 'isone') {
      url.write('/');
      url.write(region.toLowerCase());
    }
    url.write(servicePath);
    if (asOfDate == null) {
      url.write('current');
    } else {
      url.write('asofdate/$asOfDate');
    }
    var response = await http.get(Uri.parse(url.toString()));
    return (json.decode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Date>> getAvailableAsOfDates() async {
    var url = '$rootUrl${servicePath}dates';
    var response = await http.get(Uri.parse(url));
    var aux = json.decode(response.body) as List;
    var x = aux.map((e) => Date.parse(e as String)).toList();
    return x;
  }

  /// Get all ptids for a given zone from the current table.
  /// Only  'All', 'MAINE', 'NH', 'VT', 'CT', 'RI', 'SEMA', 'WCMA', 'NEMA' are
  /// allowed for [zoneName]
  Future<List<int>> getPtidsForZone(String zoneName) async {
    if (_ptidTableCache.isEmpty) {
      var aux = await getPtidTable();
      _ptidTableCache = {for (var e in aux) e['ptid'] as int: e};
    }

    if (zoneName == 'All') {
      return _ptidTableCache.keys.toList();
    } else {
      var zonePtid = zoneMap[zoneName]!;
      var ptids = _ptidTableCache.entries
          .where((e) => e.value['zonePtid'] == zonePtid)
          .map((e) => e.value['ptid'] as int);
      return [zonePtid, ...ptids];
    }
  }
}

/// Go from a zone name to ptid, e.g. 'MAINE' -> 4001, 'WCMA' -> 4007
const Map<String, int> zoneMap = {
  'MAINE': 4001,
  'NH': 4002,
  'VT': 4003,
  'CT': 4004,
  'RI': 4005,
  'SEMA': 4006,
  'WCMA': 4007,
  'NEMA': 4008
};
