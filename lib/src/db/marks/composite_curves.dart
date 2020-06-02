library db.marks.composite_curves;

/// This will need to be in a DB.  Hardcoded for now.

/// Get the composite/derived curves
List<Map<String,dynamic>> getCompositeCurves() {
  var entries = <Map<String,dynamic>>[
    {
      'curveId': 'isone_elec_4001_da_lmp',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['isone_elec_4000_da_lmp', 'isone_elec_4001_basis_da'],
    },
    {
      'curveId': 'isone_elec_4002_da_lmp',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['isone_elec_4000_da_lmp', 'isone_elec_4002_basis_da'],
    },
    {
      'curveId': 'isone_elec_4004_da_lmp',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['isone_elec_4000_da_lmp', 'isone_elec_4004_basis_da'],
    },
    {
      'curveId': 'isone_elec_4005_da_lmp',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['isone_elec_4000_da_lmp', 'isone_elec_4005_basis_da'],
    },
    {
      'curveId': 'isone_elec_4006_da_lmp',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['isone_elec_4000_da_lmp', 'isone_elec_4006_basis_da'],
    },
    {
      'curveId': 'isone_elec_4008_da_lmp',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['isone_elec_4000_da_lmp', 'isone_elec_4008_basis_da'],
    },
    {
      'curveId': 'isone_elec_4011_da_lmp',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['isone_elec_4000_da_lmp', 'isone_elec_4011_basis_da'],
    },
  ];
  return entries;
}
