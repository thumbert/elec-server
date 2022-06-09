library utils.parse_custom_integer_range;

/// Do the opposite of [unpackIntegerList].  Go from a list of positive
/// integers to a [String], e.g. '1-5, 8, 11-13'.
/// The empty list is packed as ''.
/// Input list [x] does not need to be sorted in order to allow packing of
/// [11, 12, 1, 2, 3] as '11-3'.
///
/// Note: No checks are made to ensure that the list values are between
/// min and max value.
String packIntegerList(List<int> x, {int? minValue, int? maxValue}) {
  if (x.isEmpty) return '';
  if (x.length == 1) return x.first.toString();
  var out = <String>[];
  var current = x.first;
  for (var i = 1; i < x.length; i++) {
    if (x[i] == x[i - 1] + (minValue ?? 1)) {
      // run continues
      continue;
    } else {
      // a new run
      if (current == x[i - 1]) {
        out.add('$current');
      } else {
        if (x[i - 1] == maxValue) {
          continue;
        }
        out.add('$current-${x[i - 1]}');
      }
      current = x[i];
    }
  }
  // add the last group
  if (current == x.last) {
    out.add('$current');
  } else {
    out.add('$current-${x.last}');
  }
  return out.join(', ');
}

// String packIntegerRange(List<int> x, {int? minValue, int? maxValue}) {
//   if (x.isEmpty) return '';
//   if (x.length == 1) return x.first.toString();
//   var out = <String>[];
//   var current = x.first;
//   for (var i = 1; i < x.length; i++) {
//     if (x[i] == x[i - 1] + 1) {
//       continue;
//     } else {
//       // a new run
//       if (current == x[i - 1]) {
//         out.add('$current');
//       } else {
//         out.add('$current-${x[i - 1]}');
//       }
//       current = x[i];
//     }
//   }
//   // add the last group
//   if (current == x.last) {
//     out.add('$current');
//   } else {
//     out.add('$current-${x.last}');
//   }
//   return out.join(', ');
// }

@Deprecated('Use unpackIntegerList')
List<int> parseCustomIntegerRange(String x) => unpackIntegerList(x);

/// Parse a custom positive integer range, similar to Chrome's custom pages
/// print format e.g. '1-5, 8, 11-13', etc.
/// Also, allow parsing of a range not sorted, e.g. '11-3' to represent Nov-Mar
/// Useful for UI's
List<int> unpackIntegerList(String x, {int? minValue, int? maxValue}) {
  if (x == '') return <int>[];
  var rs = x.split(',').map((e) => e.trim());
  var out = <int>[];
  for (var r in rs) {
    if (r.contains('-')) {
      out.addAll(unpackIntegerRange(r, minValue: minValue, maxValue: maxValue));
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

/// Parse '2-6', or '11-3'.
/// For a range of months of the year, [minValue] = 1, [maxValue] = 12.
List<int> unpackIntegerRange(String x, {int? minValue, int? maxValue}) {
  var out = <int>[];
  var aux = x.split('-');
  if (aux.length != 2) {
    throw ArgumentError('Problem parsing range $x');
  }
  var start = int.parse(aux[0]);
  var end = int.parse(aux[1]);
  if (end < start) {
    if (maxValue == null || minValue == null) {
      throw ArgumentError('minValue and maxValue both need to be non-null');
    }
    out.addAll(List.generate(maxValue - start + 1, (i) => i + start));
    out.addAll(List.generate(end - minValue + 1, (i) => i + minValue));
  } else {
    out.addAll(List.generate(end - start + 1, (i) => i + start));
  }
  return out;
}
