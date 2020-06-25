library utils.parse_custom_integer_range;

/// Parse a custom positive integer range, similar to Chrome's custom pages
/// print format e.g. '1-5, 8, 11-13', etc.
/// Useful for UI's
List<int> parseCustomIntegerRange(String x) {
  var rs = x.split(',').map((e) => e.trim());
  var out = <int>[];
  for (var r in rs) {
    if (r.contains('-')) {
      var aux = r.split('-');
      if (aux.length != 2) {
        throw ArgumentError('Problem parsing range $r from $x');
      }
      var start = int.parse(aux[0]);
      var end = int.parse(aux[1]);
      out.addAll(List.generate(end-start+1, (i) => i + start));
    } else {
      var aux = int.parse(r);
      if (aux < 0) {
        throw ArgumentError('Problem parsing integer $r from $x. '
            'All integers need to be positive.');
      }
      out.add(int.parse(r));
    }
  }
  return out;
}