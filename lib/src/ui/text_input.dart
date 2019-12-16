library ui.text_input;

import 'dart:html' as html;

class TextInput {
  html.Element wrapper;
  html.TextInputElement _textInput;
  String name;
  String initialValue;
  List<String> allowedValues;

  /// A simple text input with a label.
  ///
  /// Variable [name] is the text of the accompanying label.
  ///
  /// Need to trigger an action onChange.
  TextInput(this.wrapper, this.name, {this.initialValue, int size,
    String placeholder, this.allowedValues}) {

    var aux = '';
    if (initialValue != null) aux = initialValue;

    var _wrapper = html.DivElement()
      ..setAttribute('style', 'margin-top: 8px');
    _wrapper.children.add(html.LabelElement()
      ..text = '$name');
    _textInput = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px')
      ..value = aux;
    if (placeholder != null) _textInput.placeholder = placeholder;
    if (size != null) _textInput.size = size;
    _wrapper.children.add(_textInput);

    wrapper.children.add(_wrapper);
  }

  String get value {
    var _value = _textInput.value;
    if (allowedValues == null || allowedValues.contains(_value)) {
      _textInput.setAttribute('style', 'margin-left: 15px; border-color: initial;');
      return _value;
    } else {
      _textInput.setAttribute('style', 'margin-left: 15px; border: 2px solid red;');
    }
    return _value;
  }

  /// trigger a change when either one of the two inputs change
  onChange(Function x) {
    _textInput.onChange.listen(x);
  }
}
