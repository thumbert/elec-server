library ui.numeric_range_filter;

import 'dart:html' as html;

class NumericRangeFilter {
  html.Element wrapper;
  html.TextInputElement _min;
  html.TextInputElement _max;
  num _defaultMin, _defaultMax;
  String name;

  /// A two way range filter for a numeric variable.
  ///
  /// Variable [name] is the text of the accompanying label.
  ///
  /// Need to trigger an action onChange.
  NumericRangeFilter(this.wrapper, num minValue, num maxValue, this.name,
      {int size}) {
    _defaultMin = minValue;
    _defaultMax = maxValue;
    size ??= 4;

    var _wrapper = html.DivElement()
      ..setAttribute('style', 'margin-top: 8px');
    _wrapper.children.add(html.LabelElement()
      ..text = '$name above'
      ..setAttribute('style', 'margin-left: 15px'));
    _min = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px')
      ..placeholder = minValue.toString()
      ..size = size
      ..value = minValue.round().toString();
    _wrapper.children.add(_min);

    _wrapper.children.add(html.LabelElement()
      ..text = 'below'
      ..setAttribute('style', 'margin-left: 15px'));
    _max = html.TextInputElement()
      ..setAttribute('style', 'margin-left: 15px')
      ..placeholder = maxValue.toString()
      ..size = size
      ..value = maxValue.round().toString();
    _wrapper.children.add(_max);

    wrapper.children.add(_wrapper);
  }

  num get minValue {
    var minV, maxV;
    if (_min.value.isEmpty)
      minV = _defaultMin;
    else
      minV = num.parse(_min.value);
    if (_max.value == '')
      maxV = _defaultMax;
    else
      maxV = num.parse(_max.value);
    if (minV > maxV) {
      _min.setAttribute('style', 'margin-left: 15px; border: 2px solid red;');
    } else {
      _min.setAttribute('style', 'margin-left: 15px; border-color: initial;');
    }
    return minV;
  }

  num get maxValue {
    var minV, maxV;
    if (_min.value.isEmpty)
      minV = _defaultMin;
    else
      minV = num.parse(_min.value);
    if (_max.value == '')
      maxV = _defaultMax;
    else
      maxV = num.parse(_max.value);
    if (minV > maxV) {
      _max.setAttribute('style', 'margin-left: 15px; border: 2px solid red;');
    } else {
      _max.setAttribute('style', 'margin-left: 15px; border-color: initial;');
    }
    return maxV;
  }

  /// trigger a change when either one of the two inputs change
  onChange(Function x) {
    _min.onChange.listen(x);
    _max.onChange.listen(x);
  }
}
