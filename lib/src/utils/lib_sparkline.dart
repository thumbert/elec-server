library utils.lib_sparkline;

import 'package:dama/analysis/interpolation/multi_linear_interpolator.dart';
import 'package:dama/dama.dart';

/// See https://alexplescan.com/posts/2023/07/08/easy-svg-sparklines/
///
class Sparkline {
  Sparkline(this.x, this.y);

  List<num> x;
  List<num> y;

  ///
  String toSvg({
    int width = 300,
    int height = 100,
    String lineColor = 'dodgerblue',
    String fillColor = 'lightblue',
    String? markerColor = 'blue',
    int strokeWidth = 2,
    int border = 2,
  }) {
    final rangeX = range(x);
    final rangeY = range(y);
    // final border = 3.0;
    final transformX =
        MultiLinearInterpolator(rangeX, [border, width - border]);
    final xCoords = x.map((e) => transformX.valueAt(e).round()).toList();
    final transformY =
        MultiLinearInterpolator(rangeY, [height - border, border]);
    final yCoords = y.map((e) => transformY.valueAt(e).round()).toList();
    var pathFragments = <String>[];
    for (var i = 0; i < x.length; i++) {
      var prefix = (i == 0) ? 'M' : 'L';
      pathFragments.add('$prefix ${xCoords[i]},${yCoords[i]}');
    }
    final path = pathFragments.join(' ');

    var buf = StringBuffer();
    buf.writeln('<svg width="${width}px" height="${height}px">');
    if (markerColor != null) {
      buf.writeln(
          '<defs><marker id="dot" viewBox="0 0 4 4" refX="2" refY="2" markerWidth="2" markerHeight="2" fill="$markerColor"><circle cx="2" cy="2" r="2"/></marker></defs>');
    }
    // the shaded area
    buf.writeln('<path');
    buf.writeln('  d="$path L ${width - border},$height L $border,$height Z"');
    buf.writeln('  stroke="transparent" fill="$fillColor"');
    buf.writeln('/>');
    // the line itself
    buf.writeln('<path');
    buf.writeln('  d="$path"');
    buf.writeln(
        '  stroke="$lineColor" stroke-width="2" fill="transparent" vector-effect="non-scaling-stroke"');
    if (markerColor != null) {
      buf.writeln(
          '  marker-mid="url(#dot)" marker-start="url(#dot)" marker-end="url(#dot)"');
    }
    buf.writeln('/>');

    buf.writeln('</svg>');
    return buf.toString();
  }
}
