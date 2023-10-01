library test.db.ieso.rt_zonal_demand_test;

import 'dart:convert';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/api/iemo/api_ieso_rtgeneration.dart';
import 'package:elec_server/api/iemo/api_ieso_rtzonaldemand.dart';
import 'package:elec_server/client/ieso/ieso_client.dart';
import 'package:elec_server/src/db/lib_prod_archives.dart';
import 'package:elec/elec.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

Future<void> tests(String rootUrl) async {
  var archive = getIesoRtGenerationArchive();
  group('IESO rt generation db tests:', () {
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());
    test('read file for month 2019-05', () async {
      var file = archive.getFilename(Month.utc(2019, 5));
      var data = archive.processFile(file);
      expect(data.length, 5574);
      var c0 = data.firstWhere((e) => e['name'] == 'ABKENORA' && e['date'] == '2019-05-01');
      expect(c0.keys.toSet(), {'date', 'name', 'fuel', 'capability', 'output'});
      expect(c0['output'].length, 24);
      expect(c0['output'].first, 8);

      var e = data.firstWhere((e) => e['name'] == 'NAPANEE-G3' && e['date'] == '2019-05-07');
      expect(e['output'].first, 0); // it's ' ' in the spreadsheet!
    });
  });
  group('IESO rt generation API tests:', () {
    var api = ApiIesoRtGeneration(archive.dbConfig.db);
    setUp(() async => await archive.dbConfig.db.open());
    tearDown(() async => await archive.dbConfig.db.close());

    test('Get all generators', () async {
      var url = '$rootUrl/ieso/rt/generation/v1/names';
      var aux = await http.get(Uri.parse(url));
      var data = json.decode(aux.body) as List;
      expect(data.contains('NAPANEE-G1'), true);
    });

    test('Get generation for one plant', () async {
      var res = await api.getGeneration('BRUCEA-G1', 'output', '2019-05-01', '2019-05-03');
      expect(res.length, 3);
      var v0 = (res.first['output'] as List);
      expect(v0.first, 782);

      var url = '$rootUrl/ieso/rt/generation/v1/name/BRUCEA-G1'
          '/output/start/20190501/end/20190503';
      var aux = await http.get(Uri.parse(url));
      var data = json.decode(aux.body) as List;
      expect(data.length, 3);
      expect((data.first as Map).keys.toSet(), {'date', 'output'});
      expect((data.first['output'] as List).first, 782);
    });

    test('Get generation for one fuel', () async {
      var res = await api.getGenerationForFuel('hydro', 'output', '2019-05-01', '2019-05-03');
      expect(res.length, 3);
      var v0 = (res.first['output'] as List);
      expect(v0.first, 4349);

      var url = '$rootUrl/ieso/rt/generation/v1/fuel/hydro'
          '/output/start/20190501/end/20190503';
      var aux = await http.get(Uri.parse(url));
      var data = json.decode(aux.body) as List;
      expect(data.length, 3);
      expect((data.first as Map).keys.toSet(), {'date', 'output'});
      expect((data.first['output'] as List).first, 4349);
    });
  });
  // group('IESO RT Zonal Demand client tests:', () {
  //   var client = IesoClient(http.Client(), rootUrl: rootUrl);
  //   test('get hourly rt demand', () async {
  //     var term = Term.parse('1Jan23-15Jan23', Ieso.location);
  //     var aux = await client.hourlyRtZonalDemand(IesoLoadZone.ontario, term);
  //     expect(aux.length, 15*24);
  //     expect(aux.first.interval, Hour.beginning(TZDateTime(Ieso.location, 2023)));
  //     expect(aux.first.value, 13514);
  //   });
  // });
}

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['ROOT_URL']!;
  tests(rootUrl);
}
