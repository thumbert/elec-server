library ui.spinner;

import 'dart:html' as html;

class Spinner {
  html.Element wrapper;
  html.DivElement _spinner;

  Spinner(this.wrapper) {
    _spinner = html.DivElement()
      ..className = 'loader';
    wrapper.children.add(_spinner);
  }

  /// If flag is true, make it visible (the default on creation),
  /// if flag is false, make it invisible.
  void visibility(bool flag) {
    if (flag) _spinner.style.display = 'block';
    else _spinner.style.display = 'none';
  }
}
