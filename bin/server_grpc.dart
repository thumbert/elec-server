

import 'package:fixnum/fixnum.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:grpc/grpc.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/generated/timeseries.pbgrpc.dart';

class LmpService extends LmpServiceBase {
  DbCollection collection;
  final _location = getLocation('US/Eastern');

  LmpService(Db db) {
    collection = db.collection('da_lmp_hourly');
  }

  Future<NumericTimeSeries> getLmp(
      ServiceCall call, HistoricalLmpRequest request) async {
    var ptid = request.ptid;
    var start = Date.fromTZDateTime(TZDateTime.fromMillisecondsSinceEpoch(
        _location, request.start.toInt()));
    var end = Date.fromTZDateTime(
        TZDateTime.fromMillisecondsSinceEpoch(_location, request.end.toInt()));
    var component = request.component.component.toString().toLowerCase();

    var query = where;
    query = query.eq('ptid', 4000);
    query = query.gte('date', start.toString());
    query = query.lte('date', end.toString());
    query = query.fields(['hourBeginning', component]);
    var data = collection.find(query);
    var hourly = TimeInterval()..interval = TimeInterval_Interval.HOURLY;
    var out = NumericTimeSeries()
      ..name = 'isone_da_${component}_$ptid'
      ..tzLocation = 'US/Eastern'
      ..timeInterval = hourly;
    await for (Map e in data) {
      for (int i = 0; i < e['hourBeginning'].length; i++) {
        out.observation.add(NumericTimeSeries_Observation()
          ..start =
          Int64((e['hourBeginning'][i] as DateTime).millisecondsSinceEpoch)
          ..value = e[component][i]);
      }
    }

    return out;
  }
}

main() async {
  const String host = '127.0.0.1';
  var db = Db('mongodb://$host/isoexpress');
  await db.open();
  await initializeTimeZone();

  final server = Server([LmpService(db)]);
  await server.serve(port: 50051);
  print('Server listening on port ${server.port}...');
}
