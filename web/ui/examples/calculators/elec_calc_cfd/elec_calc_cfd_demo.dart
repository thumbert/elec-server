
import 'dart:html';
import 'package:http/http.dart';
import 'package:timezone/data/latest.dart';

import 'elec_calc_cfd_app.dart';

Map<String,dynamic> _template1() =>  <String,dynamic>{
  'term': 'Jan21-Mar21',
  'asOfDate': '2020-05-29',
  'buy/sell': 'Buy',
  'comments': 'a simple calculator for winter times',
  'legs': [
    {
      'curveId': 'isone_energy_4000_da_lmp',
      'cash/physical': 'cash',
      'bucket': '5x16',
      'quantity': {'value': 50},
    }
  ],
};

void main() async {
  await initializeTimeZones();
  var client = Client();
  var rootUrl = 'http://localhost:8080/';


  var wrapper = querySelector('#wrapper-elec-calc-cfd');
  var app = ElecCalcCfdApp(wrapper, client: client, rootUrl: rootUrl);
  await app.fromJson(_template1());




//  var message = querySelector('#message');
//
//  var ac = TypeAhead(wrapper, countries, placeholder: 'Country name');
//  ac.onSelect((e) => message.text = 'You selected ${ac.value}');

}