import 'dart:html' as html;

class NumericInput {
  html.Element? wrapper, _wrapper;
  late html.TextInputElement _textInput;
  String leftLabel, rightLabel;
  num? initialValue;
  String thousandSeparator;
  num? placeholder;

  /// A numeric input with a label.
  ///
  /// Variable [leftLabel] is the text of the accompanying label.
  ///
  /// Need to trigger an action onDataChange.
  NumericInput(this.wrapper, this.leftLabel,
      {int size = 5,
      this.initialValue,
      this.placeholder,
      this.rightLabel = '',
      this.thousandSeparator = ','}) {
    _wrapper = html.DivElement()..setAttribute('style', 'margin-top: 8px');
    _wrapper!.children.add(html.LabelElement()..text = leftLabel);
    _textInput = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px;margin-right: 15px')
      ..placeholder = (placeholder == null) ? '' : placeholder.toString()
      ..size = size
      ..value = (initialValue == null) ? '' : initialValue.toString();
    _wrapper!.children.add(_textInput);
    _wrapper!.children.add(html.LabelElement()..text = rightLabel);

    wrapper!.children.add(_wrapper!);
  }

  num? get value {
    num? aux;
    if (_textInput.value!.isEmpty) {
      aux = initialValue;
    } else {
      try {
        aux = num.parse(_textInput.value!.replaceAll(thousandSeparator, ''));
        _textInput.setAttribute('style',
            'margin-left: 15px; margin-right: 15px; border-color: initial;');
      } catch (e) {
        _textInput.setAttribute(
            'style', 'margin-left: 15px; border: 2px solid red;');
      }
    }
    return aux;
  }

  void setAttribute(String name, String value) =>
      _wrapper!.setAttribute(name, value);

  /// trigger a change when either one of the two inputs change
  void onChange(Function x) {
    _textInput.onChange.listen(x as void Function(html.Event)?);
  }
}
