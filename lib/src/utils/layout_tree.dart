library utils.tree_layout;

import 'package:dama/dama.dart';

/// An experiment on how to manage windows on a canvas using a tree structure.
/// Tree nodes are of 3 types:
/// 1) SingleNode
/// 2) ColumnNode
/// 3) RowNode
/// this mimic a Flutter layout.
///
/// A canvas always starts with a Single window node.  A Single window has
/// a size (width,height).  You can split a Single window
/// vertically into a Row node or horizontally into Column node.  You can
/// remove Single windows.  When a Single window is removed the remaining
/// windows in that node group get resized.
///
///

sealed class WindowNode {
  num width();
  num height();

  static WindowNode fromJson(Map<String, dynamic> x) {
    if (x
        case {
          'node': String nodeType,
        }) {
      return switch (nodeType) {
        'Single' => SingleNode.fromJson(x),
        'Column' => ColumnNode.fromJson(x),
        'Row' => RowNode.fromJson(x),
        _ => throw ArgumentError('Unsupported nodeType $nodeType'),
      };
    } else {
      throw ArgumentError('Can\'t parse $x as a Layout Tree');
    }
  }

  /// Flatten the tree structure
  List<SingleNode> flatten();

  WindowNode resize(num width, num height);

  Map<String, dynamic> toJson();
}

class SingleNode extends WindowNode {
  SingleNode(num width, num height) {
    _width = width;
    _height = height;
  }
  late final num _width;
  late final num _height;

  @override
  List<SingleNode> flatten() {
    return [this];
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'node': 'Single',
      'size': {'width': _width, 'height': _height},
    };
  }

  static SingleNode fromJson(Map<String, dynamic> x) {
    if (x
        case {
          'node': 'Single',
          'size': {'width': num width, 'height': num height}
        }) {
      return SingleNode(width, height);
    } else {
      throw ArgumentError('Can\'t parse $x as a Single');
    }
  }

  /// Vertically split a single window into n equal parts
  RowNode splitVertically(int n) {
    assert(n > 1);
    var width = _width / n;
    var children = List<WindowNode>.generate(n, (index) => SingleNode(width, _height));
    return RowNode(children);
  }

  /// Horizontally split a single window into [n] equal parts
  ColumnNode splitHorizontally(int n) {
    assert(n > 1);
    var height = _height / n;
    var children = List<WindowNode>.generate(n, (index) => SingleNode(_width, height));
    return ColumnNode(children);
  }

  @override
  num height() => _height;

  @override
  num width() => _width;

  @override
  SingleNode resize(num width, num height) {
    return SingleNode(width, height);
  }
}

class ColumnNode extends WindowNode {
  ColumnNode(this.children) {
    assert(children.length > 1);
  }
  List<WindowNode> children;

  @override
  List<SingleNode> flatten() {
    return children.expand((child) => child.flatten()).toList();
  }

  static ColumnNode fromJson(Map<String, dynamic> x) {
    if (x
        case {
          'node': 'Column',
          'children': List<Map<String, dynamic>> children,
        }) {
      var nodes = [for (var child in children) WindowNode.fromJson(child)];
      return ColumnNode(nodes);
    } else {
      throw ArgumentError('Can\'t parse $x as a Column node');
    }
  }

  @override
  num height() => sum(children.map((e) => e.height()));

  @override
  num width() => children.first.width();

  /// Remove the i^th Single node, resize the remaining children.
  ///
  /// Note: different from the [removeAt] method for Dart's List, this method
  /// returns the modified tree (not the removed element.)
  WindowNode removeAt(int i) {
    var originalWidth = width();
    var originalHeight = height();
    var cs = flatten();
    if (cs.length == 2) {
      /// always collapse a Row and a Column with only one element
      return SingleNode(originalWidth, originalHeight);
    } else {
      /// need to remove the correct node from the children ...
      var sizes =
          children.map((e) => e.flatten().length).cumSum().toList().cast<int>();
      var indexChild = sizes.indexWhere((e) => e > i);

      switch (children[indexChild]) {
        case (RowNode node):
          children[indexChild] = node.removeAt(sizes[indexChild] - i - 1);
        case (ColumnNode node):
          children[indexChild] = node.removeAt(sizes[indexChild] - i - 1);
        case SingleNode():
          children.removeAt(indexChild);
          resize(originalWidth, originalHeight);
      }

      return this;
    }
  }

  /// Horizontally split the [i]^th Single node into [n] windows.
  /// Return the [i]^th node.
  WindowNode splitHorizontally(int i, {int n = 2}) {
    assert(i >= 0);
    /// need to find the correct node from the children ...
    var sizes =
        children.map((e) => e.flatten().length).cumSum().toList().cast<int>();
    var indexChild = sizes.indexWhere((e) => e > i);

    switch (children[indexChild]) {
      case (RowNode node):
        children[indexChild] =
            node.splitHorizontally(i - sizes[indexChild - 1], n: n);
      case (ColumnNode node):
        children[indexChild] =
            node.splitHorizontally(i - sizes[indexChild - 1], n: n);
      case (SingleNode node):
        children[indexChild] = node.splitHorizontally(n);
    }

    return this;
  }

  /// Vertically split the [i]^th Single node into [n] windows.
  /// Return the [i]^th node.
  WindowNode splitVertically(int i, {int n = 2}) {
    assert(i >= 0);
    /// need to find the correct node from the children ...
    var sizes =
        children.map((e) => e.flatten().length).cumSum().toList().cast<int>();
    var indexChild = sizes.indexWhere((e) => e > i);

    switch (children[indexChild]) {
      case (RowNode node):
        children[indexChild] =
            node.splitVertically(i - sizes[indexChild - 1], n: n);
      case (ColumnNode node):
        children[indexChild] =
            node.splitVertically(i - sizes[indexChild - 1], n: n);
      case (SingleNode node):
        children[indexChild] = node.splitVertically(n);
    }

    return this;
  }

  /// Spread the missing height (from the deposed widget) equitably across the
  /// remaining widgets.
  @override
  WindowNode resize(num width, num height) {
    var adjHeight =
        (height - children.map((e) => e.height()).sum()) / children.length;
    for (var i = 0; i < children.length; i++) {
      children[i] = children[i].resize(width, children[i].height() + adjHeight);
    }
    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'node': 'Column',
      'children': [for (var child in children) child.toJson()],
    };
  }
}

class RowNode extends WindowNode {
  RowNode(this.children) {
    assert(children.length > 1);
  }
  List<WindowNode> children;

  /// Remove the i^th Single node and resize the remaining children
  ///
  /// Note: different from the [removeAt] method for Dart's List, this method
  /// returns the modified tree (not the removed element.)
  WindowNode removeAt(int i) {
    var originalWidth = width();
    var originalHeight = height();
    var cs = flatten();
    if (cs.length == 2) {
      /// always collapse a Row and a Column with only one element
      return SingleNode(originalWidth, originalHeight);
    } else {
      /// need to remove the correct node from the children ...
      var sizes =
          children.map((e) => e.flatten().length).cumSum().toList().cast<int>();
      var indexChild = sizes.indexWhere((e) => e > i);

      switch (children[indexChild]) {
        case (RowNode node):
          children[indexChild] = node.removeAt(sizes[indexChild] - i - 1);
        case (ColumnNode node):
          children[indexChild] = node.removeAt(sizes[indexChild] - i - 1);
        case SingleNode():
          children.removeAt(indexChild);
          resize(originalWidth, originalHeight);
      }
      return this;
    }
  }

  /// Vertically split the [i]^th Single node into [n] windows.
  ///
  WindowNode splitHorizontally(int i, {int n = 2}) {
    assert(i >= 0);
    /// need to find the correct node from the children ...
    var sizes =
        children.map((e) => e.flatten().length).cumSum().toList().cast<int>();
    var indexChild = sizes.indexWhere((e) => e > i);

    switch (children[indexChild]) {
      case (RowNode node):
        children[indexChild] =
            node.splitHorizontally(i - sizes[indexChild - 1], n: n);
      case (ColumnNode node):
        children[indexChild] =
            node.splitHorizontally(i - sizes[indexChild - 1], n: n);
      case (SingleNode node):
        children[indexChild] = node.splitHorizontally(n);
    }

    return this;
  }

  /// Vertically split the [i]^th Single node into [n] windows.
  ///
  WindowNode splitVertically(int i, {int n = 2}) {
    assert(i >= 0);
    /// need to find the correct node from the children ...
    var sizes =
        children.map((e) => e.flatten().length).cumSum().toList().cast<int>();
    var indexChild = sizes.indexWhere((e) => e > i);

    switch (children[indexChild]) {
      case (RowNode node):
        children[indexChild] =
            node.splitHorizontally(i - sizes[indexChild - 1], n: n);
      case (ColumnNode node):
        children[indexChild] =
            node.splitVertically(i - sizes[indexChild - 1], n: n);
      case (SingleNode node):
        children[indexChild] = node.splitVertically(n);
    }

    return this;
  }

  @override
  List<SingleNode> flatten() {
    return children.expand((child) => child.flatten()).toList();
  }

  static RowNode fromJson(Map<String, dynamic> x) {
    if (x
        case {
          'node': 'Row',
          'children': List<Map<String, dynamic>> children,
        }) {
      var nodes = [for (var child in children) WindowNode.fromJson(child)];
      return RowNode(nodes);
    } else {
      throw ArgumentError('Can\'t parse $x as a Row node');
    }
  }

  @override
  num height() => children.first.height();

  @override
  num width() => sum(children.map((e) => e.width()));

  /// Spread the missing width (from the deposed widget) equitably across the
  /// remaining widgets.
  @override
  WindowNode resize(num width, num height) {
    var adjWidth =
        (width - children.map((e) => e.width()).sum()) / children.length;
    for (var i = 0; i < children.length; i++) {
      children[i] = children[i].resize(children[i].width() + adjWidth, height);
    }
    return this;
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'node': 'Row',
      'children': [for (var child in children) child.toJson()],
    };
  }
}
