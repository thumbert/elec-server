library test.db.ieso.rt_zonal_demand_test;

import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec_server/client/ieso/ieso_client.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart';

Future<void> tests(String rootUrl, String rustServer) async {
  //
  group('IESO node table client tests:', () {
    var client = IesoClient(http.Client(), rootUrl: rootUrl, rustServer: rustServer);
    test('get node table', () async {
      var aux = await client.getNodeTable();
      expect(aux.length, greaterThan(0));
      expect(aux.first.$1, "AREA");
      expect(aux.first.$2, "ONTARIO");
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
