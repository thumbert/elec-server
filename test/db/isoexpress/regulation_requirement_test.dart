library test.db.isoexpress.regulation_requirement_test;

import 'dart:convert';
import 'package:http/http.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec_server/api/isoexpress/api_isone_regulation_requirement.dart' as api;
import 'package:elec_server/client/isoexpress/regulation_requirement.dart';
import 'package:elec_server/src/db/isoexpress/regulation_requirement.dart';
import 'package:test/test.dart';
import 'package:timezone/standalone.dart';
import 'package:date/date.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

tests() async {
  var location = getLocation('America/New_York');
  group('Regulation requirements archive test:', () {
    var archive = RegulationRequirementArchive();
    setUp(() async {
//      await archive.setupDb();
      await archive.dbConfig.db.open();
    });
    tearDown(() async => await archive.dbConfig.db.close());
//    test('download current requirement', () async {
//      var res = await archive.downloadFile();
//      expect(res, 0);
//    });
    test('read and insert all data', () async {
      var data = await archive.readAllData();
      expect(data.length, 1);
      var one = data.first;
      expect(one.keys.toSet(), {'to', 'from', 'regulation capacity',
        'regulation service'});
      var x = (one['regulation capacity'] as List).first as Map<String,dynamic>;
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
      var res = await rr.regulationRequirements();
      var values = (json.decode(res.result) as List).cast<Map<String,dynamic>>();
      expect(values.first.keys.toSet(),
          {'from', 'to', 'regulation capacity', 'regulation service'});
    });
  });
  group('Regulation requirement client test', () {
    var client = RegulationRequirement(Client());
    test('get specifications', () async {
      var specs = await client.getSpecification();
      expect(specs.first.keys.toSet(),
          {'from', 'to', 'regulation capacity', 'regulation service', 'interval'});
    });
    test('get hourly capacity requirement', () async {
      var interval = parseTerm('Jan19-Dec19', tzLocation: location);
      var capReq = await client.hourlyCapacityRequirement(interval);
      expect(capReq.length, 8760);
      var hour = Hour.beginning(TZDateTime(location,2019));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour,50));
      hour = Hour.beginning(TZDateTime(location,2019,1,1,5));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour,140));
      hour = Hour.beginning(TZDateTime(location,2019,1,1,6));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour,170));
      hour = Hour.beginning(TZDateTime(location,2019,1,1,8));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour,90));
      hour = Hour.beginning(TZDateTime(location,2019,7,1,0));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour,70));
      hour = Hour.beginning(TZDateTime(location,2019,7,1,6));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour,190));
      hour = Hour.beginning(TZDateTime(location,2019,1,1,8));
      expect(capReq.observationAt(hour), IntervalTuple<num>(hour,90));
    });
  });
}


main() async {
  await initializeTimeZone();
//  await DailyRegulationRequirementArchive().setupDb();

  await tests();

}
