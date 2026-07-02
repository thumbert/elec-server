import 'package:date/date.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
import 'package:elec/risk_system.dart' hide LmpComponent;
import 'package:elec_server/client/caiso/lmp.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

Future<void> tests() async {
  group('Caiso LMP Tests', () {
    test('get hourly lmp prices', () async {
      final term =
          Term.parse('1Dec25-10Dec25', getLocation('America/Los_Angeles'));
      final data = await getHourlyLmpPrices(
        term: term,
        nodeNames: ['TH_NP16_GEN-APND', 'TH_SP15_GEN-APND'],
        market: Market.da,
        components: [LmpComponent.lmp],
        rootUrl: dotenv.env['RUST_SERVER']!,
      );
      print(data);

      expect(1 + 1, equals(2));
    });
  });
}

Future<void> main() async {
  initializeTimeZones();
  dotenv.load('.env/test.env');
  await tests();
}
