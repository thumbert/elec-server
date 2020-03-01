library db.marks.composite_curves;

/// This will need to be in a DB.  Hardcoded for now.

/// Get the composite/derived curves
List<Map<String,dynamic>> getCompositeCurves() {
  var entries = <Map<String,dynamic>>[
    {
      'curveId': 'elec_isone_maine_lmp_da',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_maine_basis_da'],
    },
    {
      'curveId': 'elec_isone_nh_lmp_da',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_nh_basis_da'],
    },
    {
      'curveId': 'elec_isone_ct_lmp_da',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_ct_basis_da'],
    },
    {
      'curveId': 'elec_isone_ri_lmp_da',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_ri_basis_da'],
    },
    {
      'curveId': 'elec_isone_sema_lmp_da',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_sema_basis_da'],
    },
    {
      'curveId': 'elec_isone_nema_lmp_da',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_nema_basis_da'],
    },
    {
      'curveId': 'elec_isone_ptid:4011_lmp_da',
      'fromDate': '1999-12-31',
      'rule': '[0] + [1]',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_ptid:4011_basis_da'],
    },
  ];
  return entries;
}
