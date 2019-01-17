import 'dart:html';

import 'package:elec_server/src/ui/categorical_dropdown_checkbox_filter.dart';
import 'package:elec_server/src/ui/categorical_dropdown_filter.dart';
import 'package:elec_server/src/ui/numeric_input.dart';
import 'package:elec_server/src/ui/numeric_range_filter.dart';
import 'package:elec_server/src/ui/radio_group_input.dart';
import 'package:elec_server/src/ui/selectable_list.dart';

main() async {
  var messageCdcf =
      querySelector('#categorical-dropdown-checkbox-filter-message');
  var cdcf = CategoricalDropdownCheckboxFilter(
      querySelector('#categorical-dropdown-checkbox-filter'),
      ['Federer', 'Nadal'],
      'Tennis players');
  cdcf.onChange((e) => messageCdcf.text =
      'You selected ${cdcf.value}, checked: ${cdcf.checked}');

  var messageCdf = querySelector('#categorical-dropdown-filter-message');
  var cdf = CategoricalDropdownFilter(
      querySelector('#categorical-dropdown-filter'),
      ['Federer', 'Nadal'],
      'Tennis players');
  cdf.onChange((e) => messageCdf.text = 'You selected ${cdf.value}');

  /// numeric input
  var messageNi = querySelector('#numeric-input-message');
  var numericInput = NumericInput(querySelector('#numeric-input'), 'Asset Id');
  numericInput
      .onChange((e) => messageNi.text = 'You entered ${numericInput.value}');

  /// numeric input with thousand separator
  var messageNic = querySelector('#numeric-input-message-comma');
  var numericInputC = NumericInput(
      querySelector('#numeric-input-comma'), 'Property value',
      size: 9);
  numericInputC
      .onChange((e) => messageNic.text = 'You entered ${numericInputC.value}');

  /// numeric range
  var messageNr = querySelector('#numeric-range-message');
  var numericRange =
      NumericRangeFilter(querySelector('#numeric-range'), 0, 100, 'Percent');
  numericRange.onChange((e) => messageNr.text =
      'The range is ${numericRange.minValue} - ${numericRange.maxValue}');

  /// a radio group
  var message = querySelector('#radio-group-message');
  var radioGroup =
      RadioGroupInput(querySelector('#radio-group'), ['Federer', 'Nadal']);
  radioGroup.onChange((e) => message.text = 'You selected ${radioGroup.value}');

  /// a selectable list
  var messageSl = querySelector('#selectable-list-message');
  var selectableList = SelectableList(querySelector('#selectable-list'),
      ['Apple', 'Banana', 'Lemon', 'Orange', 'Strawberry', 'Watermelon']);
  selectableList.onChange((e) {
    messageSl.text = 'You selected ${selectableList.selected.join(', ')}';
  });
}
