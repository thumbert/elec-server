library db.marks.composite_curves;

/// This will need to be in a DB.  Hardcoded for now.

/// Get the composite/derived curves
List<Map<String,dynamic>> getCompositeCurves() {
  var entries = <Map<String,dynamic>>[
    {
      'curveId': 'elec|iso:ne|zone:maine|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:maine|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:nh|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:nh|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:ct|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:ct|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:ri|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:ri|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:sema|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:sema|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|zone:nema|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|zone:nema|spread|da'],
    },
    {
      'curveId': 'elec|iso:ne|ptid:4011|lmp|da',
      'fromDate': '1999-12-31',
      'rule': 'add all',
      'children': ['elec|iso:ne|hub|lmp|da', 'elec|iso:ne|ptid:4011|spread|da'],
    },
  ];
  return entries;
}
