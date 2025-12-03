import 'package:elec/risk_system.dart';

final _zoneMap = Map.fromIterables(List.generate(9, (i) => 4000 + i),
    ['hub', 'maine', 'nh', 'vt', 'ct', 'ri', 'sema', 'wcma', 'nema']);

final _markedPtids = <int, String>{
  4011: 'roseton',
};

List<Map<String, dynamic>> getCurves() {
  var xs = [
    ...getArrCurves(),
    ...getEnergyCurves(),
    ...getFwdResCurves(),
    ...getNodalCurves(),
    ...getOpResDaCurves(),
    ...getOpResRtCurves(),
  ];

  for (var x in xs) {
    x['commodity'] = 'electricity';
    x['region'] = 'isone';
    x['tzLocation'] = 'America/New_York';
  }

  xs.addAll(getVolatilityCurves());

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
          'curveId': 'isone_energy_${ptid}_$aux', // isone_energy_4000_da_lmp
          'serviceType': 'energy',
          'ptid': ptid,
          'market': market.name.toLowerCase(),
          'lmpComponent': component.name,
          'location': _zoneMap[ptid], // hub, ct, etc.
          'curve': '${_zoneMap[ptid]}_$aux', // 'hub_da_lmp'
          'unit': '\$/MWh',
          'buckets': ['5x16', '2x16H', '7x8'],
          'hourlyShapeCurveId': 'isone_energy_4000_hourlyshape',
          'markType': 'scalar',
        };

        /// For the zonal da lmp curves, add the marking rule (experimental)
        if (ptid != 4000 &&
            market == Market.da &&
            component == LmpComponent.lmp) {
          one.addAll(<String, dynamic>{
            'rule': '[0] + [1]',
            'children': [
              'isone_energy_4000_da_lmp',
              'isone_energy_${ptid}_da_basis',
            ],
          });
        }

        /// For the hub da lmp curves, add the volatility curves
        if (ptid == 4000 &&
            market == Market.da &&
            component == LmpComponent.lmp) {
          one.addAll(<String, dynamic>{
            'volatilityCurveId': {
              'daily': 'isone_volatility_4000_da_daily',
              'monthly': 'isone_volatility_4000_da_monthly',
            },
          });
        }
        out.add(one);
      }
    }

    /// Add the basis curves, isone_energy_4001_da_basis
    if (ptid != 4000) {
      out.add(<String, dynamic>{
        'curveId': 'isone_energy_${ptid}_da_basis',
        'serviceType': 'energy',
        'ptid': ptid,
        'market': 'da',
        'location': _zoneMap[ptid],
        'curve': '${_zoneMap[ptid]}_da_basis', // 'hub_da_basis'
        'unit': '\$/MWh',
        'buckets': ['5x16', '2x16H', '7x8'],
        'markType': 'scalar',
      });
    }
  }

  /// add hourly shape curve
  out.add(<String, dynamic>{
    'curveId': 'isone_energy_4000_hourlyshape',
    'unit': 'dimensionless',
    'ptid': 4000,
    'buckets': ['5x16', '2x16H', '7x8'],
    'markType': 'hourlyShape',
  });

  return out;
}

List<Map<String, dynamic>> getArrCurves() {
  return [
    for (var ptid in _zoneMap.keys.where((e) => e != 4000))
      <String, dynamic>{
        'curveId': 'isone_arr_${_zoneMap[ptid]}', // isone_arr_ri
        'serviceType': 'arr',
        'location': _zoneMap[ptid],
        'curve': _zoneMap[ptid],
        'unit': '\$/MW-month',
        'buckets': ['7x24'],
        'markType': 'scalar',
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
        'location': _zoneMap[ptid],
        'unit': '\$/MW-month',
        'buckets': ['5x16'],
        'markType': 'scalar',
      }
  ];
}

/// For each nodal location, add an LMP, basis, congestion, lossfactor curve
List<Map<String, dynamic>> getNodalCurves() {
  var out = <Map<String, dynamic>>[];
  for (var ptid in _markedPtids.keys) {
    // the LMP curve
    out.add({
      'curveId': 'isone_energy_${ptid}_da_lmp',
      'serviceType': 'energy',
      'ptid': ptid,
      'market': 'da',
      'lmpComponent': 'lmp',
      'curve': '${_markedPtids[ptid]}_da_lmp',
      'unit': '\$/MWh',
      'buckets': ['5x16', '2x16H', '7x8'],
      'hourlyShapeCurveId': 'isone_energy_4000_hourlyshape',
      'markType': 'scalar',
      'rule': '[0] + [1] + [0] * [2]',
      'children': [
        'isone_energy_4000_da_lmp',
        'isone_energy_${ptid}_da_congestion',
        'isone_energy_${ptid}_da_lossfactor',
      ],
    });
    // the basis curve
    out.add({
      'curveId': 'isone_energy_${ptid}_da_basis',
      'serviceType': 'energy',
      'ptid': ptid,
      'market': 'da',
      'lmpComponent': 'lmp',
      'curve': '${_markedPtids[ptid]}_da_basis',
      'unit': '\$/MWh',
      'buckets': ['5x16', '2x16H', '7x8'],
      'markType': 'scalar',
      'rule': '[0] - [1]',
      'children': [
        'isone_energy_${ptid}_da_lmp',
        'isone_energy_4000_da_lmp',
      ],
    });
    // the congestion curve
    out.add({
      'curveId': 'isone_energy_${ptid}_da_congestion',
      'serviceType': 'energy',
      'ptid': ptid,
      'market': 'da',
      'lmpComponent': 'congestion',
      'curve': '${_markedPtids[ptid]}_da_congestion',
      'unit': '\$/MWh',
      'buckets': ['5x16', '2x16H', '7x8'],
      'markType': 'scalar',
    });
    // the lossfactor curve
    out.add({
      'curveId': 'isone_energy_${ptid}_da_lossfactor',
      'serviceType': 'energy',
      'ptid': ptid,
      'market': 'da',
      'lmpComponent': 'congestion',
      'curve': '${_markedPtids[ptid]}_da_congestion',
      'unit': 'dimensionless',
      'buckets': ['5x16', '2x16H', '7x8'],
      'markType': 'scalar',
    });
  }

  return out;
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
      'markType': 'scalar',
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
        'location': _zoneMap[ptid],
        'curve': '${_zoneMap[ptid]}_rt',
        'unit': '\$/MWh',
        'buckets': ['7x24'],
        'markType': 'scalar',
      }
  ];
}

List<Map<String, dynamic>> getVolatilityCurves() {
  return [
    <String, dynamic>{
      'curveId': 'isone_volatility_4000_da_daily',
      'unit': 'dimensionless',
      'buckets': ['5x16', '2x16H', '7x8'],
      'markType': 'volatilitySurface',
      'commodity': 'volatility',
      'region': 'isone',
      'tzLocation': 'America/New_York',
    },
    <String, dynamic>{
      'curveId': 'isone_volatility_4000_da_monthly',
      'unit': 'dimensionless',
      'buckets': ['5x16', '2x16H', '7x8'],
      'markType': 'volatilitySurface',
      'commodity': 'volatility',
      'region': 'isone',
      'tzLocation': 'America/New_York',
    },
  ];
}
