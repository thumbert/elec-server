library ui.examples.calculators.elec_calc_cfd.elec_calc_cfd_app;

import 'dart:html' as html;
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/client/marks/curves/curve_id.dart';
import 'package:elec_server/src/ui/type_ahead.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/elec_calc_cfd.dart';
import 'package:timezone/timezone.dart';

class ElecCalcCfdApp {
  html.DivElement wrapper;
  Client client;
  String rootUrl;
  ElecCalculatorCfd _calculator;
  CurveIdClient _curveIdClient;

  html.DivElement _calculatorDiv,
      _hasCustomDiv,
      _netDiv,
      _dollarPriceDiv,
      _commentsDiv;
  html.TextInputElement _termInput, _asOfDateInput;
  List<_Row2> _row2s;
  List<html.ButtonInputElement> _buttons;
  TypeAhead _buySell;


  static final DateFormat _dateFmt = DateFormat('ddMMMyy');

  ElecCalcCfdApp(this.wrapper,
      {this.client, this.rootUrl = 'http://localhost:8080/'}) {
    _curveIdClient = CurveIdClient(client, rootUrl: rootUrl);
  }

  void _f2Refresh() {
    print(_calculator.term);
    print(_calculator.asOfDate);
    print(_calculator.buySell);
    for (var leg in _calculator.legs) {
      print(leg.bucket);
      print(leg.quantity);
    }
  }
  void _f3Details() {

  }
  void _f7Reports() {
    print('Wanna report?');
  }



  /// Initialize the calculator from a json template.  In a live app, this
  /// template comes from the database.
  set template(Map<String, dynamic> x) {
    _calculator = ElecCalculatorCfd()..fromJson(x);
    _calculatorDiv = html.DivElement()
      ..className = 'elec-calculator'
      ..children = [
        _initializeRow1(),
        _initializeRow2(),
        _initializeRow3(),
      ];

    wrapper.children.add(_calculatorDiv);
    wrapper.children.add(_makeHotKeys());
  }

  void makeHtml() {
    _calculator.legs;
  }

  /// Set the row1 elements from the [_calculator] info.
  html.DivElement _initializeRow1() {
    _termInput = html.TextInputElement()
      ..className = 'cell-string cell-editable'
      ..id = 'term'
      ..spellcheck = false
      ..value = _calculator.term.toString()
      ..onChange.listen((event) {
        Interval aux;
        try {
          aux = parseTerm(_termInput.value, tzLocation: UTC);
          _termInput.setAttribute(
              'style', 'margin-left: 15px; border-color: none;');
        } on ArgumentError {
          _termInput.setAttribute(
              'style', 'margin-left: 15px; border: 2px solid red;');
        } catch (e) {
          print(e.toString());
        }
        _calculator.term = Term.fromInterval(aux);
      });

    _asOfDateInput = html.TextInputElement()
      ..className = 'cell-string cell-editable'
      ..id = 'asofdate'
      ..spellcheck = false
      ..value = _calculator.asOfDate.toString(_dateFmt)
      ..onChange.listen((event) {
        Date aux;
        try {
          aux = Date.parse(_asOfDateInput.value, fmt: _dateFmt);
          _asOfDateInput.setAttribute(
              'style', 'margin-left: 15px; border-color: none;');
        } on ArgumentError {
          _asOfDateInput.setAttribute(
              'style', 'margin-left: 15px; border: 2px solid red;');
        } catch (e) {
          print(e.toString());
        }
        _calculator.asOfDate = aux;
      });

    _hasCustomDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..id = 'hascustom'
      ..text = _calculator.hasCustom() ? 'yes' : 'no';

    return html.DivElement()
      ..className = 'row-1'
      ..children = [
        html.DivElement()
          ..className = 'term-container'
          ..children = [
            html.DivElement()
              ..className = 'grid-container'
              ..children = [
                html.DivElement()
                  ..className = 'left-label'
                  ..text = 'Term',
                _termInput,
              ],
          ],
        html.DivElement()
          ..className = 'asofdate-container'
          ..children = [
            html.DivElement()
              ..className = 'grid-container'
              ..children = [
                html.DivElement()
                  ..className = 'left-label'
                  ..text = 'As of Date',
                _asOfDateInput,
              ],
          ],
        html.DivElement()
          ..className = 'hascustom-container'
          ..children = [
            html.DivElement()
              ..className = 'grid-container'
              ..children = [
                html.DivElement()
                  ..className = 'left-label'
                  ..text = 'Has Custom?',
                _hasCustomDiv,
              ]
          ]
      ];
  }

  html.DivElement _initializeRow2() {
    _row2s = [
      for (var i=0; i<_calculator.legs.length; i++) _Row2.fromLeg(_calculator, i),
      _Row2.empty(_calculator),
    ];

    _netDiv = html.DivElement()
      ..className = 'cell-num cell-calculated'
      ..id = 'net';
    return html.DivElement()
      ..className = 'row-2'
      ..children = [
        html.DivElement()
          ..className = 'grid-container'
          ..children = [
            ..._makeRow2Header(),
            ...[for (var row2 in _row2s) ...row2.initialize()],
            html.DivElement()
              ..className = 'net'
              ..text = 'Net',
            _netDiv,
          ]
      ];
  }

  html.DivElement _initializeRow3() {
    _dollarPriceDiv = html.DivElement()
      ..className = 'cell-num cell-calculated'
      ..id = 'dollarprice';

    var _buySellDiv = html.DivElement()
      ..className = 'typeahead cell-string cell-editable';
    _buySell = TypeAhead(_buySellDiv, ['Buy', 'Sell'])
      ..value = _calculator.buySell.toString()
      ..onSelect((e) => _calculator.buySell = BuySell.parse(_buySell.value));

    _commentsDiv = html.DivElement()
      ..className = 'cell-comments cell-editable'
      ..id = 'comments'
      ..text = _calculator.comments;

    return html.DivElement()
      ..className = 'row-3'
      ..children = [
        html.DivElement()
          ..className = 'grid-results'
          ..children = [
            html.DivElement()
              ..className = 'left-label'
              ..text = 'Dollar Price',
            _dollarPriceDiv,
            html.DivElement(),
            //
            html.DivElement()
              ..className = 'left-label'
              ..text = 'Buy/Sell',
            _buySellDiv,
            html.DivElement(),
            //
            html.DivElement()
              ..className = 'left-label'
              ..setAttribute('style', 'align-self: start;')
              ..text = 'Comments',
            _commentsDiv,
          ],
      ];
  }

  void setListeners() {
    var row = _row2s.first;

    row._regionInput.onSelect((e) {

    });

    row.bucketInput.onSelect((e) {
      var leg = _calculator.legs.first;
      leg.bucket = Bucket.parse(row.bucketInput.value);
      _calculator.legs.first = leg;
    });

  }

  /// add the buttons at the bottom of the calculators
  html.DivElement _makeHotKeys() {
    _buttons = <html.ButtonInputElement>[];
    _buttons.add(html.ButtonInputElement()
      ..className = 'btn btn-primary my-button'
      ..value = 'F2 Refresh'
      ..onClick.listen((event) => _f2Refresh()));
    _buttons.add(html.ButtonInputElement()
      ..className = 'btn btn-primary my-button'
      ..value = 'F3 Details'
      ..onClick.listen((event) => _f3Details()));
    _buttons.add(html.ButtonInputElement()
      ..className = 'btn btn-primary my-button'
      ..value = 'F7 Report'
      ..onClick.listen((event) => _f7Reports()));
    return html.DivElement()
      ..className = 'hot-keys'
      ..children = _buttons;
  }

}


class _Row2 {
  ElecCalculatorCfd calculator;
  int indexLeg;
  CommodityLeg _leg;
  bool _empty;
  html.DivElement _hourlyQuantityDiv,
      _regionDiv,
      _serviceDiv,
      _curveDiv,
      _bucketDiv,
      _fixPriceDiv,
      _floatingPriceDiv;
  TypeAhead _regionInput, _serviceInput, _curveInput, bucketInput;

  /// An empty commodity row
  _Row2.empty(this.calculator) {
    _empty = true;
  }

  /// A commodity row from a calculator leg
  _Row2.fromLeg(this.calculator, this.indexLeg) {
    _leg = calculator.legs[indexLeg];
    _empty = false;
  }

  ///
  List<html.Element> initialize() {
    _hourlyQuantityDiv = html.DivElement()
      ..className = 'cell-num cell-editable';
    if (_empty) {
      // if this is not set, the empty row doesn't get displayed
      _hourlyQuantityDiv..innerHtml = '&nbsp';
    } else {
      _hourlyQuantityDiv..text = _leg.showQuantity.toString();
    }
    _regionDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..text = _empty ? '' : (_leg.curveDetails['iso'] as Iso).name;
    _serviceDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..text = _empty ? '' : _leg.curveDetails['serviceType'];
    _curveDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..text = _empty ? '' : _leg.curveDetails['name'];
    _bucketDiv = html.DivElement()
      ..id = 'bucket-leg-$indexLeg'
      ..className = 'cell-string cell-editable typeahead';
    bucketInput = TypeAhead(_bucketDiv, ['Peak', 'Offpeak', 'Flat', 'Custom',
      '5x16', '2x16H', '7x8', '7x24', '7x16'])
      ..spellcheck = false
      ..value = _empty ? '' : _leg.bucket.toString();
    /// the options don't show in the dropdown but are there and can be
    /// selected!

    _fixPriceDiv = html.DivElement()
      ..className = 'cell-num cell-editable'
      ..text = _empty ? '' : _leg.showFixPrice.toString();
    _floatingPriceDiv = html.DivElement()
      ..className = 'cell-num cell-calculated'
      ..text = '';


    return [
      _hourlyQuantityDiv,
      _regionDiv,
      _serviceDiv,
      _curveDiv,
      _bucketDiv,
      _fixPriceDiv,
      _floatingPriceDiv,
    ];
  }
}


List<html.DivElement> _makeRow2Header() {
  return <html.DivElement>[
    html.DivElement()
      ..className = 'cell-header'
      ..innerHtml = 'Hourly<br>Quantity',
    html.DivElement()
      ..className = 'cell-header'
      ..text = 'Region',
    html.DivElement()
      ..className = 'cell-header'
      ..text = 'Service',
    html.DivElement()
      ..className = 'cell-header'
      ..text = 'Curve',
    html.DivElement()
      ..className = 'cell-header'
      ..text = 'Bucket',
    html.DivElement()
      ..className = 'cell-header'
      ..text = 'Fix Price',
    html.DivElement()
      ..className = 'cell-header'
      ..text = 'Price',
  ];
}
