library ui.examples.calculators.elec_calc_cfd.elec_calc_cfd_app;

import 'dart:html' as html;
import 'package:elec/elec.dart';
import 'package:elec/risk_system.dart';
import 'package:elec_server/src/ui/disposable_window.dart';
import 'package:elec_server/src/ui/hourly_schedule_input.dart';
import 'package:elec_server/src/ui/type_ahead.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:elec/src/time/hourly_schedule.dart';
import 'package:elec/src/risk_system/pricing/calculators/base/cache_provider.dart';
import 'package:date/date.dart';
import 'package:elec/src/risk_system/pricing/calculators/elec_calc_cfd/elec_calc_cfd.dart';
import 'package:timezone/timezone.dart';

class ElecCalcCfdApp {
  html.DivElement wrapper;
  Client client;
  String rootUrl;
  ElecCalculatorCfd _calculator;
  CacheProvider cacheProvider;

  html.DivElement _calculatorDiv,
      _hasCustomDiv,
      _netDiv,
      _dollarPriceDiv,
      _commentsDiv,
      _reportOutputDiv;
  html.TextInputElement _termInput, _asOfDateInput;
  List<_Row2> _row2s;
  List<html.ButtonInputElement> _buttons;
  TypeAhead _buySell;
  HourlyScheduleInput hourlyScheduleInput;

  static final DateFormat _dateFmt = DateFormat('ddMMMyy');
  static final NumberFormat _dollarPriceFmt =
      NumberFormat.simpleCurrency(decimalDigits: 0, name: '');

  ElecCalcCfdApp(this.wrapper, this.cacheProvider) {
    wrapper.style.margin = '8px';
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
  void _f3Details() {}
  void _f7Reports() {
    _reportOutputDiv.children.clear();
    var content = html.DivElement()
      ..setAttribute('style',
          'font-family: monospace; white-space: pre-wrap; '
              'background-color: dodgerblue; color: white;')
      ..text = _calculator.flatReport().toString();
    _reportOutputDiv.children = [DisposableWindow(content).inner];
  }
  void _help() {
    print('Need help');
  }

  /// Initialize the calculator from a json template.  In a live app, this
  /// template comes from the database.
  void fromJson(Map<String, dynamic> x) async {
    _calculator = ElecCalculatorCfd(cacheProvider);
    await _calculator.fromJson(x);
    _calculatorDiv = html.DivElement()
      ..className = 'elec-calculator'
      ..children = [
        _initializeRow1(),
        _initializeRow2(),
        _initializeRow3(),
      ];
    setListenersRow1();
    setListenersRow2();
    setListenersRow3();

    _reportOutputDiv = html.DivElement();

    wrapper.children.add(_calculatorDiv);
    wrapper.children.add(_makeHotKeys());
    wrapper.children.add(_reportOutputDiv);
  }

  void setListenersRow1() {
    /// term changes
    _termInput.onChange.listen((e) async {
      _calculator.term = Term.parse(_termInput.value, UTC);
      await _calculator.build();
      for (var i = 0; i < _row2s.length - 1; i++) {
        _row2s[i]._floatingPriceDiv.text =
            _calculator.legs[i].price().toStringAsFixed(2);
      }
      _dollarPriceDiv.text = _dollarPriceFmt.format(_calculator.dollarPrice());
    });

    /// asOfDate changes

  }

  void setListenersRow2() {
    for (var i = 0; i < _row2s.length - 1; i++) {
      var row = _row2s[i];

      /// when quantity changes
      row.quantityInput.onChange.listen((event) async {
        var value = num.tryParse(row.quantityInput.value) ?? 0;
        _calculator.legs[i].quantitySchedule = HourlySchedule.filled(value);
        await _calculator.build();
        _dollarPriceDiv.text =
            _dollarPriceFmt.format(_calculator.dollarPrice());
      });

      row.quantityInput.onKeyDown.listen((e) async {
        /// on Alt + 1, show the quantity editor
        if (e.altKey == true && e.keyCode == 49) {
          e.preventDefault();
          var term = Term.fromInterval(
              _calculator.term.interval.withTimeZone(row._leg.tzLocation));
          hourlyScheduleInput =
              HourlyScheduleInput(term, header: 'Quantity for leg $i')
                ..visibility = true;
          _calculatorDiv.children.add(hourlyScheduleInput.inner);
          hourlyScheduleInput.onClose((e) async {
            if (hourlyScheduleInput.timeseries.isNotEmpty) {
              /// the save button was pressed
              var aux = hourlyScheduleInput.timeseries;
              _calculator.legs[i].quantitySchedule =
                  HourlySchedule.fromTimeSeries(aux);
              row.quantityInput.value = _calculator.legs[i].showQuantity().round().toString();
              await _calculator.build();
              _dollarPriceDiv.text =
                  _dollarPriceFmt.format(_calculator.dollarPrice());
            }
          });
        }
      });

      /// when bucket changes
      row.bucketInput.onSelect((e) async {
        _calculator.legs[i].bucket = Bucket.parse(_row2s[i].bucketInput.value);
        await _calculator.build();
        _row2s[i]._floatingPriceDiv.text =
            _calculator.legs[i].price().toStringAsFixed(2);
        _dollarPriceDiv.text =
            _dollarPriceFmt.format(_calculator.dollarPrice());
      });

      /// when fixPrice changes
      row.fixPriceInput.onChange.listen((event) async {
        var value = num.tryParse(row.fixPriceInput.value);
        if (value != null) {
          _calculator.legs[i].fixPriceSchedule = HourlySchedule.filled(value);
          await _calculator.build();
          _dollarPriceDiv.text =
              _dollarPriceFmt.format(_calculator.dollarPrice());
        } else {
          _dollarPriceDiv.text = 'Error';
        }
      });
    }
  }

  void setListenersRow3() {
    /// buy/sell changes
    _buySell.onSelect((e) async {
      _calculator.buySell = BuySell.parse(_buySell.value);
      await _calculator.build();
      _dollarPriceDiv.text = _dollarPriceFmt.format(_calculator.dollarPrice());
    });
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
      for (var i = 0; i < _calculator.legs.length; i++)
        _Row2.fromLeg(_calculator, i),
      _Row2.empty(_calculator),
    ];

    _netDiv = html.DivElement()
      ..className = 'cell-num cell-calculated'
      ..id = 'net'
      ..innerHtml = '&nbsp';
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
      ..id = 'dollarprice'
      ..text = _dollarPriceFmt.format(_calculator.dollarPrice());

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
    _buttons.add(html.ButtonInputElement()
      ..className = 'btn btn-primary my-button'
      ..value = 'Help'
      ..onClick.listen((event) => _help()));
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
  html.DivElement _regionDiv,
      _serviceDiv,
      _curveDiv,
      _bucketDiv,
      _floatingPriceDiv;
  html.TextInputElement quantityInput, fixPriceInput;
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

  /// Make one commodity row
  List<html.Element> initialize() {
    quantityInput = html.TextInputElement()
      ..className = 'cell-num cell-editable';
    if (_empty) {
      // if this is not set, the empty row doesn't get displayed
      quantityInput..innerHtml = '&nbsp';
    } else {
      quantityInput.value = _leg.showQuantity().toString();
    }

//    _quantityDiv = html.DivElement()
//      ..children = [quantityInput];
//    hourlyScheduleInput = HourlyScheduleInput(_quantityDiv, calculator.term)
//      ..visibility = false;

    _regionDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..text = _empty ? '' : _leg.region;
    _serviceDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..text = _empty ? '' : _leg.serviceType;
    _curveDiv = html.DivElement()
      ..className = 'cell-string cell-editable'
      ..text = _empty ? '' : _leg.curveName;
    _bucketDiv = html.DivElement()
      ..id = 'bucket-leg-$indexLeg'
      ..className = 'cell-string cell-editable typeahead';
    bucketInput = TypeAhead(
        _bucketDiv, Bucket.buckets.keys.map((e) => e.toLowerCase()).toList())
      ..spellcheck = false
      ..value = _empty ? '' : _leg.bucket.toString();

    fixPriceInput = html.TextInputElement()
      ..className = 'cell-num cell-editable'
      ..value = _empty ? '' : _leg.showFixPrice().toString();
    _floatingPriceDiv = html.DivElement()
      ..className = 'cell-num cell-calculated'
      ..text = _empty ? '' : _leg.price().toStringAsFixed(2);

    return [
      quantityInput,
      _regionDiv,
      _serviceDiv,
      _curveDiv,
      _bucketDiv,
      fixPriceInput,
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
