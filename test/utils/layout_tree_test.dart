import 'package:test/test.dart';
import 'package:elec_server/src/utils/layout_tree.dart';

void main() {
  group('Layout tree tests:', () {
    test('Parsing a Single', () {
      var json = {
        'node': 'Single',
        'size': {'width': 900, 'height': 600},
      };
      var root = WindowNode.fromJson(json) as SingleNode;
      expect(json, root.toJson());
      expect(root.width(), 900);
      expect(root.height(), 600);
    });

    test('Parsing the simplest Column', () {
      var json = {
        'node': 'Column',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 300},
          },
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 300},
          },
        ]
      };
      var root = WindowNode.fromJson(json) as ColumnNode;
      expect(json, root.toJson());
      var n0 = root.children.first as SingleNode;
      expect(n0.width(), 900);
      expect(n0.height(), 300);
    });

    test('Parsing the simplest Row', () {
      var json = {
        'node': 'Row',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 450, 'height': 600},
          },
          {
            'node': 'Single',
            'size': {'width': 450, 'height': 600},
          },
        ]
      };
      var root = WindowNode.fromJson(json) as RowNode;
      expect(json, root.toJson());
      var n0 = root.children.first as SingleNode;
      expect(n0.width(), 450);
      expect(n0.height(), 600);
    });

    test('Parsing a 3 level deep tree', () {
      var json = {
        'node': 'Row',
        'children': [
          {
            'node': 'Column',
            'children': [
              {
                'node': 'Single',
                'size': {'width': 450, 'height': 300},
              },
              {
                'node': 'Single',
                'size': {'width': 450, 'height': 300},
              },
            ]
          },
          {
            'node': 'Single',
            'size': {'width': 450, 'height': 600},
          },
        ]
      };
      var root = WindowNode.fromJson(json) as RowNode;
      expect(json, root.toJson());
      var n0 = root.children.first as ColumnNode;
      var n00 = n0.children.first as SingleNode;
      expect(n00.width(), 450);
      expect(n00.height(), 300);
    });

    test('Split a Single', () {
      var root = SingleNode(900, 600);
      var h2 = root.splitHorizontally(2);
      var top = h2.children.first as SingleNode;
      expect(top.width(), root.width());
      expect(top.height(), root.height() / 2);

      var v2 = root.splitVertically(2);
      var left = v2.children.first as SingleNode;
      expect(left.width(), root.width() / 2);
      expect(left.height(), root.height());
    });

    test('Split Column horizontally one level down', () {
      var root = WindowNode.fromJson({
        'node': 'Column',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 300},
          },
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 400},
          },
        ]
      }) as ColumnNode;
      var x = root.splitHorizontally(1, n: 2) as ColumnNode;
      expect(x.flatten().length, 3);
      var x1 = x.children[1] as ColumnNode;
      expect(x1.children.length, 2);
      expect(x1.children.first.width(), 900);
      expect(x1.children.first.height(), 200);
    });

    test('Split Column vertically one level down', () {
      var root = WindowNode.fromJson({
        'node': 'Column',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 300},
          },
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 400},
          },
        ]
      }) as ColumnNode;
      var x = root.splitVertically(1, n: 2) as ColumnNode;
      expect(x.flatten().length, 3);
      var x1 = x.children[1] as RowNode;
      expect(x1.children.length, 2);
      expect(x1.children.first.width(), 450);
      expect(x1.children.first.height(), 400);
    });

    test('Split Row vertically one level down', () {
      var root = WindowNode.fromJson({
        'node': 'Row',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 450, 'height': 300},
          },
          {
            'node': 'Single',
            'size': {'width': 450, 'height': 400},
          },
        ]
      }) as RowNode;
      var x = root.splitVertically(1, n: 2) as RowNode;
      expect(x.flatten().length, 3);
      var x1 = x.children[1] as RowNode;
      expect(x1.children.length, 2);
      expect(x1.children.first.width(), 225);
      expect(x1.children.first.height(), 400);
    });

    test('Split Row horizontally one level down', () {
      var root = WindowNode.fromJson({
        'node': 'Row',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 450, 'height': 300},
          },
          {
            'node': 'Single',
            'size': {'width': 450, 'height': 400},
          },
        ]
      }) as RowNode;
      var x = root.splitHorizontally(1, n: 2) as RowNode;
      expect(x.flatten().length, 3);
      var x1 = x.children[1] as ColumnNode;
      expect(x1.children.length, 2);
      expect(x1.children.first.width(), 450);
      expect(x1.children.first.height(), 200);
    });

    test('Split horizontally one level down', () {
      var root = WindowNode.fromJson({
        'node': 'Column',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 300},
          },
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 400},
          },
        ]
      }) as ColumnNode;
      var x = root.splitHorizontally(1, n: 2) as ColumnNode;
      expect(x.flatten().length, 3);
      var x1 = x.children[1] as ColumnNode;
      expect(x1.children.length, 2);
      expect(x1.children.first.width(), 900);
      expect(x1.children.first.height(), 200);
    });

    test('Split horizontally two levels down', () {
      var root = WindowNode.fromJson({
        'node': 'Column',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 300},
          },
          {
            'node': 'Row',
            'children': [
              {
                'node': 'Single',
                'size': {'width': 600, 'height': 300},
              },
              {
                'node': 'Single',
                'size': {'width': 300, 'height': 300},
              },
            ],
          },
        ]
      }) as ColumnNode;
      var x = root.splitHorizontally(1, n: 2) as ColumnNode;
      expect(x.flatten().length, 4);
      // dimensions for child 1 remain the same
      var x1 = x.children[1] as RowNode;
      expect(x1.width(), 900);
      expect(x1.height(), 300);
      //
      var x10 = x1.children[0] as ColumnNode;
      expect(x10.children.length, 2);
      expect(x10.children.first.width(), 600);
      expect(x10.children.first.height(), 150);
    });

    test('Split vertically two levels down', () {
      var root = WindowNode.fromJson({
        'node': 'Column',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 300},
          },
          {
            'node': 'Row',
            'children': [
              {
                'node': 'Single',
                'size': {'width': 300, 'height': 300},
              },
              {
                'node': 'Single',
                'size': {'width': 400, 'height': 300},
              },
              {
                'node': 'Single',
                'size': {'width': 200, 'height': 300},
              },
            ],
          },
        ]
      }) as ColumnNode;
      var x = root.splitVertically(2, n: 2) as ColumnNode;
      expect(x.flatten().length, 5);
      // dimensions for child 1 remain the same
      var x1 = x.children[1] as RowNode;
      expect(x1.width(), 900);
      expect(x1.height(), 300);
      //
      var x11 = x1.children[1] as RowNode;
      expect(x11.children.length, 2);
      expect(x11.children.first.width(), 200);
      expect(x11.children.first.height(), 300);
    });

    test('Split multiple times', () {
      var root = SingleNode(900, 600);
      var h2 = root.splitHorizontally(2);
      var v3 = h2.splitVertically(0) as ColumnNode;
      var v4 = v3.splitVertically(2);
      expect(v4.flatten().length, 4);
    });

    test('Tree traversal', () {
      var root = WindowNode.fromJson({
        'node': 'Row',
        'children': [
          {
            'node': 'Column',
            'children': [
              {
                'node': 'Single',
                'size': {'width': 450, 'height': 300},
              },
              {
                'node': 'Single',
                'size': {'width': 450, 'height': 300},
              },
            ]
          },
          {
            'node': 'Single',
            'size': {'width': 450, 'height': 600},
          },
        ]
      }) as RowNode;

      var xs = root.flatten();
      expect(xs.length, 3);
      expect(xs.first.width(), 450);
      expect(xs.first.height(), 300);
      expect(xs.last.width(), 450);
      expect(xs.last.height(), 600);
    });

    test('Remove node, move to Single', () {
      var root = WindowNode.fromJson({
        'node': 'Row',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 300, 'height': 600},
          },
          {
            'node': 'Single',
            'size': {'width': 400, 'height': 600},
          },
        ]
      }) as RowNode;
      var x = root.removeAt(0);
      expect(x is SingleNode, true);
      expect(x.width(), 700);
      expect(x.height(), 600);
    });

    test('Remove node, remain Sequence', () {
      var root = WindowNode.fromJson({
        'node': 'Row',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 300, 'height': 600},
          },
          {
            'node': 'Single',
            'size': {'width': 400, 'height': 600},
          },
          {
            'node': 'Single',
            'size': {'width': 500, 'height': 600},
          },
        ]
      }) as RowNode;
      var x = root.removeAt(1) as RowNode;
      expect(x.width(), 1200);
      expect(x.height(), 600);
      expect(x.children.length, 2);
      //
      expect(x.children.first.width(), 500);
      expect(x.children.first.height(), 600);
      //
      expect(x.children.last.width(), 700);
      expect(x.children.last.height(), 600);
    });

    test('Remove inside node, resize all', () {
      var root = WindowNode.fromJson({
        'node': 'Column',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 300},
          },
          {
            'node': 'Row',
            'children': [
              {
                'node': 'Single',
                'size': {'width': 400, 'height': 300},
              },
              {
                'node': 'Single',
                'size': {'width': 300, 'height': 300},
              },
              {
                'node': 'Single',
                'size': {'width': 200, 'height': 300},
              },
            ],
          },
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 400},
          },
        ]
      }) as ColumnNode;
      var x = root.removeAt(2) as ColumnNode; // the (300,300) window
      expect(x.children.length, 3); // same as the original
      expect(x.width(), 900);
      expect(x.height(), 1000);
      // 1st node is a single window
      var x0 = x.children.first as SingleNode;
      expect(x0.width(), 900);
      expect(x0.height(), 300);
      // 2nd node is a row with 2 windows
      var x1 = x.children[1] as RowNode;
      expect(x1.width(), 900);
      expect(x1.height(), 300);
      expect(x1.children.length, 2);
      expect(x1.children.first.width(), 550);
      expect(x1.children.first.height(), 300);
      expect(x1.children.last.width(), 350);
      expect(x1.children.last.height(), 300);
    });

    test('Remove inside node, collapse Row to Single', () {
      var root = WindowNode.fromJson({
        'node': 'Column',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 300},
          },
          {
            'node': 'Row',
            'children': [
              {
                'node': 'Single',
                'size': {'width': 600, 'height': 300},
              },
              {
                'node': 'Single',
                'size': {'width': 300, 'height': 300},
              },
            ],
          },
        ]
      }) as ColumnNode;
      var x = root.removeAt(1) as ColumnNode; // the (300,300) window
      expect(x.children.length, 2);
      expect(x.width(), 900);
      expect(x.height(), 600);
      // 1st node is the original single window
      var x0 = x.children.first as SingleNode;
      expect(x0.width(), 900);
      expect(x0.height(), 300);
      // 2nd node is also a single window
      var x1 = x.children[1] as SingleNode;
      expect(x1.width(), 900);
      expect(x1.height(), 300);
    });

    test('Remove node from 3rd level down, collapse Column to Single', () {
      var root = WindowNode.fromJson({
        'node': 'Column',
        'children': [
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 200},
          },
          {
            'node': 'Row',
            'children': [
              {
                'node': 'Column',
                'children': [
                  {
                    'node': 'Single',
                    'size': {'width': 600, 'height': 50},
                  },
                  {
                    'node': 'Single',
                    'size': {'width': 600, 'height': 150},
                  },
                ],
              },
              {
                'node': 'Single',
                'size': {'width': 300, 'height': 200},
              },
            ],
          },
          {
            'node': 'Single',
            'size': {'width': 900, 'height': 200},
          },
        ]
      }) as ColumnNode;
      var x = root.removeAt(2) as ColumnNode; // the (300,300) window
      expect(x.children.length, 3);
      expect(x.width(), 900);
      expect(x.height(), 600);
      // 1st node is the original single window
      var x0 = x.children.first as SingleNode;
      expect(x0.width(), 900);
      expect(x0.height(), 200);
      // 2nd node is Row
      var x1 = x.children[1] as RowNode;
      expect(x1.width(), 900);
      expect(x1.height(), 200);
      // this node has collapsed to a single
      var x10 = x1.children[0] as SingleNode;
      expect(x10.width(), 600);
      expect(x10.height(), 200);
    });
  });
}
