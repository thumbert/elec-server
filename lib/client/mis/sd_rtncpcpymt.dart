library client.mis.sd_rtncpcpymnt;

import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

class SdRtNcpcPymnt {
  String rootUrl;
  String servicePath;
  final location = getLocation('America/New_York');

  SdRtNcpcPymnt(http.Client client,
      {this.rootUrl = 'http://localhost:8080/',
      this.servicePath = 'sd_rtncpcpymt/v1/'});

  /// Get details for all generators between a start/end date.
  Future<List<Map<String, dynamic>>> getPaymentsForAllGenerators(
      String accountId, Date start, Date end,
      {int settlement = 99}) async {
    var _url = rootUrl +
        servicePath +
        'accountId/{accountId}/details' +
        '/start/${start.toString()}/end/${end.toString()}';

    var _response = await http.get(Uri.parse(_url));
    var aux = json.decode(_response.body);
    var data = (json.decode(aux['result']) as List).cast<Map<String, dynamic>>();

    var grp = groupBy(data, (dynamic e) => e['Asset ID']);
    // TODO:  use (e) => Tuple2(e['Asset ID'], e['date'])
    var out = <Map<String,dynamic>>[];
    for (var assetId in grp.keys) {
      out.addAll(getNthSettlement(grp[assetId]!, (e) => e['date'],  n: settlement));
    }

    return out;
  }
}
