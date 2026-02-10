import 'dart:convert';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/api/ieso/api_ieso_rtzonaldemand.dart';
import 'package:elec_server/client/ieso/ieso_client.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec/elec.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

/// See bin/setup_db.dart for setting the archive up to pass the tests
Future<void> tests(String rootUrl, String rustServer) async {
  var archive = getIesoRtZonalDemandArchive();
  group('IESO rt zonal demand db tests:', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read file for year 2003', () async {
      var file = archive.getFilename(2003);
      var data = archive.processFile(file);
      expect(data.length, 2940);
      expect(data.first.keys.toSet(), {'date', 'zone', 'values'});
      var c0 = data.firstWhere(
          (e) => e['zone'] == 'Ontario' && e['date'] == '2003-05-01');
      expect(c0['values'].length, 24);
      expect(c0['values'].first, 13702);
    });
  });
  group('IESO rt zonal demand API tests:', () {
    var api = ApiIesoRtZonalDemand(archive.dbConfig.db);
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());

    test('Get all zones', () async {
      var url = '$rootUrl/ieso/rt/zonal_demand/v1/zones';
      var aux = await http.get(Uri.parse(url));
      var data = json.decode(aux.body) as List;
      expect(data.contains('Ontario'), true);
    });

    test('Get demand for one zone', () async {
      var res = await api.getZone('Ontario', '2023-01-01', '2023-01-15');
      expect(res.length, 15);
      var v0 = (res.first['values'] as List);
      expect(v0.first, 13514);

      var url = '$rootUrl/ieso/rt/zonal_demand/v1/zone/Ontario'
          '/start/20230101/end/20230115';
      var aux = await http.get(Uri.parse(url));
      var data = json.decode(aux.body) as List;
      expect(data.length, 15);
      expect((data.first as Map).keys.toSet(), {'date', 'values'});
      expect((data.first['values'] as List).first, 13514);
    });
  });
  group('IESO RT Zonal Demand client tests:', () {
    var client =
        IesoClient(http.Client(), rootUrl: rootUrl, rustServer: rustServer);
    test('get hourly rt demand', () async {
      var term = Term.parse('1Jan23-15Jan23', Ieso.location);
      var aux = await client.hourlyRtZonalDemand(IesoLoadZone.east, term);
      expect(aux.length, 15 * 24);
      expect(
          aux.first.interval, Hour.beginning(TZDateTime(Ieso.location, 2023)));
      expect(aux.first.value, 774);
    });
  });
}

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['ROOT_URL']!;
  var rustServer = dotenv.env['RUST_SERVER']!;
  tests(rootUrl, rustServer);
}
