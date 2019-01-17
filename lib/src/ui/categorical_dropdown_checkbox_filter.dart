library ui.categorical_dropdown_checkbox_filter;

import 'dart:html' as html;
import 'dart:math' show Random;

class CategoricalDropdownCheckboxFilter {
  html.Element wrapper;
  html.SelectElement _selector;
  html.CheckboxInputElement _checkboxInputElement;
  String name;

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
      ..setAttribute('style', 'margin-top: 6px; margin-bottom: 6px;');

    // create a random string for the checkbox id
    var id = '__cb__${name}__${Random().nextInt(100000).toString()}';
    _checkboxInputElement = html.CheckboxInputElement()..id = id;
    _wrapper.children.add(_checkboxInputElement);

    _wrapper.children.add(html.LabelElement()
      ..setAttribute('style', 'margin-left: 15px;')
      ..text = name
      ..htmlFor = id);

    _selector = new html.SelectElement()
      ..setAttribute('style', 'margin-left: 15px;');
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

  bool get checked => _checkboxInputElement.checked;

  onChange(Function x) {
    _selector.onChange.listen(x);
    _checkboxInputElement.onChange.listen(x);
  }
}

