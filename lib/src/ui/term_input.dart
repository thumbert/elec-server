library ui.term_input;

import 'dart:html' as html;
import 'package:timezone/browser.dart';
import 'package:date/date.dart';

class TermInput {
  html.Element wrapper;
  html.TextInputElement _textInput;
  String name;
  String defaultValue;
  Location tzLocation;


  /// A term input (DateTime Interval) with a label.
  ///
  /// Variable [name] is the text of the accompanying label.
  ///
  /// Need to trigger an action onChange.
  TermInput(this.wrapper, {this.name: 'Term', this.defaultValue, this.tzLocation,
    int size}) {

    size ??= 9;

    String aux = '';
    if (defaultValue != null) aux = defaultValue;

    var _wrapper = new html.DivElement()
      ..setAttribute('style', 'margin-top: 8px');
    _wrapper.children.add(new html.LabelElement()
      ..text = '$name');
    _textInput = new html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px')
      ..placeholder = aux
      ..size = size
      ..value = aux;
    _wrapper.children.add(_textInput);

    wrapper.children.add(_wrapper);
  }

  Interval get value {
    Interval aux;
    try {
      aux = parseTerm(_textInput.value, tzLocation: tzLocation);
      _textInput.setAttribute('style', 'margin-left: 15px; border-color: initial;');
    } on ArgumentError {
      _textInput.setAttribute('style', 'margin-left: 15px; border: 2px solid red;');
    } catch (e) {
      print(e.toString());
    }
    return aux;
  }


  /// trigger a change when either one of the two inputs change
  onChange(Function x) {
    _textInput.onChange.listen(x);
  }
}
