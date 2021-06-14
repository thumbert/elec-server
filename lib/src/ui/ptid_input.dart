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
      ..text = '$name'
      ..setAttribute('style', 'margin-left: 15px'));
    _textInput = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px')
      //..placeholder = aux
      ..size = size
      ..value = aux;
    _wrapper.children.add(_textInput);
    _nodeLabel = html.LabelElement()
      ..setAttribute('style', 'margin-left: 15px');
    _nodeLabel.text = '';
    _wrapper.children.add(_nodeLabel);

    wrapper.children.add(_wrapper);
  }

  int? get value {
    int? aux;
    var text = '';
    if (_textInput.value!.isEmpty) {
      aux = null;
      if (!canBeEmpty) {
        _textInput.setAttribute(
            'style', 'margin-left: 15px; border: 2px solid red;');
      }
    } else {
      aux = int.tryParse(_textInput.value!);
      _textInput.setAttribute(
          'style', 'margin-left: 15px; border-color: initial;');
    }
    if (aux != null && ptidToName.containsKey(aux)) {
      text = ptidToName[aux]!;
    }
    if (text == '') {
      // name not in the ptidToName map
      _textInput.setAttribute(
          'style', 'margin-left: 15px; border: 2px solid red;');
    }
    // you can set the label
    _nodeLabel.text = text;
    return aux;
  }

  /// trigger a change when the input changes
  void onChange(Function x) {
    _textInput.onChange.listen(x as void Function(html.Event)?);
  }
}
