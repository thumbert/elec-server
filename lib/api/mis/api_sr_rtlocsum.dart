library api.mis.sr_rtlocsum;

import 'dart:async';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/timezone.dart';
import 'package:intl/intl.dart';
import 'package:date/date.dart';
import 'package:tuple/tuple.dart';
import 'package:table/table.dart';
import 'package:dama/dama.dart';
import 'package:elec_server/src/db/lib_settlements.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SrRtLocSum {
  DbCollection coll;
  Location _location;
  final DateFormat fmt = DateFormat('yyyy-MM-ddTHH:00:00.000-ZZZZ');
  String collectionName = 'sr_rtlocsum';

  SrRtLocSum(Db db) {
    coll = db.collection(collectionName);
    _location = getLocation('America/New_York');
  }

  final headers = {
    'Content-Type': 'application/json',
  };

  Router get router {
    final router = Router();

    router.get('/accountId/<accountId>/start/<start>/end/<end>',
        (Request request, String accountId, String start, String end) async {
      var aux = await apiGetTab0(accountId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/accountId/<accountId>/locationId/<locationId>/start/<start>/end/<end>',
        (Request request, String accountId, String locationId, String start,
            String end) async {
      var aux = await apiGetTab0ByLocation(
          accountId, int.parse(locationId), start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/accountId/<accountId>/locationId/<locationId>/column/<columnName>/start/<start>/end/<end>',
        (Request request, String accountId, String locationId,
            String columnName, String start, String end) async {
      columnName = Uri.decodeComponent(columnName);
      var aux = await apiGetTab0ByLocationColumn(
          accountId, int.parse(locationId), columnName, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/daily/accountId/<accountId>/locationId/<locationId>/column/<columnName>/start/<start>/end/<end>',
        (Request request, String accountId, String locationId,
            String columnName, String start, String end) async {
      columnName = Uri.decodeComponent(columnName);
      var aux = await apiGetTab0ByLocationColumnDaily(
          accountId, int.parse(locationId), columnName, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/accountId/<accountId>/subaccountId/<subaccountId>/start/<start>/end/<end>',
        (Request request, String accountId, String subaccountId, String start,
            String end) async {
      var aux = await apiGetTab1(accountId, subaccountId, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/accountId/<accountId>/subaccountId/<subaccountId>/locationId/<locationId>/start/<start>/end/<end>',
        (Request request, String accountId, String subaccountId,
            String locationId, String start, String end) async {
      var aux = await apiGetTab1ByLocation(
          accountId, subaccountId, int.parse(locationId), start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/accountId/<accountId>/subaccountId/<subaccountId>/locationId/<locationId>/column/<columnName>/start/<start>/end/<end>',
        (Request request,
            String accountId,
            String subaccountId,
            String locationId,
            String columnName,
            String start,
            String end) async {
      columnName = Uri.decodeComponent(columnName);
      var aux = await apiGetTab1ByLocationColumn(accountId, subaccountId,
          int.parse(locationId), columnName, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/daily/accountId/<accountId>/subaccountId/<subaccountId>/locationId/<locationId>/column/<columnName>/start/<start>/end/<end>',
        (Request request,
            String accountId,
            String subaccountId,
            String locationId,
            String columnName,
            String start,
            String end) async {
      columnName = Uri.decodeComponent(columnName);
      var aux = await apiGetTab1ByLocationColumnDaily(accountId, subaccountId,
          int.parse(locationId), columnName, start, end);
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/rtload/monthly/accountId/<accountId>/locationId/<locationId>/start/<start>/end/<end>/settlement/<settlement>',
        (Request request, String accountId, String locationId, String start,
            String end, String settlement) async {
      var aux = await monthlyRtLoadForAccountZone(
          accountId, int.parse(locationId), start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/rtload/monthly/accountId/<accountId>/subaccountId/<subaccountId>/locationId/<locationId>/start/<start>/end/<end>/settlement/<settlement>',
        (Request request,
            String accountId,
            String subaccountId,
            String locationId,
            String start,
            String end,
            String settlement) async {
      var aux = await monthlyRtLoadForSubaccountZone(accountId, subaccountId,
          int.parse(locationId), start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/rtenergy_settlement/daily/accountId/<accountId>/start/<start>/end/<end>/settlement/<settlement>',
        (Request request, String accountId, String start, String end,
            String settlement) async {
      var aux = await dailyRtSettlementForAccount(
          accountId, start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/rtenergy_settlement/daily/accountId/<accountId>/start/<start>/end/<end>/locations/<locations>/settlement/<settlement>',
        (Request request, String accountId, String start, String end,
            String locations, String settlement) async {
      locations = Uri.decodeComponent(locations);
      var aux = await dailyRtSettlementForAccountLocations(
          accountId, start, end, locations, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/rtenergy_settlement/daily/accountId/<accountId>/subaccountId/<subaccountId>/start/<start>/end/<end>/settlement/<settlement>',
        (Request request, String accountId, String subaccountId, String start,
            String end, String settlement) async {
      var aux = await dailyRtSettlementForSubaccount(
          accountId, subaccountId, start, end, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    router.get(
        '/rtenergy_settlement/daily/accountId/<accountId>/subaccountId/<subaccountId>/start/<start>/end/<end>/locations/<locations>/settlement/<settlement>',
        (Request request, String accountId, String subaccountId, String start,
            String end, String locations, String settlement) async {
      locations = Uri.decodeComponent(locations);
      var aux = await dailyRtSettlementForSubaccountLocations(accountId,
          subaccountId, start, end, locations, int.parse(settlement));
      return Response.ok(json.encode(aux), headers: headers);
    });

    return router;
  }

  /// http://localhost:8080/sr_rtlocsum/v1/account/0000523477/start/20170101/end/20170101
  /// Get all data in tab 0 for a given location.
  Future<List<Map<String, dynamic>>> apiGetTab0(
      String accountId, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data =
        await getHourlyData(accountId, null, null, null, startDate, endDate);
    return _processStream(data);
  }

  /// Get all data (all locations) for the account.
  Future<List<Map<String, dynamic>>> apiGetTab0ByLocation(
      String accountId, int locationId, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data = await getHourlyData(
        accountId, null, locationId, null, startDate, endDate);
    return _processStream(data, hasLocationId: false);
  }

  /// Get one location, one column for the account.
  Future<List<Map<String, dynamic>>> apiGetTab0ByLocationColumn(
      String accountId,
      int locationId,
      String columnName,
      String start,
      String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data = await getHourlyData(
        accountId, null, locationId, columnName, startDate, endDate);
    return _processStream(data, hasLocationId: false);
  }

  /// Get one location, one column for the account.
  Future<List<Map<String, dynamic>>> apiGetTab0ByLocationColumnDaily(
      String accountId,
      int locationId,
      String columnName,
      String start,
      String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    return getDailyDataColumn(
        accountId, null, locationId, columnName, startDate, endDate);
  }

  /// Get all data in tab 1 for all locations.
  Future<List<Map<String, dynamic>>> apiGetTab1(
      String accountId, String subaccountId, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data = await getHourlyData(
        accountId, subaccountId, null, null, startDate, endDate);
    return _processStream(data);
  }

  /// Get all data in tab 1 for a given location.
  Future<List<Map<String, dynamic>>> apiGetTab1ByLocation(String accountId,
      String subaccountId, int locationId, String start, String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data = await getHourlyData(
        accountId, subaccountId, locationId, null, startDate, endDate);
    return _processStream(data, hasLocationId: false);
  }

  /// Get all data for a subaccount for a given location, one column.
  Future<List<Map<String, dynamic>>> apiGetTab1ByLocationColumn(
      String accountId,
      String subaccountId,
      int locationId,
      String columnName,
      String start,
      String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    var data = await getHourlyData(
        accountId, subaccountId, locationId, columnName, startDate, endDate);
    return _processStream(data, hasLocationId: false);
  }

  /// Get all data for a subaccount for a given location, one column.
  Future<List<Map<String, dynamic>>> apiGetTab1ByLocationColumnDaily(
      String accountId,
      String subaccountId,
      int locationId,
      String columnName,
      String start,
      String end) async {
    var startDate = Date.parse(start);
    var endDate = Date.parse(end);
    return getDailyDataColumn(
        accountId, subaccountId, locationId, columnName, startDate, endDate);
  }

  /// Get monthly total load for a subaccount for a given location, one settlement.
  Future<Map<String, dynamic>> monthlyRtLoadForAccountZone(String accountId,
      int locationId, String start, String end, int settlement) async {
    var startDate = parseMonth(start).startDate.toString();
    var endDate = parseMonth(end).endDate.toString();
    return _getMonthlyData(
      accountId,
      null,
      locationId,
      startDate,
      endDate,
      settlement,
      column: 'Real Time Load Obligation',
    );
  }

  /// Get monthly total load for a subaccount for a given location, one settlement.
  /// [start] and [end] are in the yyyymm format.
  Future<Map<String, dynamic>> monthlyRtLoadForSubaccountZone(
      String accountId,
      String subaccountId,
      int locationId,
      String start,
      String end,
      int settlement) async {
    var startDate = parseMonth(start).startDate.toString();
    var endDate = parseMonth(end).endDate.toString();
    return _getMonthlyData(
      accountId,
      subaccountId,
      locationId,
      startDate,
      endDate,
      settlement,
      column: 'Real Time Load Obligation',
    );
  }

  Future<List<Map<String, dynamic>>> dailyRtSettlementForAccount(
      String accountId, String start, String end, int settlement) async {
    var startDate = Date.parse(start).toString();
    var endDate = Date.parse(end).toString();
    return _getDailyData(accountId, null, startDate, endDate, null, settlement,
        columns: [
          'Real Time Energy Charge/Credit',
          'Real Time Congestion Charge/Credit',
          'Real Time Loss Charge/Credit',
          'Real Time Demand Reduction Credit',
          'Real Time Demand Reduction Charge',
          'Real Time Marginal Loss Revenue Allocation',
          'External Inadvertent Cost Distribution',
        ]);
  }

  /// Locations is a comma separated string of ptids, e.g. '4001,4004'
  Future<List<Map<String, dynamic>>> dailyRtSettlementForAccountLocations(
      String accountId,
      String start,
      String end,
      String locations,
      int settlement) async {
    var startDate = Date.parse(start).toString();
    var endDate = Date.parse(end).toString();
    return _getDailyData(
        accountId, null, startDate, endDate, locations, settlement,
        columns: [
          'Real Time Energy Charge/Credit',
          'Real Time Congestion Charge/Credit',
          'Real Time Loss Charge/Credit',
          'Real Time Demand Reduction Credit',
          'Real Time Demand Reduction Charge',
          'Real Time Marginal Loss Revenue Allocation',
          'External Inadvertent Cost Distribution',
        ]);
  }

  Future<List<Map<String, dynamic>>> dailyRtSettlementForSubaccount(
      String accountId,
      String subaccountId,
      String start,
      String end,
      int settlement) async {
    var startDate = Date.parse(start).toString();
    var endDate = Date.parse(end).toString();
    return _getDailyData(
        accountId, subaccountId, startDate, endDate, null, settlement,
        columns: [
          'Real Time Energy Charge/Credit',
          'Real Time Congestion Charge/Credit',
          'Real Time Loss Charge/Credit',
          'Real Time Demand Reduction Credit',
          'Real Time Demand Reduction Charge',
          'Real Time Marginal Loss Revenue Allocation',
          'External Inadvertent Cost Distribution',
        ]);
  }

  Future<List<Map<String, dynamic>>> dailyRtSettlementForSubaccountLocations(
      String accountId,
      String subaccountId,
      String start,
      String end,
      String locations,
      int settlement) async {
    var startDate = Date.parse(start).toString();
    var endDate = Date.parse(end).toString();
    return _getDailyData(
        accountId, subaccountId, startDate, endDate, locations, settlement,
        columns: [
          'Real Time Energy Charge/Credit',
          'Real Time Congestion Charge/Credit',
          'Real Time Loss Charge/Credit',
          'Real Time Demand Reduction Credit',
          'Real Time Demand Reduction Charge',
          'Real Time Marginal Loss Revenue Allocation',
          'External Inadvertent Cost Distribution',
        ]);
  }

  /// Get daily total for a subaccount for a given location, one settlement.
  Future<List<Map<String, dynamic>>> _getDailyData(
      String accountId,
      String subaccountId,
      String startDate,
      String endDate,
      String locations,
      int settlement,
      {List<String> columns}) async {
    var _locations = <int>[];
    if (locations != null) {
      _locations = locations.split(',').map((e) => int.parse(e)).toList();
    }
    var pipeline = [
      {
        '\$match': {
          'account': {'\$eq': accountId},
          'tab': {'\$eq': subaccountId == null ? 0 : 1},
          if (subaccountId != null) 'Subaccount ID': {'\$eq': subaccountId},
          'date': {
            '\$gte': startDate,
            '\$lte': endDate,
          },
          if (_locations.isNotEmpty) 'Location ID': {'\$in': _locations},
        },
      },
      {
        '\$group': {
          '_id': {
            'date': '\$date',
            'version': '\$version',
            'Location ID': '\$Location ID',
            ...{
              for (var column in columns) column: {'\$sum': '\$$column'}
            },
          }
        },
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$_id.date',
          'version': {'\$toString': '\$_id.version'},
          'Location ID': '\$_id.Location ID',
          ...{for (var column in columns) column: '\$_id.$column'},
        },
      },
      {
        '\$sort': {
          'date': 1,
        }
      },
    ];
    var data = await coll.aggregateToStream(pipeline).toList();
    var aux = getNthSettlement(data, (e) => Tuple2(e['date'], e['Location ID']),
        n: settlement);
    return aux;
  }

  /// Get monthly total for a subaccount for a given zone, one settlement.
  Future<Map<String, dynamic>> _getMonthlyData(
      String accountId,
      String subaccountId,
      int locationId,
      String startDate,
      String endDate,
      int settlement,
      {String column = 'Real Time Load Obligation'}) async {
    var pipeline = [
      {
        '\$match': {
          'account': {'\$eq': accountId},
          'tab': {'\$eq': subaccountId == null ? 0 : 1},
          if (subaccountId != null) 'Subaccount ID': {'\$eq': subaccountId},
          'date': {
            '\$gte': startDate.toString(),
            '\$lte': endDate.toString(),
          },
          'Location ID': {'\$eq': locationId},
        },
      },
      {
        '\$group': {
          '_id': {
            'date': '\$date',
            'version': '\$version',
            'value': {'\$sum': '\$$column'},
          }
        },
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$_id.date',
          'version': '\$_id.version',
          'value': '\$_id.value',
        },
      },
      {
        '\$sort': {
          'date': 1,
        }
      },
    ];

    var data = await coll.aggregateToStream(pipeline).toList();
    var aux = getNthSettlement(data, (e) => e['date'], n: settlement);
    var nest = Nest()
      ..key((e) => e['date'].substring(0, 7))
      ..rollup((List xs) => -sum(xs.map((e) => e['value'] as num)));
    var out = nest.map(aux);
    return Map<String, dynamic>.from(out);
  }

  List<Map<String, dynamic>> _processStream(List<Map<String, dynamic>> data,
      {bool hasLocationId = true}) {
    var out = <Map<String, dynamic>>[];
    List<String> otherKeys;
    for (var e in data) {
      otherKeys ??= e.keys.toList()
        ..remove('hourBeginning')
        ..remove('version')
        ..remove('Location ID');
      for (var i = 0; i < e['hourBeginning'].length; i++) {
        var aux = <String, dynamic>{
          'hourBeginning':
              TZDateTime.from(e['hourBeginning'][i], _location).toString(),
          'version': TZDateTime.from(e['version'], _location).toString(),
        };
        if (hasLocationId) aux['Location ID'] = e['Location ID'];
        for (var key in otherKeys) {
          aux[key] = e[key][i];
        }
        out.add(aux);
      }
    }
    return out;
  }

  /// Extract data from the collection
  /// returns one element for each day
  /// If [subaccountId] is [null] return data from tab 0 (the aggregated data)
  /// If [locationId] is [null] return all locations
  /// If [column] is [null] return all columns
  Future<List<Map<String, dynamic>>> getHourlyData(
      String account,
      String subaccountId,
      int locationId,
      String column,
      Date startDate,
      Date endDate) async {
    var excludeFields = <String>['_id', 'account', 'tab', 'date'];

    var query = where;
    query.eq('account', account);
    if (subaccountId == null) {
      query.eq('tab', 0);
    } else {
      query.eq('tab', 1);
      query.eq('Subaccount ID', subaccountId);
      excludeFields.add('Subaccount ID');
    }
    query.gte('date', startDate.toString());
    query.lte('date', endDate.toString());
    if (locationId != null) {
      query.eq('Location ID', locationId);
    }

    if (column == null) {
      query.excludeFields(excludeFields);
    } else {
      query.excludeFields(['_id']);
      query.fields(['hourBeginning', 'version', column]);
    }
    return coll.find(query).toList();
  }

  /// Extract data from the collection
  /// returns one element for each day
  /// If [subaccountId] is [null] return data from tab 0 (the aggregated data)
  /// If [locationId] is [null] return all locations
  /// If [column] is [null] return all columns
  Future<List<Map<String, dynamic>>> getDailyDataColumn(
      String account,
      String subaccountId,
      int locationId,
      String column,
      Date startDate,
      Date endDate) async {
    var pipeline = [
      {
        '\$match': {
          'date': {
            '\$gte': startDate.toString(),
            '\$lte': endDate.toString(),
          },
          'account': {'\$eq': account},
          'tab': {'\$eq': (subaccountId == null) ? 0 : 1},
          if (subaccountId != null) 'Subaccount ID': {'\$eq': subaccountId},
          if (locationId != null) 'Location ID': {'\$eq': locationId},
        }
      },
      {
        '\$project': {
          '_id': 0,
          'date': '\$date',
          'version': {'\$toString': '\$version'},
          if (locationId == null) 'Location ID': '\$Location ID',
          column: {'\$sum': '\$$column'},
        }
      },
      {
        '\$sort': {
          'date': 1,
        }
      }
    ];
    var res = await coll.aggregateToStream(pipeline).toList();
    return res;
  }
}
