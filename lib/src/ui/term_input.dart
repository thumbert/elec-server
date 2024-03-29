library ui.term_input;

import 'dart:html' as html;
import 'package:timezone/browser.dart';
import 'package:date/date.dart';

class TermInput {
  html.Element? wrapper;
  late html.DivElement _wrapper;
  late html.TextInputElement _textInput;
  String name;
  String? defaultValue;
  Location? tzLocation;

  /// A term input (DateTime Interval) with a label.
  ///
  /// Variable [name] is the text of the accompanying label.
  ///
  /// Need to trigger an action onChange.
  TermInput(this.wrapper,
      {this.name = 'Term',
      this.defaultValue,
      this.tzLocation,
      String? placeholder,
      int size = 9}) {
    String? aux = '';
    placeholder = '';
    if (defaultValue != null) {
      aux = defaultValue;
      placeholder = defaultValue;
    }

    _wrapper = html.DivElement()..setAttribute('style', 'margin-top: 8px');
    _wrapper.children.add(html.LabelElement()..text = name);
    _textInput = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px')
      ..placeholder = placeholder!
      ..size = size
      ..value = aux;
    _wrapper.children.add(_textInput);

    wrapper!.children.add(_wrapper);
  }

  void setAttribute(String name, String value) =>
      _wrapper.setAttribute(name, value);

  Interval? get value {
    Interval? aux;
    try {
      aux = parseTerm(_textInput.value!, tzLocation: tzLocation);
      _textInput.setAttribute(
          'style', 'margin-left: 15px; border-color: initial;');
    } on ArgumentError {
      _textInput.setAttribute(
          'style', 'margin-left: 15px; border: 2px solid red;');
    } catch (e) {
      print(e.toString());
    }
    return aux;
  }

  /// trigger a change when either one of the two inputs change
  void onChange(Function x) {
    _textInput.onChange.listen(x as void Function(html.Event)?);
  }
}
