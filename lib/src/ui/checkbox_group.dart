library ui.checkbox_group;

import 'dart:html' as html;

enum CheckboxGroupOrientation { horizontal, vertical }

class CheckboxGroup {
  html.Element wrapper;
  html.Element _wrapper;
  List<html.CheckboxInputElement> _checkboxes;
  List<String> labels;
  List<bool> state;

  CheckboxGroupOrientation orientation;

  /// A List of checkboxes with a text labels.
  ///
  /// Variable [labels] is the text of the associated labels.
  /// By default [state] is set to all elements [true] i.e. checked.
  /// Need to trigger an action onChange.
  CheckboxGroup(this.wrapper, this.labels,
      {this.state, this.orientation = CheckboxGroupOrientation.horizontal}) {
    /// set all checkboxes to checked
    state ??= List.filled(labels.length, true);

    /// check that all labels are distinct
    if (labels.toSet().length != labels.length) {
      throw ArgumentError('Not all labels are distinct');
    }

    _checkboxes = List<html.InputElement>(labels.length);

    _wrapper = html.DivElement()..setAttribute('style', 'margin-top: 8px;');

    if (orientation == CheckboxGroupOrientation.horizontal) {
      for (var i = 0; i < labels.length; i++) {
        _checkboxes[i] = html.CheckboxInputElement()
          ..id = '${wrapper.id}__cgl__${labels[i]}'
          ..checked = state[i];
        _wrapper.children.add(_checkboxes[i]);
        _wrapper.children.add(html.LabelElement()
          ..setAttribute('style', 'margin-left: 8px; margin-right: 8px;')
          ..text = labels[i]
          ..htmlFor = _checkboxes[i].id);
      }
    } else {
      throw UnimplementedError('Implement vertical!');
      // see radio_group_input
    }

    wrapper.children.add(_wrapper);
  }

  void setAttribute(String name, String value) =>
      _wrapper.setAttribute(name, value);

  set checked(List<bool> x) {
    for (var i = 0; i < x.length; i++) {
      _checkboxes[i].checked = x[i];
    }
  }

  List<bool> get checked => _checkboxes.map((e) => e.checked).toList();

  List<String> get selected {
    var out = <String>[];
    for (var i=0; i<labels.length; i++) {
      if (_checkboxes[i].checked) out.add(labels[i]);
    }
    return out;
  }

  void onChange(Function x) {
    _checkboxes = _checkboxes.map((e) {
      e.onChange.listen(x);
      return e;
    }).toList();
  }
}
