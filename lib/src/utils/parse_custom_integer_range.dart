library utils.parse_custom_integer_range;

/// Do the opposite of [parseCustomIntegerRange].  Go from an integer list
/// to a [String], e.g. '1-5, 8, 11-13'.
String packIntegerList(List<int> x) {
  if (x.isEmpty) return '';
  if (x.length == 1) return x.first.toString();
  x.sort();
  var out = <String>[];
  var current = x.first;
  for (var i = 1; i < x.length; i++) {
    if (x[i] == x[i - 1] + 1) {
      continue;
    } else {
      // a new run
      if (current == x[i - 1]) {
        out.add('$current');
      } else {
        out.add('$current-${x[i - 1]}');
      }
      current = x[i];
    }
  }
  if (current == x.last) {
    out.add('$current');
  } else {
    out.add('$current-${x.last}');
  }
  return out.join(', ');
}

@Deprecated('Use unpackIntegerList')
List<int> parseCustomIntegerRange(String x) => unpackIntegerList(x);

/// Parse a custom positive integer range, similar to Chrome's custom pages
/// print format e.g. '1-5, 8, 11-13', etc.
/// Useful for UI's
List<int> unpackIntegerList(String x) {
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
      out.addAll(List.generate(end - start + 1, (i) => i + start));
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
