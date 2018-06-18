import 'dart:html';
import 'package:intl/intl.dart';

class Table {
  Element tableWrapper;
  List<Map<String,dynamic>> data;
  Map options;

  TableElement table;
  List<Element> _tableHeaders;
  List<String> _columnNames;
  List<int> _sortDirection;

  /// A simple html table with sorting.
  /// The [options] Map can be used to specify a format function for a
  /// given column, e.g. {'columnName': {'valueFormat': (num x) => x.round()}}
  /// By default the table has column names.
  /// If you don't want column names, use {'noColumnNames': true}
  Table(this.tableWrapper, this.data, {this.options}) {
    options ??= {};
    _columnNames = data.first.keys.toList();
    _tableHeaders = new List(_columnNames.length);
    _sortDirection = new List(_columnNames.length);
    _makeTable();
  }

  _makeTable() {
    table = new TableElement();
    table.createTHead();
    // make the table header
    TableRowElement headerRow = table.tHead.insertRow(0);
    for (int i=0; i<_columnNames.length; i++) {
      _tableHeaders[i] =  new Element.th();
      if (options.containsKey('noColumnNames') && options['noColumnNames']) {
        _tableHeaders[i].text = '';
      } else {
        _tableHeaders[i].text = _columnNames[i];
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
          tRow..insertCell(j).text = aux;
        } else {
          tRow..insertCell(j).text = values[j];
        }
      }
    }
    /// if you already have a table, remove it before you add it back to the dom
    if (tableWrapper.children.length > 0)
      tableWrapper.children = [];
    tableWrapper.append(table);
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
