library db.marks.curve_attributes;

Set<String> getBucketsMarked(String curveId) {
  if (curveId.startsWith(RegExp('elec_{isone|pjm}'))) {
    return <String>{'5x16', '2x16H', '7x8'};
  } else if (curveId.startsWith('ng_')) {
    return <String>{'7x24'};
  }
  return <String>{};
}