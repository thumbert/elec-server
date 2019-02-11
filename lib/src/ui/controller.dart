library ui.controller;

class Controller {
  /// Keep track of which checkboxes are toggled
  var checkboxes = <String>[];

  /// Keep track of which value selectors have values
  var filters = <String,dynamic>{};

  /// Keep track of which range selectors have values
  var ranges = <String,List<num>>{};

  /// A Controller to keep track of UI elements that are selected and/or toggled.
  /// This allows you to separate the aggregation logic from the UI elements,
  /// so it can be tested separately.  Started doing this in Aug18, and I like
  /// the pattern.  For example:
  /// <p> To add an entity checkbox: checkboxes = ['entity']
  /// <p> To add an entity filter: filters['bucket'] = '5x16'
  /// <p> To add an range filter: ranges['temperature'] = [-30,110]
  Controller({this.checkboxes, this.filters, this.ranges}) {
    checkboxes ??= <String>[];

    filters ??= <String,dynamic>{};

    ranges ??= <String,List<num>>{};
  }
  
  String toString() {
    var out = '';
    if (checkboxes.isNotEmpty)
      out = out + 'checkboxes: ${checkboxes.join(',')}\n';
    if (filters.isNotEmpty) {
      out = out + 'filters:\n';
      for (var e in filters.entries) {
        out = out + '   ${e.key}: ${e.value}\n';
      }
    }
    if (ranges.isNotEmpty) {
      out = out + 'ranges:\n';
      for (var e in filters.entries) {
        out = out + '   ${e.key}: {min: ${e.value[0]}, max: ${e.value[1]}}\n';
      }
    }
    return out;
  }
  
}

