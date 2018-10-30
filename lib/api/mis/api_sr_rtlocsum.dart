	
	
library api.mis.sr_rtlocsum;
	
import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:rpc/rpc.dart';
import 'package:timezone/standalone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';
import 'package:elec_server/src/utils/api_response.dart';

@ApiClass(name: 'sr_rtlocsum', version: 'v1')
class SrRtLocSum {
	  DbCollection coll;
	  Location _location;
	  final DateFormat fmt = new DateFormat("yyyy-MM-ddTHH:00:00.000-ZZZZ");
	  String collectionName = 'sr_rtlocsum';
	

	  SrRtLocSum(Db db) {
	    coll = db.collection(collectionName);
	    _location = getLocation('US/Eastern');
	  }
	

	  /// http://localhost:8080/sr_rtlocsum/v1/account/0000523477/start/20170101/end/20170101
	  @ApiMethod(path: 'accountId/{accountId}/start/{start}/end/{end}')
	  /// Get all data in tab 0 for a given location.
	  Future<ApiResponse> apiGetTab0 (String accountId,
	      String start, String end) async {
	    Date startDate = Date.parse(start);
	    Date endDate = Date.parse(end);
	    var data = _getData(accountId, null, null, null, startDate, endDate);
	    return _processStream(data).then((aux) {
	    	return ApiResponse()..result = json.encode(aux);
			});
	  }
	

	  @ApiMethod(
	      path: 'accountId/{accountId}/locationId/{locationId}/start/{start}/end/{end}')
	  /// Get all data (all locations) for the account.
	  Future<ApiResponse> apiGetTab0ByLocation (String accountId,
	      int locationId, String start, String end) async {
	    Date startDate = Date.parse(start);
	    Date endDate = Date.parse(end);
	    var data = _getData(accountId, null, locationId, null, startDate, endDate);
	    return _processStream(data, hasLocationId: false).then((aux) {
        return ApiResponse()..result = json.encode(aux);
      });
	  }
	

	  @ApiMethod(
	      path: 'accountId/{accountId}/locationId/{locationId}/column/{columnName}/start/{start}/end/{end}')
	  /// Get one location, one column for the account.
	  Future<ApiResponse> apiGetTab0ByLocationColumn (String accountId,
	      int locationId, String columnName, String start, String end) async {
	    Date startDate = Date.parse(start);
	    Date endDate = Date.parse(end);
	    var data = _getData(accountId, null, locationId, columnName, startDate, endDate);
	    return _processStream(data, hasLocationId: false).then((aux) {
        return ApiResponse()..result = json.encode(aux);
      });
	  }
	

	  @ApiMethod(path: 'accountId/{accountId}/subaccountId/{subaccountId}/start/{start}/end/{end}')
	  /// Get all data in tab 1 for all locations.
	  Future<ApiResponse> apiGetTab1 (String accountId,
	      String subaccountId, String start, String end) async {
	    Date startDate = Date.parse(start);
	    Date endDate = Date.parse(end);
	    var data = _getData(accountId, subaccountId, null, null, startDate, endDate);
	    //var aux = await data.toList(); print(aux);
	    return _processStream(data).then((aux) {
        return ApiResponse()..result = json.encode(aux);
      });
	  }
	

	  @ApiMethod(path: 'accountId/{accountId}/subaccountId/{subaccountId}/locationId/{locationId}/start/{start}/end/{end}')
	  /// Get all data in tab 1 for a given location.
	  Future<ApiResponse> apiGetTab1ByLocation (String accountId,
	      String subaccountId, int locationId, String start, String end) async {
	    Date startDate = Date.parse(start);
	    Date endDate = Date.parse(end);
	    var data = _getData(accountId, subaccountId, locationId, null, startDate, endDate);
	    //var aux = await data.toList(); print(aux);
	    return _processStream(data, hasLocationId: false).then((aux) {
        return ApiResponse()..result = json.encode(aux);
      });
	  }
	

	  @ApiMethod(path: 'accountId/{accountId}/subaccountId/{subaccountId}/locationId/{locationId}/column/{columnName}/start/{start}/end/{end}')
	  /// Get all data for a subaccount for a given location, one column.
	  Future<ApiResponse> apiGetTab1ByLocationColumn (String accountId,
	      String subaccountId, int locationId, String columnName, String start, String end) async {
	    Date startDate = Date.parse(start);
	    Date endDate = Date.parse(end);
	    var data = _getData(accountId, subaccountId, locationId, columnName, startDate, endDate);
	    //var aux = await data.toList(); print(aux);
	    return _processStream(data, hasLocationId: false).then((aux) {
	      print(aux);
        return ApiResponse()..result = json.encode(aux);
      });
	  }


	  Future<List<Map<String,dynamic>>> _processStream(Stream<Map<String,dynamic>> data, {bool hasLocationId: true}) async {
	    var out = <Map<String,dynamic>>[];
	    List<String> otherKeys;
	    await for (var e in data) {
	      otherKeys ??= e.keys.toList()
	        ..remove('hourBeginning')
	        ..remove('version')
	        ..remove('Location ID');
	      for (int i=0; i<e['hourBeginning'].length; i++) {
	        var aux = <String,dynamic>{
	          'hourBeginning': new TZDateTime.from(e['hourBeginning'][i], _location).toString(),
	          'version': new TZDateTime.from(e['version'], _location).toString(),
	        };
	        if (hasLocationId) aux['Location ID'] = e['Location ID'];
	        for (String key in otherKeys) {
	          aux[key] = e[key][i];
	        }
	        out.add(aux);
	      }
	    }
	    return out;
	  }
	

	  
	  /// Extract data from tab 0
	  /// returns one element for each day
	  /// If [subaccountId] is [null] return data from tab 0 (the aggregated data)
	  /// If [locationId] is [null] return all locations
	  /// If [column] is [null] return all columns
	  Stream<Map<String,dynamic>> _getData(String account, String subaccountId,
	      int locationId, String column, Date startDate, Date endDate) {
	    var pipeline = <Map<String,dynamic>>[];
	    var match = <String,dynamic>{'account': {'\$eq': account}};
	    if (subaccountId == null) {
	      match['tab'] = {'\$eq': 0};
	    } else {
	      match['tab'] = {'\$eq': 1};
	      match['Subaccount ID'] = {'\$eq': subaccountId};
	    }
	    match['date'] = {
	        '\$gte': startDate.toString(),
	        '\$lte': endDate.toString(),
	    };
	    if (locationId != null) match['Location ID']= {'\$eq': locationId};
	    pipeline.add({'\$match': match});
	    Map project = {
	      '_id': 0,
	      'account': 0,
	      'tab': 0,
	      'date': 0,
	    };
	    if (subaccountId != null) project['Subaccount ID'] = 0;
	    pipeline.add({'\$project': project});
	    
	    if (column != null) {
	      /// add another projection to get only this column
	      pipeline.add({'\$project': {
	        'hourBeginning': 1,
	        'version': 1,
	        column: 1,
	      }});
	    }
	    return coll.aggregateToStream(pipeline);
	  }
	

}
	

