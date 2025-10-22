import 'package:http/http.dart' as http;
//import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/api/isoexpress/api_isone_regulation_requirement.dart'
    as api;
import 'package:elec_server/client/isoexpress/regulation_requirement.dart';
import 'package:elec_server/src/db/isoexpress/regulation_requirement.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

Future<void> tests(String rootUrl) async {
  var location = getLocation('America/New_York');
  // var shelfRootUrl = dotenv.env['SHELF_ROOT_URL'];
  var archive = RegulationRequirementArchive();
  group('Regulation requirements archive test:', () {
    setUp(() async => await archive.db.open());
    tearDown(() async => await archive.db.close());
    test('read and insert all data', () async {
      var data = archive.readAllData();
      expect(data.length, 1);
      var one = data.first;
      expect(one.keys.toSet(),
          {'to', 'from', 'regulation capacity', 'regulation service'});
      var x =
          (one['regulation capacity'] as List).first as Map<String, dynamic>;
      expect(x.keys.toSet(), {'month', 'weekday', 'hourBeginning', 'value'});
      var res = await archive.insertData(data);
      expect(res, 0);
    });
  });
  group('Regulation requirement API test', () {
    var db = mongo.Db('mongodb://localhost/isoexpress');
    var rr = api.RegulationRequirement(db);
    setUp(() async => await db.open());
    tearDown(() async => await db.close());
    test('get all values', () async {
      var values = await rr.regulationRequirements();
      expect(values.first.keys.toSet(),
          {'from', 'to', 'regulation capacity', 'regulation service'});
    });
  });
  group('Regulation requirement client test', () {
    var client = RegulationRequirement(http.Client(), rootUrl: rootUrl);
    test('get specifications', () async {
      var specs = await client.getSpecification();
      expect(specs.first.keys.toSet(), {
        'from',
        'to',
        'regulation capacity',
        'regulation service',
        'interval'
      });
    });
    test('get hourly capacity requirement', () async {
      var interval = parseTerm('Jan22-Dec22', tzLocation: location)!;
      var capReq = await client.hourlyCapacityRequirement(interval);
      expect(capReq.length, 8760);
      var hour = Hour.beginning(TZDateTime(location, 2022));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour, 50));
      hour = Hour.beginning(TZDateTime(location, 2022, 1, 1, 5));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour, 50));
      hour = Hour.beginning(TZDateTime(location, 2022, 1, 1, 6));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour, 120));
      hour = Hour.beginning(TZDateTime(location, 2022, 1, 1, 8));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour, 100));
      hour = Hour.beginning(TZDateTime(location, 2022, 7, 1, 0));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour, 70));
      hour = Hour.beginning(TZDateTime(location, 2022, 7, 1, 6));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour, 190));
      hour = Hour.beginning(TZDateTime(location, 2022, 1, 1, 8));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour, 100));
    });
  });
}

void main() async {
  initializeTimeZones();
//  await DailyRegulationRequirementArchive().setupDb();

  // dotenv.load('.env/prod.env');
  await tests('http://127.0.0.1:8080');
}
