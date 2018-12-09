library ui.filter_categorical_dropdown;

import 'dart:html' as html;

class CategoricalDropdownCheckboxFilter {
  html.Element wrapper;
  html.SelectElement _selector;
  String name;
  bool selected;

  /// A dropdown filter for a categorical variable, for example a list of
  /// bucket values, or zone names, or option types, etc.,
  /// with a checkbox;
  ///
  /// Variable [name] is the text of the associated label.
  ///
  /// Need to trigger an action onChange.
  CategoricalDropdownCheckboxFilter(this.wrapper, List<String> values, this.name) {
    // put both the label and the select element into a div
    var _wrapper = new html.DivElement()
      ..setAttribute('style', 'margin-top: 8px');
    _wrapper.children.add(new html.LabelElement()
      ..text = name
      ..setAttribute('style', 'margin-left: 15px'));

    _selector = new html.SelectElement()
      ..setAttribute('style', 'margin-left: 15px');
    values.forEach((String e) {
      _selector.children.add(new html.OptionElement()
        ..id = e
        ..value = e
        ..text = e);
    });
    _wrapper.children.add(_selector);

    wrapper.children.add(_wrapper);
  }

  String get value => _selector.value;

  onChange(Function x) =>  _selector.onChange.listen(x);
}

