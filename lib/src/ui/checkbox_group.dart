library ui.checkbox_group;

import 'dart:html' as html;

enum CheckboxGroupOrientation { horizontal, vertical }

class CheckboxGroup {
  html.Element? wrapper;
  late html.Element inner;
  late List<html.CheckboxInputElement?> _checkboxes;
  List<String> labels;
  List<bool>? state;
  /// If you want a label to the left of the checkboxes
  String leftLabel;
  /// space between the elements, in px
  int marginRight;
  
  CheckboxGroupOrientation orientation;

  /// A List of checkboxes with a text labels.
  ///
  /// Variable [labels] is the text of the associated labels.
  /// By default [state] is set to all elements [true] i.e. checked.
  /// Need to trigger an action onChange.
  CheckboxGroup(this.wrapper, this.labels,
      {this.state, this.orientation = CheckboxGroupOrientation.horizontal, 
      this.leftLabel = '', this.marginRight = 8}) {
    /// set all checkboxes to checked
    state ??= List.filled(labels.length, true);

    /// check that all labels are distinct
    if (labels.toSet().length != labels.length) {
      throw ArgumentError('Not all labels are distinct');
    }

    _checkboxes = List<html.InputElement?>.filled(labels.length, null);

    inner = html.DivElement()
      ..setAttribute('style', 'margin-top: 8px;')
      ..children.add(html.LabelElement()
        ..setAttribute('style', 'float: left; margin-right: 16px;')
        ..text = leftLabel);

    if (orientation == CheckboxGroupOrientation.horizontal) {
      for (var i = 0; i < labels.length; i++) {
        _checkboxes[i] = html.CheckboxInputElement()
          ..id = '${wrapper!.id}__cgl__${labels[i]}'
          ..checked = state![i];
        inner.children.add(_checkboxes[i]!);
        inner.children.add(html.LabelElement()
          ..setAttribute('style',
              'margin-left: 8px; margin-right: ${marginRight}px;')
          ..text = labels[i]
          ..htmlFor = _checkboxes[i]!.id);
      }
    } else {
      throw UnimplementedError('Implement vertical!');
      // see radio_group_input
    }

    wrapper!.children.add(inner);
  }

  void setAttribute(String name, String value) =>
      inner.setAttribute(name, value);

  set checked(List<bool?> x) {
    for (var i = 0; i < x.length; i++) {
      _checkboxes[i]!.checked = x[i];
    }
  }

  List<bool?> get checked => _checkboxes.map((e) => e!.checked).toList();

  List<String> get selected {
    var out = <String>[];
    for (var i=0; i<labels.length; i++) {
      if (_checkboxes[i]!.checked!) out.add(labels[i]);
    }
    return out;
  }

  void onChange(Function x) {
    _checkboxes = _checkboxes.map((e) {
      e!.onChange.listen(x as void Function(html.Event)?);
      return e;
    }).toList();
  }
}
