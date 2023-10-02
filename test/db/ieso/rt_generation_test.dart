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

    test('Get last date', () async {
      var url = '$rootUrl/ieso/rt/generation/v1/last-date';
      var aux = await http.get(Uri.parse(url));
      var data = json.decode(aux.body) as String;
      expect(data.length, 10);
    });

    test('Get all generators', () async {
      var url = '$rootUrl/ieso/rt/generation/v1/names';
      var aux = await http.get(Uri.parse(url));
      var data = json.decode(aux.body) as List;
      expect(data.contains('NAPANEE-G1'), true);
    });

    test('Get all generators/variables', () async {
      var url = '$rootUrl/ieso/rt/generation/v1/names/variables/date/2023-09-01';
      var aux = await http.get(Uri.parse(url));
      var data = json.decode(aux.body) as Map;
      expect(data.containsKey('ADELAIDE'), true);
      expect(data['ADELAIDE'], ['capacity', 'forecast', 'output']);
    });

    test('Get all generators between start/end', () async {
      var url = '$rootUrl/ieso/rt/generation/v1/all'
          '/start/20190501/end/20190503';
      var aux = await http.get(Uri.parse(url));
      var data = json.decode(aux.body) as List;
      expect(data.length, 537);
      var x0 = data.firstWhere((e) => e['date'] == '2019-05-01' && e['name'] == 'ABKENORA') as Map;
      expect(x0.keys.toSet(), {'date', 'name', 'capability', 'output'});
      expect((x0['output'] as List).first, 8);
    });

    test('Get generation for one plant', () async {
      var res = await api.getVariableForName('BRUCEA-G1', 'output', '2019-05-01', '2019-05-03');
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
  //
  //
  group('IESO RT Generation client tests:', () {
    var client = IesoClient(http.Client(), rootUrl: rootUrl);
    test('get hourly rt generation one name', () async {
      var term = Term.parse('1May19-10May19', Ieso.location);
      var aux = await client.hourlyRtGeneration('ABKENORA', term, variable: 'output');
      expect(aux.length, 10*24);
      expect(aux.first.interval, Hour.beginning(TZDateTime(Ieso.location, 2019, 5)));
      expect(aux.first.value, 8);
    });
    test('get hourly rt generation one name', () async {
      var term = Term.parse('1May19-10May19', Ieso.location);
      var aux = await client.hourlyRtGenerationAll('ADELAIDE', term);
      expect(aux.length, 3);
      expect(aux.keys.toSet(), {'capacity', 'forecast', 'output'});
      expect(aux['output']!.first.interval, Hour.beginning(TZDateTime(Ieso.location, 2019, 5)));
      expect(aux['output']!.first.value, 37);
    });
    test('get hourly rt generation by fuel', () async {
      var term = Term.parse('1May19-10May19', Ieso.location);
      var aux = await client.hourlyRtGenerationForType(IesoFuelType.nuclear, term);
      expect(aux.length, 10*24);
      expect(aux.first.value, 8420);
    });

  });
}

void main() async {
  initializeTimeZones();
  dotenv.load('.env/prod.env');
  var rootUrl = dotenv.env['ROOT_URL']!;
  tests(rootUrl);
}
