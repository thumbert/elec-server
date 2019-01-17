library ui.selectable_list;

import 'dart:html';

class SelectableList {
  Element wrapper;
  List<String> values;

  List<bool> _onOff; // keep track of which elements are selected
  List<int> _ind;
  DivElement _listWrapper;
  List<DivElement> _divs;

  /// A simple vertical list of selectable values.  Selection is done by
  /// clicking on the element, if you click again, the element is deselected.
  SelectableList(this.wrapper, this.values) {

    int n = values.length;

    _onOff = List.filled(n, false);
    _ind = List.generate(n, (i) => i);

    _listWrapper = DivElement();
    _divs = <DivElement>[];
    for (int i=0; i<n; i++) {
      var aux = DivElement()
        ..text = values[i]
        ..id = '__sl_$i'
        ..onClick.listen((e) => _select1(i));
      _divs.add(aux);
    }
    _listWrapper.children.addAll(_divs);

    wrapper.children.add(_listWrapper);
  }

  /// keep track of selections
  _select1(int i) {
    _onOff[i] = !_onOff[i];
    if (_onOff[i]) {
      // need to highlight
      _divs[i].style.backgroundColor = 'yellow';
    } else {
      // return it to normal
      _divs[i].style.backgroundColor = null;
    }
    // need to fire a change event on the wrapper
    _listWrapper.dispatchEvent(Event.eventType('HTMLEvents', 'change'));
  }

  /// Get the selected values.
  List<String> get selected =>
      _ind.where((i) => _onOff[i]).map((i) => values[i]).toList();

  /// Listen to changes
  onChange(Function x) {
    _listWrapper.onChange.listen(x);
  }

}