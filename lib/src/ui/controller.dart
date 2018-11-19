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
//    checkboxes ??= [];
//
//    filters ??= {};
//
//    ranges ??= <String,List<num>>{};

  }
}

