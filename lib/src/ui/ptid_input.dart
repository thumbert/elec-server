library ui.ptid_input;

import 'dart:html' as html;

class PtidInput {
  html.Element wrapper;
  String name;
  int? initialValue;
  Map<int, String> ptidToName;
  bool canBeEmpty;

  late html.TextInputElement _textInput;
  late html.LabelElement _nodeLabel;

  /// A ptid input field.
  /// [initialValue] can be null, for an empty initial value.
  /// Variable [name] is the text of the accompanying label.
  ///
  /// Need to trigger an action onDataChange.
  PtidInput(this.wrapper, this.initialValue, this.ptidToName,
      {int size = 6, this.name = 'Ptid', this.canBeEmpty = false}) {
    var aux = initialValue == null ? '' : initialValue.toString();

    var _wrapper = html.DivElement()..setAttribute('style', 'margin-top: 8px');
    _wrapper.children.add(html.LabelElement()
      ..text = name
      ..setAttribute('style', 'margin-left: 15px'));
    _textInput = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px')
      //..placeholder = aux
      ..size = size
      ..value = aux;
    _wrapper.children.add(_textInput);

    var labelText = '';
    if (ptidToName.containsKey(initialValue)) {
      labelText = ptidToName[initialValue]!;
    }
    _nodeLabel = html.LabelElement()
      ..setAttribute('style', 'margin-left: 15px')
      ..text = labelText;
    _wrapper.children.add(_nodeLabel);

    wrapper.children.add(_wrapper);
  }

  int? get value {
    int? aux;
    // print('value: "${_textInput.value}"');
    if (_textInput.value!.isNotEmpty) {
      // there is some input
      aux = int.tryParse(_textInput.value!);
      if (aux != null && ptidToName.containsKey(aux)) {
        var text = ptidToName[aux]!;
        _textInput.setAttribute(
            'style', 'margin-left: 15px; border-color: initial;');
        // input is good, set the label
        _nodeLabel.text = text;
      } else {
        // print('input "${_textInput.value}"');
        _textInput.setAttribute(
            'style', 'margin-left: 15px; border: 2px solid red;');
        _nodeLabel.text = '';
      }
    } else {
      // an empty input field
      if (canBeEmpty) {
        _textInput.setAttribute(
            'style', 'margin-left: 15px; border-color: initial;');
      } else {
        _textInput.setAttribute(
            'style', 'margin-left: 15px; border: 2px solid red;');
      }
      _nodeLabel.text = ''; // clear the label
    }

    return aux;
  }

  /// trigger a change when the input changes
  void onChange(Function x) {
    _textInput.onChange.listen(x as void Function(html.Event)?);
  }
}
