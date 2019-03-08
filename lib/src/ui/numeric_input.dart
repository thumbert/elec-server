library ui.numeric_input;

import 'dart:html' as html;

class NumericInput {
  html.Element wrapper;
  html.TextInputElement _textInput;
  String name;
  num defaultValue;
  String thousandSeparator;

  /// A numeric input with a label.
  ///
  /// Variable [name] is the text of the accompanying label.
  ///
  /// Need to trigger an action onDataChange.
  NumericInput(this.wrapper, this.name,
      {int size: 5, this.defaultValue, this.thousandSeparator: ','}) {

    String aux = '';
    if (defaultValue != null) aux = defaultValue.toString();

    var _wrapper = html.DivElement()
      ..setAttribute('style', 'margin-top: 8px');
    _wrapper.children.add(html.LabelElement()
      ..text = '$name');
    _textInput = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px')
      ..placeholder = aux
      ..size = size
      ..value = aux;
    _wrapper.children.add(_textInput);

    wrapper.children.add(_wrapper);
  }

  num get value {
    num aux;
    if (_textInput.value.isEmpty)
      aux = defaultValue;
    else
      aux = num.parse(_textInput.value.replaceAll(thousandSeparator, ''));
    return aux;
  }


  /// trigger a change when either one of the two inputs change
  onChange(Function x) {
    _textInput.onChange.listen(x);
  }
}
