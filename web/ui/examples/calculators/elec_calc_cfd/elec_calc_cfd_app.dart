library ui.examples.calculators.elec_calc_cfd.elec_calc_cfd_app;

import 'dart:html' as html;
import 'package:elec/elec.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart';
import 'package:date/date.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/elec_calc_cfd.dart';

class ElecCalcCfdApp {
  html.DivElement wrapper;
  Client client;
  String rootUrl;

  ElecCalculatorCfd _calculator;

  html.DivElement _calculatorDiv,
      _termDiv,
      _asOfDateDiv,
      _hasCustomDiv,
      _netDiv,
      _dollarPriceDiv,
      _buySellDiv,
      _commentsDiv;
  List<_Row2> _row2s;

  static final DateFormat _dateFmt = DateFormat('ddMMMyy');

  ElecCalcCfdApp(this.wrapper,
      {this.client, this.rootUrl = 'http://localhost:8080/'});

  /// Initialize the calculator from a json template.  In a live app, this
  /// template comes from the database.
  set template(Map<String, dynamic> x) {
    _calculator = ElecCalculatorCfd.fromJson(x);
    _calculatorDiv = html.DivElement()
      ..className = 'elec-calculator'
      ..children = [
        _initializeRow1(),
        _initializeRow2(),
        _initializeRow3(),
      ];
    
    wrapper.children.add(_calculatorDiv);
  }

  void makeHtml() {
    _calculator.legs;
  }

  /// Set the row1 elements from the [_calculator] info.
  html.DivElement _initializeRow1() {
    _termDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..id = 'term'
      ..text = _calculator.term.toString();

    _asOfDateDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..setAttribute('style', 'width: 4em;')
      ..id = 'asofdate'
      ..text = _calculator.asOfDate.toString(_dateFmt);

    _hasCustomDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..setAttribute('style', 'width: 4em;')
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
                  ..className = 'cell-header'
                  ..text = 'Term',
                _termDiv,
              ],
          ],
        html.DivElement()
          ..className = 'asofdate-container'
          ..children = [
            html.DivElement()
              ..className = 'grid-container'
              ..children = [
                html.DivElement()
                  ..className = 'cell-header'
                  ..text = 'As of Date',
                _asOfDateDiv,
              ],
          ],
        html.DivElement()
          ..className = 'hascustom-container'
          ..children = [
            html.DivElement()
              ..className = 'grid-container'
              ..children = [
                html.DivElement()
                  ..className = 'cell-header'
                  ..text = 'Has Custom?',
                _hasCustomDiv,
              ]
          ]
      ];
  }

  html.DivElement _initializeRow2() {
    _row2s = [
      for (var leg in _calculator.legs) _Row2.fromLeg(leg),
      _Row2.empty(),  // add another empty row
    ];
    print(_row2s.length);
    _netDiv = html.DivElement()
      ..className = 'cell-num cell-calculated'
      ..id = 'net';
    return html.DivElement()
      ..id = 'row-2'
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

    _buySellDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..id = 'buysell'
      ..text = _calculator.buySell.toString();

    _commentsDiv = html.DivElement()
      ..className = 'cell-comments cell-editable'
      ..id = 'comments'
      ..text = _calculator.comments;

    return html.DivElement()
      ..id = 'row-3'
      ..children = [
        html.DivElement()
          ..className = 'grid-results'
          ..children = [
            html.DivElement()
              ..className = 'cell-header'
              ..text = 'Dollar Price',
            _dollarPriceDiv,
            html.DivElement(),
            //
            html.DivElement()
              ..className = 'cell-header'
              ..text = 'Buy/Sell',
            _buySellDiv,
            html.DivElement(),
            //
            html.DivElement()
              ..className = 'cell-header'
              ..setAttribute('style', 'align-self: start;')
              ..text = 'Comments',
            _commentsDiv,
          ],
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

class _Row2 {
  CommodityLeg _leg;
  bool _empty;
  html.DivElement _hourlyQuantityDiv,
      _regionDiv,
      _serviceDiv,
      _curveDiv,
      _bucketDiv,
      _fixPriceDiv,
      _floatingPriceDiv;

  /// An empty commodity row
  _Row2.empty() {
    _empty = true;
  }

  /// A commodity row from a calculator leg
  _Row2.fromLeg(this._leg) {
    _empty = false;
  }

  ///
  List<html.Element> initialize() {
    _hourlyQuantityDiv = html.DivElement()
      ..className = 'cell-num cell-editable';
    _regionDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..text = _empty ? '' : (_leg.curveId.components['iso'] as Iso).name;
    _serviceDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..text = _empty ? '' : _leg.curveId.components['serviceType'];
    _curveDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..text = _empty ? '' : _leg.curveId.curve;
    _bucketDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..text = _empty ? '' : _leg.bucket.toString();
    _fixPriceDiv = html.DivElement()
      ..className = 'cell-num cell-editable'
      ..text = _empty ? '' : _leg.showFixPrice.toString();
    _floatingPriceDiv = html.DivElement()
      ..className = 'cell-num cell-calculated'
      ..text = '';
    if (_empty) {
      // if this is not set, the empty row doesn't get displayed
      _hourlyQuantityDiv..innerHtml = '&nbsp';
    } else {
      _hourlyQuantityDiv..text = _leg.showQuantity.toString();
    }


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
