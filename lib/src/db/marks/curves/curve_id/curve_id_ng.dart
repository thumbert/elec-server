library db.curves.curve_id.curve_id_ng;

List<Map<String, dynamic>> getCurves() {
  var xs = <Map<String, dynamic>>[
    {
      'curveId': 'ng_henryhub',
      'location': 'Henry Hub',
      'product': 'fixprice',
      'region': 'Gulf',
    },
    ..._getAgt(),
  ];

  for (var x in xs) {
    x.addAll(_defaults());
  }

  return xs;
}

List<Map<String, dynamic>> _getAgt() {
  var xs = <Map<String, dynamic>>[
    {
      'curveId': 'ng_agtcg_iferc_basis',
      'location': 'Agtcg',
      'product': 'iferc',
      'region': 'NorthEast',
    },
    {
      'curveId': 'ng_agtcg_iferc',
      'location': 'Agtcg',
      'product': 'iferc',
      'region': 'NorthEast',
      'rule': '[0] + [1]',
      'children': ['ng_henryhub', 'ng_agtcg_iferc_basis'],
    },
  ];

  return xs;
}

Map<String, dynamic> _defaults() {
  return <String, dynamic>{
    'serviceType': 'energy',
    'commodity': 'natural gas',
    'unit': '\$/MMBtu',
    'markType': 'scalar',
    'buckets': ['7x24'],
    'tzLocation': 'UTC',
  };
}
