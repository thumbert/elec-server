import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

class DaDemandBids {
  static final location = getLocation('America/New_York');
  String rootUrl;
  String servicePath;

  DaDemandBids(http.Client client,
      {this.rootUrl = 'http://localhost:8000',
      this.servicePath = '/da_demand_bids/v1/'});

  Future<List<Map<String, dynamic>>> getDailyDemandBidsForParticipant(
      int participantId, Date start, Date end) async {
    var url =
        '$rootUrl${servicePath}daily/mwh/demandbid/participantId/${participantId.toString()}/start/${start.toString()}/end/${end.toString()}';
    var response = await http.get(Uri.parse(url));
    var out = (json.decode(response.body) as List).cast<Map<String, dynamic>>();
    for (var e in out) {
      e['hours'] = json.decode(e['hours']);
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> getDailyDemandBidsForParticipantPtid(
      int participantId, int ptid, Date start, Date end) async {
    var _url =
        '$rootUrl${servicePath}daily/mwh/demandbid/participantId/${participantId.toString()}/ptid/$ptid/start/${start.toString()}/end/${end.toString()}';
    var _response = await http.get(Uri.parse(_url));
    var out =
        (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
    for (var e in out) {
      e['hours'] = json.decode(e['hours']);
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> getDailyDemandBidsByParticipant(
      Date start, Date end) async {
    var _url =
        '$rootUrl${servicePath}daily/mwh/demandbid/participant/start/${start.toString()}/end/${end.toString()}';
    var _response = await http.get(Uri.parse(_url));
    var out =
        (json.decode(_response.body) as List).cast<Map<String, dynamic>>();
    for (var e in out) {
      e['hours'] = json.decode(e['hours']);
    }
    return out;
  }
}
