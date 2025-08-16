library utils.list_extensions;

import 'package:build_html/build_html.dart';

extension HtmlExtension on List<List<String>> {
  Table toHtml() {
    var table = Table();
    var header = TableRow();
    for (var colName in first) {
      header.addCell(TableCell(TableCellType.header)..withRaw(colName));
    }
    for (var cells in skip(1)) {
      var row = TableRow();
      for (var cell in cells) {
        row.addCell(TableCell(TableCellType.data)..withRaw(cell));
      }
      table.addCustomBodyRow(row);
    }
    return table;
  }
}

extension IterableExtensions<E> on Iterable<E> {
  /// Partition an iterable based on a condition.
  /// First element (left) is the true condition, the second element (right)
  /// is the false condition.
  (List<E>, List<E>) partition(bool Function(E) predicate) {
    final left = <E>[];
    final right = <E>[];
    for (var e in this) {
      if (predicate(e)) {
        left.add(e);
      } else {
        right.add(e);
      }
    }
    return (left, right);
  }
}
