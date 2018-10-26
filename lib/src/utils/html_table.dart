import 'dart:html';
import 'package:intl/intl.dart';


class HtmlTable {
  Element tableWrapper;
  List<Map<String,dynamic>> data;
  Map<String,dynamic> options;

  TableElement table;
  List<Element> _tableHeaders;
  List<String> _columnNames;
  List<int> _sortDirection;

  /// A simple html table with sorting.
  /// The [options] Map can be used to specify a format function for a
  /// given column, e.g. {'columnName': {'valueFormat': (num x) => x.round()}}
  /// By default the table has column names.
  /// <p>If you don't want column names, use {'noColumnNames': true}, the default
  ///   is [false].
  ///
  /// To add row numbers, use {'rowNumbers': true}, the default is false;
  ///
  /// Use a [null] [tableWrapper] if you are interested in the html only.  
  HtmlTable(this.tableWrapper, this.data, {this.options}) {
    options ??= <String,dynamic>{};
    options.putIfAbsent('makeHeader', () => true);
    options.putIfAbsent('rowNumbers', () => false);

    if (options['rowNumbers']) {
      for (int i=0; i<data.length; i++) {
        data[i] = <String,dynamic>{'#':i+1}..addAll(data[i]);
      }
    }

    /// Get the column names from the keys of the first element
    _columnNames = data.first.keys.toList();
    _tableHeaders = List<Element>(_columnNames.length);
    _sortDirection = List<int>(_columnNames.length);
    _makeTable();
  }

  _makeTable() {
    table = new TableElement();
    table.createTHead();
    // make the table header
    TableRowElement headerRow = table.tHead.insertRow(0);
    for (int i=0; i<_columnNames.length; i++) {
      _tableHeaders[i] =  new Element.th();
      if (options['makeHeader']) {
        _tableHeaders[i].text = _columnNames[i];
      } else {
        _tableHeaders[i].text = '';
      }
      _tableHeaders[i].onClick.listen((e) => _sortByColumn(i));
      headerRow.nodes.add(_tableHeaders[i]);
    }
    // make the table body
    var tBody = table.createTBody();
    for (int r=0; r<data.length; r++) {
      List values = data[r].values.toList();
      var tRow = tBody.insertRow(r);
      for (int j=0; j<_columnNames.length; j++) {
        if (options.containsKey(_columnNames[j]) && (options[_columnNames[j]].containsKey('valueFormat'))) {
          var aux = options[_columnNames[j]]['valueFormat'](values[j]);
          tRow..insertCell(j).text = aux.toString();
        } else {
          tRow..insertCell(j).text = values[j].toString();
        }
      }
    }


    if (tableWrapper != null) {
      /// if you already have a table, remove it before you add it back to the dom
      if (tableWrapper.children.length > 0)
        tableWrapper.children = [];
      tableWrapper.append(table);
    }
  }

  /// If you click on a header, sort the data.
  _sortByColumn(int i) {
    if (_sortDirection[i] == null) {
      _sortDirection[i] = 1;
    } else {
      _sortDirection[i] *= -1;
    }
    data.sort((a,b) => (_sortDirection[i]*(a[_columnNames[i]].compareTo(b[_columnNames[i]]) as num).toInt()));
    _makeTable();
  }

}

