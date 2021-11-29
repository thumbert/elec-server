library ui.categorical_dropdown_filter;

import 'dart:html' as html;

class CategoricalDropdownFilter {
  html.Element? wrapper;
  late html.Element inner;
  late html.SelectElement _selector;
  String name;

  /// A dropdown filter for a categorical variable, for example a list of
  /// bucket values, or zone names, or option types, etc.,
  ///
  /// Variable [name] is the text of the associated label.
  ///
  /// Need to trigger an action onChange.
  CategoricalDropdownFilter(this.wrapper, List<String> values, this.name) {
    // put both the label and the select element into a div
    inner = html.DivElement()
      ..setAttribute('style', 'margin-top: 6px; margin-bottom: 6px;');
    inner.children.add(html.LabelElement()
      ..text = name);

    _selector = html.SelectElement()
      ..setAttribute('style', 'margin-left: 15px;');
    for (var e in values) {
      _selector.children.add(html.OptionElement()
        ..id = e
        ..value = e
        ..text = e);
    }
    inner.children.add(_selector);

    wrapper!.children.add(inner);
  }

  set value(String? x) => _selector.value = x;

  String? get value => _selector.value;

  void setAttribute(String name, String value) =>
      inner.setAttribute(name, value);

  /// Set the values for this dropdown in case the data wasn't available at
  /// initialization
  set values(Iterable<String> xs) {
    _selector.children.clear();
    for (var e in xs) {
      _selector.children.add(html.OptionElement()
        ..id = e
        ..value = e
        ..text = e);
    }
  }

  void onChange(Function x) =>  _selector.onChange.listen(x as void Function(html.Event)?);
}

