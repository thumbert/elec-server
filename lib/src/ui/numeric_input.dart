library ui.numeric_input;

import 'dart:html' as html;

class NumericInput {
  html.Element wrapper;
  html.TextInputElement _textInput;
  String name;
  num defaultValue;

  /// A numeric input with a label.
  ///
  /// Variable [name] is the text of the accompanying label.
  ///
  /// Need to trigger an action onDataChange.
  NumericInput(this.wrapper, this.name,
      {int size: 5, this.defaultValue}) {

    String aux = '';
    if (defaultValue != null) aux = defaultValue.toString();

    var _wrapper = new html.DivElement()
      ..setAttribute('style', 'margin-top: 8px');
    _wrapper.children.add(new html.LabelElement()
      ..text = '$name';
      //..setAttribute('style', 'margin-left: 15px'));
    _textInput = new html.TextInputElement()
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
      aux = num.parse(_textInput.value);
    return aux;
  }


  /// trigger a change when either one of the two inputs change
  onChange(Function x) {
    _textInput.onChange.listen(x);
  }
}
