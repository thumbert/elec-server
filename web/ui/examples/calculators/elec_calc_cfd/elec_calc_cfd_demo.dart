
import 'dart:html';
import 'package:http/http.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/cache_provider.dart';
import 'package:elec_server/src/ui/maya/elec_calc_cfd/elec_calc_cfd_app.dart';

Map<String,dynamic> _template1() =>  <String,dynamic>{
  'term': 'Jan21-Mar21',
  'asOfDate': '2020-05-29',
  'buy/sell': 'Buy',
  'comments': 'a simple calculator for winter times',
  'legs': [
    {
      'curveId': 'isone_energy_4000_da_lmp',
      'bucket': '5x16',
      'quantity': {'value': 50},
    }
  ],
};

void main() async {
  await initializeTimeZones();
  var rootUrl = 'http://localhost:8080/';
  var wrapper = querySelector('#wrapper-elec-calc-cfd');
  var cacheProvider = CacheProvider.test(client: Client(), rootUrl: rootUrl);
  var app = ElecCalcCfdApp(wrapper, cacheProvider);
  await app.fromJson(_template1());




//  var message = querySelector('#message');
//
//  var ac = TypeAhead(wrapper, countries, placeholder: 'Country name');
//  ac.onSelect((e) => message.text = 'You selected ${ac.value}');

}