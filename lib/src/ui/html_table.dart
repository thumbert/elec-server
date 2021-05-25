library ui.html_table;

import 'dart:html';

/// See the example in web/ui/html_table for how to set the style of the table.

class HtmlTable {
  Element? wrapper;
  DivElement? _wrapper;
  List<Map<String, dynamic>> data;
  Map<String, dynamic>? options;

  late TableElement table;
  late List<Element?> _tableHeaders;
  List<String>? _columnNames;
  late List<int?> _sortDirection;
  late Map<String, Function?> _valueFormat;

  /// A simple html table with sorting.
  ///
  /// The [options] Map can be used to customize the table appearance.
  ///
  /// Set options['format'] to specify a format function for a
  /// given column, e.g.
  /// {'format': {'columnName': {'valueFormat': (num x) => x.round()}}}
  ///
  /// By default the table has column names taken from the first data row.
  /// If you don't want column names, use options['makeHeader'] = false,
  /// the default value is [true].
  ///
  /// In case of incomplete data (missing cells) you can specify the table
  /// columns with options['columnNames'] = <String>[...].  Missing data
  /// is rendered as a blank.
  ///
  /// To add row numbers, use options['rowNumbers'] = true, the default is
  /// false.
  ///
  /// To export table: options['export'] = {'format': 'xlsx'}
  /// To copy table to clipboard: options['copy'] = {'separator': '|'}
  ///
  HtmlTable(this.wrapper, this.data, {this.options}) {
    options ??= <String, dynamic>{};
    options!.putIfAbsent('makeHeader', () => true);
    options!.putIfAbsent('rowNumbers', () => false);
    options!.putIfAbsent('format', () => {});
    options!.putIfAbsent('export', () => {});
//    options.putIfAbsent('copy', () => {});

    if (options!['rowNumbers']) {
      for (var i = 0; i < data.length; i++) {
        data[i] = <String, dynamic>{'#': i + 1}..addAll(data[i]);
      }
    }

    if (options!.containsKey('columnNames')) {
      _columnNames = options!['columnNames'];
    } else {
      /// Get the column names from the keys of the first element
      _columnNames = data.first.keys.toList();
    }

    _tableHeaders = List<Element?>.filled(_columnNames!.length, null);
    _sortDirection = List<int?>.filled(_columnNames!.length, null);

    _valueFormat = {};
    if (options!.containsKey('format')) {
      var aux = options!['format'] as Map?;
      for (var name in _columnNames!) {
        if (aux!.containsKey(name)) {
          var bux = aux[name] as Map;
          if (bux.containsKey('valueFormat')) {
            _valueFormat[name] = bux['valueFormat'];
          }
        }
      }
    }

    _makeTable();
  }

  void _makeTable() {
    table = TableElement();
    table.createTHead();
    // make the table header
    var headerRow = table.tHead!.insertRow(0);
    for (var i = 0; i < _columnNames!.length; i++) {
      _tableHeaders[i] = Element.th();
      if (options!['makeHeader']) {
        _tableHeaders[i]!.text = _columnNames![i];
      } else {
        _tableHeaders[i]!.text = '';
      }
      _tableHeaders[i]!.onClick.listen((e) => _sortByColumn(i));
      headerRow.nodes.add(_tableHeaders[i]!);
    }

    // make the table body
    var tBody = table.createTBody();
    for (var r = 0; r < data.length; r++) {
      var tRow = tBody.insertRow(r);
      for (var j = 0; j < _columnNames!.length; j++) {
        var name = _columnNames![j];
        String? value = '';
        if (data[r].containsKey(name)) {
          if (_valueFormat.containsKey(name)) {
            value = _valueFormat[name]!(data[r][name]);
          } else {
            value = data[r][name].toString();
          }
        }
        tRow..insertCell(j).text = value;
      }
    }

    if (wrapper != null) {
      /// if you already have a table, remove it before you add it back to
      /// the dom not sure why do I have this? 1/6/2020.
      if (wrapper!.children.isNotEmpty) {
        wrapper!.children = [];
      }
      if ((options!['export'] as Map).isNotEmpty) {
        wrapper!.append(ImageElement(
            src: 'assets/spreadsheet_icon.png', width: 20, height: 20)
          ..onClick.listen((e) => _save()));
      }
//      if ((options['copy'] as Map).isNotEmpty) {
//        wrapper.append(ImageElement(
//            src: 'assets/copy_icon.png', width: 20, height: 20)
//          ..onClick.listen((e) => _copy()));
//      }
      wrapper!.append(table);
    }
  }

  /// See this example for saving to CSV, maybe works on Windows.
  /// Current function just saves the html table.
  void _save() {
    var downloadLink = document.createElement('a') as AnchorElement;
    document.body!.append(downloadLink);
    downloadLink.href = 'data:application/vnd.ms-excel, ' + table.outerHtml!;
    downloadLink.download = 'data.xlsx';
    downloadLink.click();
  }

//  void _copy() {
//    table.onSelect.listen((e) => document.execCommand('copy'));
//  }

  /// If you click on a header, sort the data.
  void _sortByColumn(int i) {
    if (_sortDirection[i] == null) {
      _sortDirection[i] = 1;
    } else {
      _sortDirection[i] = -1 * _sortDirection[i]!;
    }
    data.sort((a, b) => (_sortDirection[i]! *
        (a[_columnNames![i]].compareTo(b[_columnNames![i]]) as num).toInt()));
    _makeTable();
  }
}
