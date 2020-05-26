library ui2.selector_checkbox;

import 'dart:html' as html;

import 'package:elec_server/src/ui2/selector.dart';

class SelectorCheckbox extends Selector {
//  @override
//  html.Element inner;

  SelectorCheckbox(html.Element wrapper, List<String> values, String name)
      : super(wrapper, values, name) {
    var aux = [
      html.DivElement()
        ..className = 'row'
        ..children = [
          html.DivElement()
            ..className = 'col-md-1 mb-1'
            ..children = [
              html.CheckboxInputElement()..id = '${wrapper.id}__cb__$name',
            ],
          html.DivElement()
            ..className = 'col-sm'
            ..children = [
              ...wrapper.children,
            ],
        ],
    ];
    wrapper.children = aux;
  }

//  @override
//  String get value => inner.value;

//  @override
//  void setAttribute(String name, String value) =>
//      inner.setAttribute(name, value);

  /// Set the values for this selector in case the data wasn't available at
  /// initialization
//  @override
//  set values(Iterable<String> xs) {
//    _selector.children.clear();
//    xs.forEach((e) {
//      _selector.children.add(html.OptionElement()
//        ..id = e
//        ..value = e
//        ..text = e);
//    });
//  }

//  void onChange(Function x) => _selector.onChange.listen(x);
}
