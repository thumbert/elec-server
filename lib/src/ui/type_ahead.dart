import 'dart:html';

/// Port of https://www.w3schools.com/howto/howto_js_autocomplete.asp

class TypeAhead {
  DivElement wrapper;
  InputElement _input;
  List<String> values;

  /// the max height of the dropdown in px
  int maxHeight;
  String _value;

  DivElement _al; // the autocomplete-list
  int _currentFocus;

  TypeAhead(this.wrapper, this.values,
      {String placeholder = '', this.maxHeight = 300}) {
    _input = InputElement(type: 'text')
      ..id = '${wrapper.id}-input'
      ..placeholder = placeholder;

    // a div element that will hold all the items
    _al = DivElement()
      ..setAttribute('id', '${_input.id}-typeahead-list')
      ..setAttribute('class', 'typeahead-items')
      ..setAttribute('style', 'max-height: ${maxHeight}px; overflow-y: auto;');

    _input.onInput.listen((e) {
      _value = _input.value;
      _closeAllLists();
      _currentFocus = -1;

      Iterable<String> candidates;
      if (_value == '') {
        candidates = values;
      } else {
        candidates = values
//            .where((e) => e.toUpperCase().startsWith(_value.toUpperCase()));
            .where((e) => e.toUpperCase().contains(_value.toUpperCase()));
      }

      for (var value in candidates) {
        // highlight the match with <strong>
        var regex = RegExp(_value, caseSensitive: false);
        var matches = regex.allMatches(value);
        var splits = value.split(regex);
        var innerHtml = '';
        for (var s=0; s<splits.length-1; s++) {
          innerHtml += '${splits[s]}<strong>${matches.elementAt(s).group(0)}</strong>';
        }
        innerHtml += '${splits.last}';
        var _b = DivElement()..innerHtml = innerHtml;
//        _b.innerHtml = '<strong>${value.substring(0, _value.length)}</strong>';
//        _b.innerHtml += value.substring(_value.length);
        _b.innerHtml += '<input type="hidden" value="${value}">';
        _b.onClick.listen((e) {
          _input.value = value;
          _closeAllLists();
          _input.select();
        });
        _al.children.add(_b);
      }
    });

    _input.onKeyDown.listen((e) {
      //if (_al == null) return;
      var _xs = _al.children.cast<DivElement>();
      if (_xs.isEmpty) return;
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

  void setAttribute(String name, String value) =>
      _input.setAttribute(name, value);

  set value(String x) => _input.value = x;

  set spellcheck(bool value) => _input.spellcheck = value;

  void onSelect(Function x) {
    _input.onSelect.listen(x);
  }

  void _addActive(List<DivElement> xs) {
    _removeActive(xs);
    if (_currentFocus >= xs.length) _currentFocus = 0;
    if (_currentFocus < 0) _currentFocus = xs.length - 1;
    xs[_currentFocus].classes.add('typeahead-active');
  }

  void _removeActive(List<DivElement> xs) {
    for (var i = 0; i < xs.length; i++) {
      xs[i].classes.remove('typeahead-active');
    }
  }

  void _closeAllLists() {
    _al.children.clear();
  }
}
