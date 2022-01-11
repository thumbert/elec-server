library db.curves.curve_id.curve_id_ng;

List<Map<String, dynamic>> getCurves() {
  var xs = <Map<String, dynamic>>[
    {
      'curveId': 'ng_henryhub',
      'location': 'Henry Hub',
      'product': 'fixprice',
      'region': 'Gulf',
    },
    {
      'curveId': 'ng_henryhub',
      'location': 'Henry Hub',
      'product': 'iferc',
      'region': 'Gulf',
    },
    {
      'curveId': 'ng_henryhub',
      'location': 'Henry Hub',
      'product': 'gasdaily',
      'region': 'Gulf',
    },
    ..._getAgt(),
    ..._getEasternGasSouth(),
    ..._getIroquoisZ2(),
    ..._getTetcoM3(),
    ..._getTranscoZ6NY(),
    ..._getTranscoZ6NNY(),
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
      'region': 'Northeast',
    },
    {
      'curveId': 'ng_agtcg_iferc',
      'location': 'Agtcg',
      'product': 'iferc',
      'region': 'NorthEast',
      'rule': '[0] + [1]',
      'children': ['ng_henryhub', 'ng_agtcg_iferc_basis'],
    },
    {
      'curveId': 'ng_agtcg_iferc_gasdaily',
      'location': 'Agtcg',
      'product': 'iferc',
      'region': 'Northeast',
    },
  ];
  return xs;
}

/// Formerly known as Dominion Gas
List<Map<String, dynamic>> _getEasternGasSouth() {
  var xs = <Map<String, dynamic>>[
    {
      'curveId': 'ng_easterngassouth_iferc_basis',
      'location': 'Eastern Gas, South',
      'product': 'iferc',
      'region': 'Appalachia',
    },
    {
      'curveId': 'ng_easterngassouth_iferc',
      'location': 'Eastern Gas, South',
      'product': 'iferc',
      'region': 'Appalachia',
      'rule': '[0] + [1]',
      'children': ['ng_henryhub', 'ng_easterngassouth_iferc_basis'],
    },
    {
      'curveId': 'ng_easterngassouth_gasdaily',
      'location': 'Eastern Gas, South',
      'product': 'gasdaily',
      'region': 'Appalachia',
    },
  ];
  return xs;
}

List<Map<String, dynamic>> _getIroquoisZ2() {
  var xs = <Map<String, dynamic>>[
    {
      'curveId': 'ng_iroquoisz2_iferc_basis',
      'location': 'Iroquois, Z2',
      'product': 'iferc',
      'region': 'Northeast',
    },
    {
      'curveId': 'ng_iroquoisz2_iferc',
      'location': 'Iroquois, Z2',
      'product': 'iferc',
      'region': 'NorthEast',
      'rule': '[0] + [1]',
      'children': ['ng_henryhub', 'ng_agtcg_iferc_basis'],
    },
    {
      'curveId': 'ng_iroquoisz2_iferc_gasdaily',
      'location': 'Iroquois, Z2',
      'product': 'gasdaily',
      'region': 'Northeast',
    },
  ];
  return xs;
}

List<Map<String, dynamic>> _getTetcoM3() {
  var xs = <Map<String, dynamic>>[
    {
      'curveId': 'ng_tetcom3_iferc_basis',
      'location': 'Tetco, M3',
      'product': 'iferc',
      'region': 'Northeast',
    },
    {
      'curveId': 'ng_tetcom3_iferc',
      'location': 'Tetco, M3',
      'product': 'iferc',
      'region': 'Northeast',
      'rule': '[0] + [1]',
      'children': ['ng_henryhub', 'ng_tetcom3_iferc_basis'],
    },
    {
      'curveId': 'ng_tetcom3_gasdaily',
      'location': 'Tetco, M3',
      'product': 'gasdaily',
      'region': 'Northeast',
    },
  ];
  return xs;
}

List<Map<String, dynamic>> _getTranscoZ6NY() {
  var xs = <Map<String, dynamic>>[
    {
      'curveId': 'ng_transcoz6ny_iferc_basis',
      'location': 'Transco, Z6 NY',
      'product': 'iferc',
      'region': 'Northeast',
    },
    {
      'curveId': 'ng_transcoz6ny_iferc',
      'location': 'Transco, Z6 NY',
      'product': 'iferc',
      'region': 'Northeast',
      'rule': '[0] + [1]',
      'children': ['ng_henryhub', 'ng_transcoz6ny_iferc_basis'],
    },
    {
      'curveId': 'ng_transcoz6ny_gasdaily',
      'location': 'Transco, Z6 NY',
      'product': 'gasdaily',
      'region': 'Northeast',
    },
  ];
  return xs;
}

List<Map<String, dynamic>> _getTranscoZ6NNY() {
  var xs = <Map<String, dynamic>>[
    {
      'curveId': 'ng_transcoz6nny_iferc_basis',
      'location': 'Transco, Z6 Non-NY',
      'product': 'iferc',
      'region': 'Northeast',
    },
    {
      'curveId': 'ng_transcoz6nny_iferc',
      'location': 'Transco, Z6 Non-NY',
      'product': 'iferc',
      'region': 'Northeast',
      'rule': '[0] + [1]',
      'children': ['ng_henryhub', 'ng_transcoz6nny_iferc_basis'],
    },
    {
      'curveId': 'ng_transcoz6nny_gasdaily',
      'location': 'Transco, Z6 Non-NY',
      'product': 'gasdaily',
      'region': 'Northeast',
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
