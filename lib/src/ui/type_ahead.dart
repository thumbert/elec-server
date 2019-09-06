import 'dart:html';

/// Port of https://www.w3schools.com/howto/howto_js_autocomplete.asp

class TypeAhead {

  DivElement wrapper;
  InputElement _input;
  List<String> values;

  String _value;

  DivElement _al;  // autocomplete-list
  int _currentFocus;

  TypeAhead(this.wrapper, this.values, {String placeholder: ''}) {
    _input = InputElement(type: 'text')
      ..id = '${wrapper.id}-input'
      ..placeholder = placeholder;


    // a div element that will hold all the items
    _al = DivElement()
      ..setAttribute('id', '${_input.id}-typeahead-list')
      ..setAttribute('class', 'typeahead-items');


    _input.onInput.listen((e) {
      _value = _input.value;
      _closeAllLists();
      _currentFocus = -1;
      if (_value == '') return;

      for (var value in values
          .where((e) => e.toUpperCase().startsWith(_value.toUpperCase()))) {
        var _b = DivElement();
        _b.innerHtml = '<strong>${value.substring(0, _value.length)}</strong>';
        _b.innerHtml += value.substring(_value.length);
        _b.innerHtml += '<input type="hidden" value="${value}">';
        _al.children.add(_b);
      }
    });

    _input.onKeyDown.listen((e) {
      //if (_al == null) return;
      var _xs = _al.children.cast<DivElement>();
      if (_xs.length == 0) return;
      if (e.keyCode == 40) {
        // if arrow DOWN is pressed
        _currentFocus++;
        _addActive(_xs);
      } else if (e.keyCode == 38) {
        // if arrow UP is pressed
        _currentFocus--;
        _addActive(_xs);
      } else if (e.keyCode == 13) {
        // if ENTER is pressed
        if (_currentFocus > -1) {
          _input.value = _xs[_currentFocus].text;
          _closeAllLists();
          _input.select();
        }
      }
    });

    _input.onClick.listen((e) {
      _closeAllLists();
    });

    wrapper.children.add(_input);
    wrapper.children.add(_al);
  }

  String get value => _input.value;

  onSelect(Function x) {
    _input.onSelect.listen(x);
  }

  void _addActive(List<DivElement> xs) {
    _removeActive(xs);
    if (_currentFocus >= xs.length) _currentFocus = 0;
    if (_currentFocus < 0) _currentFocus = xs.length - 1;
    xs[_currentFocus].classes.add('typeahead-active');
  }

  void _removeActive(List<DivElement> xs) {
    for (var i=0; i<xs.length; i++) {
      xs[i].classes.remove('typeahead-active');
    }
  }

  void _closeAllLists() {
    _al.children.clear();
  }
}
