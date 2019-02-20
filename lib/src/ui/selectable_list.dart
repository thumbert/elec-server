library ui.selectable_list;

import 'dart:html';

class SelectableList {
  Element wrapper;
  List<String> _values;
  String highlightColor;

  List<bool> _onOff; // keep track of which elements are selected
  List<int> _ind;
  DivElement _listWrapper;
  List<DivElement> _divs;

  /// A simple vertical list of selectable values.  Selection is done by
  /// clicking on the element, if you click again, the element is deselected.
  ///
  SelectableList(this.wrapper, List<String> values, {String style: 'width: 200px;',
    this.highlightColor: '#e6ffe6'}) {

    _listWrapper = DivElement()..setAttribute('style', style);

    this.values = values;

    wrapper.children.add(_listWrapper);
  }

  List<String> get values => _values;

  /// Set the values for the list.  It allows you to rebuild the list given an
  /// external event.
  set values(List<String> xs) {
    _values = List.from(xs);
    _onOff = List.filled(xs.length, false);
    _ind = List.generate(xs.length, (i) => i);
    var _wId = wrapper.id;  // to create unique ids

    _listWrapper.children.clear();
    _divs = <DivElement>[];
    for (int i=0; i<_values.length; i++) {
      var aux = DivElement()
        ..text = _values[i]
        ..id = '__sl_${_wId}_$i'
        ..onClick.listen((e) => _select1(i));
      aux.onMouseOver.listen((e) {
        if (!_onOff[i]) aux.style.backgroundColor='#f5f5f5';
      });
      aux.onMouseLeave.listen((e){
        if (!_onOff[i]) aux.style.backgroundColor=null;
      });
      _divs.add(aux);
    }
    _listWrapper.children.addAll(_divs);
  }

  /// keep track of selections
  _select1(int i) {
    _onOff[i] = !_onOff[i];
    if (_onOff[i]) {
      // need to highlight
      _divs[i].style.backgroundColor = highlightColor;
    } else {
      // return it to normal
      _divs[i].style.backgroundColor = null;
    }
    // need to fire a change event on the wrapper
    _listWrapper.dispatchEvent(Event.eventType('HTMLEvents', 'change'));
  }

  /// Get the selected values.
  List<String> get selected =>
      _ind.where((i) => _onOff[i]).map((i) => _values[i]).toList();

  /// Listen to changes
  onChange(Function x) {
    _listWrapper.onChange.listen(x);
  }
}
