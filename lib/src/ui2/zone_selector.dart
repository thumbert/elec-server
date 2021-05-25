library ui2.zone_selector;

import 'dart:html' as html;

class ZoneSelector {
  html.Element? wrapper, _wrapper;
  List<String>? names;

  html.SelectElement? _selector;

  ZoneSelector(this.wrapper, {this.names}) {
    names ??= ['ALL', 'MAINE', 'NH', 'VT', 'CT', 'RI', 'SEMA', 'WCMA', 'NEMA'];

    _selector = html.SelectElement()..className = 'custom-select';
    for (var name in names!) {
      _selector!.children.add(html.OptionElement()
        ..id = name
        ..value = name
        ..text = name);
    }

    _wrapper = html.DivElement()
      ..className = 'row'
      ..setAttribute('style', 'width: 300px;')
      ..children.add(
        html.DivElement()
            ..className = 'col-md-6 mb-3'
            ..children.addAll([
              html.LabelElement()..text = 'Load Zone',
              _selector!,
            ])
      );

    wrapper!.children.add(_wrapper!);
  }

  String? get value => _selector!.value;

  void setAttribute(String name, String value) =>
      _wrapper!.setAttribute(name, value);

  /// Set the values for this selector in case the data wasn't available at
  /// initialization
  set values(Iterable<String> xs) {
    _selector!.children.clear();
    xs.forEach((e) {
      _selector!.children.add(html.OptionElement()
        ..id = e
        ..value = e
        ..text = e);
    });
  }

  void onChange(Function x) =>  _selector!.onChange.listen(x as void Function(html.Event)?);


}