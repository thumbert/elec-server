library ui.slider2;

import 'dart:html' as html;

import 'dart:math' as math;

/// Multi-range sliders
/// https://bashooka.com/coding/25-amazing-css-range-slider-designs/

/// This implementation is a dart port from
/// https://codepen.io/glitchworker/pen/XVdKqj
class Slider2 {
  html.DivElement inner;
  html.InputElement _inputL, _inputR;

  num minValue, maxValue, leftInitialValue, rightInitialValue, increment;

  /// Go from value to text displayed
  String Function(num) format;

  /// Go from value of variable to percent of slider.
  num Function(num) scale;

  /// Go from percent of slider to value.
  num Function(num) scaleInverse;

  /// A two range slider to constrain values between min and max.
  /// [increment] can be a decimal number, by default it splits the [min,max]
  /// range in 100.
  Slider2(this.minValue, this.maxValue,
      {this.leftInitialValue,
      this.rightInitialValue,
      this.increment,
      this.format}) {
    var _range = maxValue - minValue;
    leftInitialValue ??= minValue;
    rightInitialValue ??= maxValue;
    increment ??= _range/100;
    format ??= (num x) => x.toString();
    scale = (num x) => math.max(
        0,
        math.min(100,
            num.parse((100 * (x - minValue) / _range).toStringAsFixed(1))));
    scaleInverse = (num percent) => math.min(maxValue,
        minValue + _range * percent/100);

    if (!(minValue <= leftInitialValue &&
        leftInitialValue <= rightInitialValue &&
        rightInitialValue <= maxValue)) {
      throw ArgumentError('Inputs are not properly ordered.'
          'minValue <= leftInitialValue <= rightInitialValue <= maxValue');
    }

    var _step = (100*increment/_range);
    _inputL = html.InputElement()
      ..type = 'range'
      ..tabIndex = 0
      ..value = scale(leftInitialValue).toString()
      ..min = '0'
      ..max = '100'
      ..step = _step.toStringAsFixed(1)
      ..onInput.listen((event) {
        var first = _inputL.parentNode.firstChild; // div
        _inputL.value = math
            .min(num.parse(_inputL.value),
                scale(num.parse(first.childNodes[6].firstChild.text)) - _step)
            .toStringAsFixed(1);
        var value = num.parse(_inputL.value);
        var children = first.childNodes;
        // inverse-left
        (children[0] as html.Element)..setAttribute('style', 'width:${value}%');
        // range
        var _style = (children[2] as html.Element).getAttribute('style');
        _style = ['left:$value%', _style.split(';')[1]].join(';');
        (children[2] as html.Element)..setAttribute('style', _style);
        // thumb
        (children[3] as html.Element)..setAttribute('style', 'left:$value%');
        // sign
        (children[5] as html.Element)..setAttribute('style', 'left:$value%');
        (children[5].firstChild as html.Element)
          ..innerHtml = '${format(scaleInverse(num.parse(_inputL.value)))}';
      });

    _inputR = html.InputElement()
      ..type = 'range'
      ..tabIndex = 0
      ..value = scale(rightInitialValue).toString()
      ..min = '0'
      ..max = '100'
      ..step = _step.toStringAsFixed(1)
      ..onInput.listen((event) {
        var first = _inputR.parentNode.firstChild; // div
        _inputR.value = math
            .max(num.parse(_inputR.value),
                scale(num.parse(first.childNodes[5].firstChild.text)) + _step)
            .toStringAsFixed(1);
        var value = num.parse(_inputR.value); // between 0 and 100
        var _rightWidth = (100 - value).toStringAsFixed(1);
        var children = first.childNodes;
        // inverse-right
        (children[1] as html.Element)
          ..setAttribute('style', 'width:${_rightWidth}%');
        var _style = (children[2] as html.Element).getAttribute('style');
        _style = [_style.split(';')[0], 'right:${_rightWidth}%'].join(';');
        // range
        (children[2] as html.Element)..setAttribute('style', _style);
        // thumb
        (children[4] as html.Element)
          ..setAttribute('style', 'left:${value.toStringAsFixed(1)}%');
        // sign
        (children[6] as html.Element)
          ..setAttribute('style', 'left:${value.toStringAsFixed(1)}%');
        (children[6].firstChild as html.Element)
          ..innerHtml = '${format(scaleInverse(num.parse(_inputR.value)))}';
      });

    var _rightInitialWidth =
        (100 - scale(rightInitialValue)).toStringAsFixed(1);

    inner = html.DivElement()
      ..setAttribute('slider', '')
      ..id = 'slider-distance'
      ..children.addAll([
        html.DivElement()
          ..children.addAll([
            html.DivElement()
              ..setAttribute('inverse-left', '')
              ..setAttribute('style', 'width:${scale(leftInitialValue)}%'),
            html.DivElement()
              ..setAttribute('inverse-right', '')
              ..setAttribute('style', 'width:$_rightInitialWidth%'),
            html.DivElement()
              ..setAttribute('range', '')
              ..setAttribute(
                  'style',
                  'left:${scale(leftInitialValue)}%;'
                      'right:$_rightInitialWidth%'),
            html.SpanElement()
              ..setAttribute('thumb', '')
              ..setAttribute('style',
                  'left:${scale(leftInitialValue).toStringAsFixed(1)}%'),
            html.SpanElement()
              ..setAttribute('thumb', '')
              ..setAttribute('style',
                  'left:${scale(rightInitialValue).toStringAsFixed(1)}%'),
            html.DivElement()
              ..setAttribute('sign', '')
              ..setAttribute('style',
                  'left:${scale(leftInitialValue).toStringAsFixed(1)}%')
              ..children
                  .add(html.SpanElement()..text = format(leftInitialValue)),
            html.DivElement()
              ..setAttribute('sign', '')
              ..setAttribute('style',
                  'left:${scale(rightInitialValue).toStringAsFixed(1)}%')
              ..children
                  .add(html.SpanElement()..text = format(rightInitialValue)),
          ]),
        _inputL,
        _inputR,
      ]);
  }

  num get leftValue =>
    num.parse(format(scaleInverse(num.parse(_inputL.value))));

  num get rightValue =>
      num.parse(format(scaleInverse(num.parse(_inputR.value))));


  /// trigger a change when either one of the two inputs change
  void onChange(Function x) {
    _inputL.onChange.listen(x);
    _inputR.onChange.listen(x);
  }
}

