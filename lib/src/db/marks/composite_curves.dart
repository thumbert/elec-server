library db.marks.composite_curves;

/// This will need to be in a DB.  Hardcoded for now.

/// Get the composite/derived curves
List<Map<String,dynamic>> getCompositeCurves() {
  var entries = <Map<String,dynamic>>[
    {
      'curveId': 'elec_isone_maine_lmp_da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_maine_spread_da'],
    },
    {
      'curveId': 'elec_isone_nh_lmp_da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_nh_spread_da'],
    },
    {
      'curveId': 'elec_isone_ct_lmp_da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_ct_spread_da'],
    },
    {
      'curveId': 'elec_isone_ri_lmp_da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_ri_spread_da'],
    },
    {
      'curveId': 'elec_isone_sema_lmp_da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_sema_spread_da'],
    },
    {
      'curveId': 'elec_isone_nema_lmp_da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_nema_spread_da'],
    },
    {
      'curveId': 'elec_isone_ptid:4011_lmp_da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec_isone_hub_lmp_da', 'elec_isone_ptid:4011_spread_da'],
    },
  ];
  return entries;
}
