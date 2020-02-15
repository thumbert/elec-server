library db.marks.curve_attributes;


Set<String> getBucketsMarked(String curveId) {
  if (curveId.startsWith(RegExp('elec\|{iso:ne|iso:pjm}'))) {
    return <String>{'5x16', '2x16H', '7x8'};
  } else if (curveId.startsWith('ng|')) {
    return <String>{'7x24'};
  }
  return <String>{};
}