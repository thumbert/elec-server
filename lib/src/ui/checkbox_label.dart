library ui.checkbox;

import 'dart:html' as html;

class CheckboxLabel {
  html.Element wrapper;
  html.CheckboxInputElement _checkboxInputElement;
  String name;

  /// A simple checkbox with a text label.
  ///
  /// Variable [name] is the text of the associated label.
  ///
  /// Need to trigger an action onChange.
  CheckboxLabel(this.wrapper, this.name) {
    // put both the label and the select element into a div
    var _wrapper = html.DivElement()
      ..setAttribute('style', 'margin-top: 6px; margin-bottom: 6px;');

    // create the string for the checkbox id
    var id = '${wrapper.id}__cbl__${name}';
    _checkboxInputElement = html.CheckboxInputElement()..id = id;
    _wrapper.children.add(_checkboxInputElement);

    _wrapper.children.add(html.LabelElement()
      ..setAttribute('style', 'margin-left: 15px;')
      ..text = name
      ..htmlFor = id);

    wrapper.children.add(_wrapper);
  }

  set checked(bool x) => _checkboxInputElement.checked = x;

  bool get checked => _checkboxInputElement.checked;

  onChange(Function x) {
    _checkboxInputElement.onChange.listen(x);
  }
}

