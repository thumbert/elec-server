import 'package:fixnum/fixnum.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:timezone/standalone.dart';
import 'package:grpc/grpc.dart';
import 'package:date/date.dart';
import 'package:elec_server/src/generated/timeseries.pbgrpc.dart';

class LmpService extends LmpServiceBase {
  late DbCollection collection;
  final _location = getLocation('America/New_York');

  LmpService(Db db) {
    collection = db.collection('da_lmp_hourly');
  }

  @override
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
    var hourly = IntervalType()..type = IntervalType_Type.HOURLY;
    var out = NumericTimeSeries()
      ..name = 'isone_da_${component}_$ptid'
      ..tzLocation = 'America/New_York'
      ..timeInterval = hourly;
    await for (Map e in data) {
      var hours = e['hourBeginning'] as List;
      for (var i = 0; i < hours.length; i++) {
        out.observation.add(NumericTimeSeries_Observation()
          ..start = Int64((hours[i] as DateTime).millisecondsSinceEpoch)
          ..value = e[component][i] as double);
      }
    }

    return out;
  }
}

void main() async {
  const host = '127.0.0.1';
  var db = Db('mongodb://$host/isoexpress');
  await db.open();
  await initializeTimeZone();

  final server = Server([LmpService(db)]);
  await server.serve(port: 50051);
  print('Server listening on port ${server.port}...');
}
