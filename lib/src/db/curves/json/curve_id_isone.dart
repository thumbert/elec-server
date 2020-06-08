library db.curves.json.curve_id_isone;

import 'dart:convert';
import 'dart:io';

import 'package:elec/risk_system.dart';

Future<List<Map<String, dynamic>>> getCurves() async {
  var out = <Map<String, dynamic>>[];
  var components = [LmpComponent.lmp, LmpComponent.congestion];
  var markets = [Market.da, Market.rt];
  var ptids = List.generate(9, (i) => 4000 + i);
  var _zoneMap = Map.fromIterables(
      ptids, ['hub', 'maine', 'nh', 'vt', 'ct', 'ri', 'sema', 'wcma', 'nema']);

  for (var ptid in ptids) {
    for (var component in components) {
      for (var market in markets) {
        var aux = '${market.name}_${component.name}'.toLowerCase();
        var one = <String, dynamic>{
          'curveId': 'isone_energy_${ptid}_${aux}',
          'region': 'isone',
          'serviceType': 'energy',
          'ptid': ptid,
          'market': market.name.toLowerCase(),
          'lmpComponent': component.name,
          'curve': '${_zoneMap[ptid]}_${aux}', // 'hub_da_lmp'
        };
        if (ptid != 4000 && market == Market.da) {
          one.addAll({
            'rule': '[0] + [1]',
            'children': [
              'isone_energy_4000_da_lmp',
              'isone_energy_${ptid}_da_basis',
            ],
          });
        }
        out.add(one);
      }
    }
  }

  /// load ancillaries & capacity curves
  var xs = jsonDecode(File('curve_id_isone.json').readAsStringSync()) as List;
  out.addAll([for (Map<String, dynamic> x in xs) x]);

  return out;
}
