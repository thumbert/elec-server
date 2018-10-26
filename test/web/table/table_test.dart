

import 'dart:html';
import 'package:intl/intl.dart';
import 'package:elec_server/src/utils/html_table.dart';


simpleTable() {
  var data = <Map<String,dynamic>>[
    {'airport': 'BOS', 'tmin': '22', 'tmax': '45'},
    {'airport': 'BWI', 'tmin': '27', 'tmax': '49'},
    {'airport': 'LGA', 'tmin': '25', 'tmax': '47'},
  ];
  new HtmlTable(querySelector('#wrapper-simple-table'), data);
}

tableWithFormat() {
  var data = <Map<String,dynamic>>[
    {'date': new DateTime(2018,1), 'price': 85.24},
    {'date': new DateTime(2018,2), 'price': 73.1},
    {'date': new DateTime(2018,3), 'price': 55.93},
    {'date': new DateTime(2018,4), 'price': 38.06},
  ];

  var fmt = new DateFormat('MMMyy');
  var dollar = new NumberFormat.currency(symbol: '\$');

  var options = <String,dynamic>{
    'date': {
      'valueFormat': (DateTime dt) => fmt.format(dt)
    },
    'price': {
      'valueFormat': (x) => dollar.format(x)
    }
  };
  new HtmlTable(querySelector('#wrapper-table-format'), data, options: options);

  options['rowNumbers'] = true;
  new HtmlTable(querySelector('#wrapper-table-format-rownumbers'), data, options: options);
}



main() {
  simpleTable();
  tableWithFormat();

}
