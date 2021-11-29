library ui2.zone_selector;

import 'dart:html' as html;

class Selector {
  late html.Element inner;

  Selector(html.Element wrapper, List<String> values, String name,
      {bool hasCheckbox = false}) {
    inner = html.DivElement()
      ..className = 'row' // 'column'
      ..children = [
        html.DivElement()
          ..className = 'col-md-3 mb-3'
          ..children = [
            html.LabelElement()..text = name,
            html.SelectElement()
              ..className = 'custom-select'
              ..children = [
                for (var value in values)
                  html.OptionElement()
                    ..id = value
                    ..value = value
                    ..text = value
              ]
          ]
      ];

    wrapper.children.add(inner);
  }

  String? get value => ((inner.children[0] as html.DivElement).children[1] as html.SelectElement).value;

  void setAttribute(String name, String value) =>
      inner.setAttribute(name, value);

  /// Set the values for this selector in case the data wasn't available at
  /// initialization
  set values(Iterable<String> xs) {
    var _selector = inner.children[1] as html.SelectElement;
    _selector.children.clear();
    for (var e in xs) {
      _selector.children.add(html.OptionElement()
        ..id = e
        ..value = e
        ..text = e);
    }
  }

  void onChange(Function x) => (inner.children[0] as html.DivElement).children[1].onChange.listen(x as void Function(html.Event)?);
}
