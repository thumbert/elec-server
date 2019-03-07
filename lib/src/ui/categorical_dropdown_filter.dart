library ui.categorical_dropdown_filter;

import 'dart:html' as html;

class CategoricalDropdownFilter {
  html.Element wrapper;
  html.SelectElement _selector;
  String name;

  /// A dropdown filter for a categorical variable, for example a list of
  /// bucket values, or zone names, or option types, etc.,
  ///
  /// Variable [name] is the text of the associated label.
  ///
  /// Need to trigger an action onChange.
  CategoricalDropdownFilter(this.wrapper, List<String> values, this.name) {
    // put both the label and the select element into a div
    var _wrapper = new html.DivElement()
      ..setAttribute('style', 'margin-top: 6px; margin-bottom: 6px;');
    _wrapper.children.add(html.LabelElement()
      ..text = name);

    _selector = new html.SelectElement()
      ..setAttribute('style', 'margin-left: 15px;');
    values.forEach((String e) {
      _selector.children.add(html.OptionElement()
        ..id = e
        ..value = e
        ..text = e);
    });
    _wrapper.children.add(_selector);

    wrapper.children.add(_wrapper);
  }

  String get value => _selector.value;
  
  /// Set the values for this dropdown in case the data wasn't available at
  /// initialization
  set values(Iterable<String> xs) {
    _selector.children.clear();
    xs.forEach((e) {
      _selector.children.add(html.OptionElement()
        ..id = e
        ..value = e
        ..text = e);
    });
  }

  onChange(Function x) =>  _selector.onChange.listen(x);
}

