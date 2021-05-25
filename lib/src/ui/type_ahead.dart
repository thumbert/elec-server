import 'dart:html';

import 'dart:math';

/// Port of https://www.w3schools.com/howto/howto_js_autocomplete.asp

class TypeAhead {
  DivElement? wrapper;
  late InputElement _input;
  List<String> values;

  /// the max height of the dropdown in px
  int maxHeight;
  int maxDropdown;
  String? _value;

  // the wrapper for the autocomplete-list
  late DivElement _al;
  late int _currentFocus;
  /// All matches that satisfy the input.  Only [maxDropdown] elements of
  /// this list are shown on the screen.
  late List<DivElement> _bs;


  TypeAhead(this.wrapper, this.values,
      {String placeholder = '', this.maxHeight = 300, this.maxDropdown = 12}) {
    _input = InputElement(type: 'text')
      ..id = '${wrapper!.id}-input'
      ..placeholder = placeholder;

    // a div element that will hold all the items
    _al = DivElement()
      ..setAttribute('id', '${_input.id}-typeahead-list')
      ..setAttribute('class', 'typeahead-items');
//      ..setAttribute('style', 'max-height: ${maxHeight}px; overflow-y: auto;');

    _bs = <DivElement>[];

    _input.onInput.listen((e) {
      _value = _input.value;
      _closeAllLists();
      _currentFocus = -1;

      Iterable<String> candidates;
      if (_value == '') {
        candidates = values;
      } else {
//        // match start only
//        candidates = values
//            .where((e) => e.toUpperCase().startsWith(_value.toUpperCase()));
        /// match everywhere inside
        candidates = values
            .where((e) => e.toUpperCase().contains(_value!.toUpperCase()))
            .toList();
      }

      for (var value in candidates) {
        // highlight the match with <strong>
        var regex = RegExp(_value!, caseSensitive: false);
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
        _b.innerHtml = _b.innerHtml! + '<input type="hidden" value="$value">';
        _b.onClick.listen((e) {
          _input.value = value;
          _closeAllLists();
          _input.select();
        });
        _bs.add(_b);
      }
      /// add the first [maxDropdown] elements
      _al.children.addAll(_bs.sublist(0, min(_bs.length, maxDropdown)));
    });

    _input.onKeyDown.listen((e) {
      var _xs = _al.children.cast<DivElement>();
      if (_xs.isEmpty) return;
      if (e.keyCode == 40) {
        // if arrow DOWN is pressed
        _currentFocus = min(_currentFocus + 1, _bs.length);
        _addActive(_xs);
      } else if (e.keyCode == 38) {
        // if arrow UP is pressed
        _currentFocus = max(0, _currentFocus - 1);
        _addActive(_xs);
      } else if (e.keyCode == 13) {
        // if ENTER is pressed
        if (_currentFocus > -1) {
          _input.value = _bs[_currentFocus].text;
          _closeAllLists();
          _input.select();
        }
      }
    });
    _input.onClick.listen((e) => _closeAllLists());

    wrapper!.children.add(_input);
    wrapper!.children.add(_al);
  }

  void _addActive(List<DivElement> xs) {
    _removeActive(xs);
    if (_currentFocus >= xs.length) {
      _al.children.clear();
      var _end = min(_bs.length, _currentFocus+1);
      var _start = min(max(0, _currentFocus-maxDropdown+1), max(0, _bs.length-maxDropdown));
      _al.children.addAll(_bs.sublist(_start, _end));
      xs.last.classes.add('typeahead-active');
    } else if (_currentFocus <= 0) {
      xs.first.classes.add('typeahead-active');
    } else {
      _al.children.clear();
      _al.children.addAll(_bs.sublist(0, min(maxDropdown, _bs.length)));
      xs[_currentFocus].classes.add('typeahead-active');
    }

  }

  String? get value => _input.value;

  void setAttribute(String name, String value) => _input.setAttribute(name, value);

  set value(String? x) => _input.value = x;

  set spellcheck(bool value) => _input.spellcheck = value;

  void onSelect(Function x) => _input.onSelect.listen(x as void Function(Event)?);


  void _removeActive(List<DivElement> xs) {
    for (var i = 0; i < xs.length; i++) {
      xs[i].classes.remove('typeahead-active');
    }
  }

  void _closeAllLists() {
    _bs.clear();
    _al.children.clear();
  }
}
