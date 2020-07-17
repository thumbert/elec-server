library db.curves.curve_id.curve_id_isone;

import 'dart:convert';
import 'dart:io';
import 'package:elec/risk_system.dart';

var _zoneMap = Map.fromIterables(List.generate(9, (i) => 4000 + i),
    ['hub', 'maine', 'nh', 'vt', 'ct', 'ri', 'sema', 'wcma', 'nema']);

List<Map<String, dynamic>> getCurves() {
  var xs = [
    ...getArrCurves(),
    ...getEnergyCurves(),
    ...getFwdResCurves(),
    ...getOpResDaCurves(),
    ...getOpResRtCurves(),
  ];

  for (var x in xs) {
    x['commodity'] = 'electricity';
    x['region'] = 'isone';
    x['tzLocation'] = 'America/New_York';
  }

  return xs;
}

List<Map<String, dynamic>> getEnergyCurves() {
  var out = <Map<String, dynamic>>[];

  /// LMP and congestion curves for all the zones, DA and RT
  /// isone_energy_4000_da_lmp, isone_energy_4000_rt_lmp,
  /// isone_energy_4000_da_congestion, isone_energy_4000_rt_congestion
  var components = [LmpComponent.lmp, LmpComponent.congestion];
  var markets = [Market.da, Market.rt];

  for (var ptid in _zoneMap.keys) {
    for (var component in components) {
      for (var market in markets) {
        var aux = '${market.name}_${component.name}'.toLowerCase();
        var one = <String, dynamic>{
          'curveId': 'isone_energy_${ptid}_${aux}', // isone_energy_4000_da_lmp
          'serviceType': 'energy',
          'ptid': ptid,
          'market': market.name.toLowerCase(),
          'lmpComponent': component.name,
          'curve': '${_zoneMap[ptid]}_${aux}', // 'hub_da_lmp'
          'unit': '\$/MWh',
          'buckets': ['5x16', '2x16H', '7x8'],
          'hourlyShapeCurveId': 'isone_energy_4000_hourlyshape',
        };

        /// for the zonal da lmp curves, add the marking rule (experimental)
        if (ptid != 4000 &&
            market == Market.da &&
            component == LmpComponent.lmp) {
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

    /// add the basis curves, isone_energy_4001_da_basis
    if (ptid != 4000) {
      out.add({
        'curveId': 'isone_energy_${ptid}_da_basis',
        'serviceType': 'energy',
        'ptid': ptid,
        'market': 'da',
        'curve': '${_zoneMap[ptid]}_da_basis', // 'hub_da_basis'
        'unit': '\$/MWh',
        'buckets': ['5x16', '2x16H', '7x8'],
      });
    }

    /// add hourly shape curve
    out.add({
      'curveId': 'isone_energy_4000_hourlyshape',
      'unit': 'dimensionless',
      'buckets': ['5x16', '2x16H', '7x8'],
    });
  }

  return out;
}

List<Map<String, dynamic>> getArrCurves() {
  return [
    for (var ptid in _zoneMap.keys.where((e) => e != 4000))
      <String, dynamic>{
        'curveId': 'isone_arr_${_zoneMap[ptid]}', // isone_arr_ri
        'serviceType': 'arr',
        'curve': '${_zoneMap[ptid]}',
        'unit': '\$/MW-month',
        'buckets': ['7x24'],
      }
  ];
}

List<Map<String, dynamic>> getFwdResCurves() {
  return [
    for (var ptid in _zoneMap.keys.where((e) => e != 4000))
      <String, dynamic>{
        'curveId': 'isone_fwdres_${_zoneMap[ptid]}', // isone_fwdres_ri
        'serviceType': 'fwdres',
        'curve': '${_zoneMap[ptid]}',
        'unit': '\$/MW-month',
        'buckets': ['5x16'],
      }
  ];
}

List<Map<String, dynamic>> getOpResDaCurves() {
  return [
      <String, dynamic>{
        'curveId': 'isone_opres_da_pool',
        'serviceType': 'opres',
        'market': 'da',
        'curve': 'pool_da',
        'unit': '\$/MWh',
        'buckets': ['7x24'],
      }
  ];
}

List<Map<String, dynamic>> getOpResRtCurves() {
  return [
    for (var ptid in _zoneMap.keys.where((e) => e != 4000))
      <String, dynamic>{
        'curveId': 'isone_opres_rt_${_zoneMap[ptid]}', // isone_opres_rt_ri
        'serviceType': 'opres',
        'market': 'rt',
        'curve': '${_zoneMap[ptid]}_rt',
        'unit': '\$/MWh',
        'buckets': ['7x24'],
      }
  ];
}
