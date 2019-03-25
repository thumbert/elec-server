import 'dart:html';
import 'package:intl/intl.dart';
import 'package:elec_server/src/utils/html_table.dart';

simpleTable() {
  var data = <Map<String, dynamic>>[
    {'airport': 'BOS', 'tmin': '22', 'tmax': '45'},
    {'airport': 'BWI', 'tmin': '27', 'tmax': '49'},
    {'airport': 'LGA', 'tmin': '25', 'tmax': '47'},
  ];
  HtmlTable(querySelector('#wrapper-simple-table'), data);
}

tableWithFormat() {
  var data = <Map<String, dynamic>>[
    {'date': DateTime(2018, 1), 'price': 85.24},
    {'date': DateTime(2018, 2), 'price': 73.1},
    {'date': DateTime(2018, 3), 'price': 55.93},
    {'date': DateTime(2018, 4), 'price': 38.06},
  ];

  var fmt = DateFormat('MMMyy');
  var dollar = NumberFormat.currency(symbol: '\$');

  var options = <String, dynamic>{
    'format': {
      'date': {'valueFormat': (DateTime dt) => fmt.format(dt)},
      'price': {'valueFormat': (x) => dollar.format(x)}
    }
  };
  HtmlTable(querySelector('#wrapper-table-format'), data, options: options);

  options['rowNumbers'] = true;
  HtmlTable(querySelector('#wrapper-table-format-rownumbers'), data,
      options: options);
}

main() {
  simpleTable();
  tableWithFormat();
}
