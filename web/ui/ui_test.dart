import 'dart:html';

import 'package:elec_server/src/ui/categorical_dropdown_checkbox_filter.dart';
import 'package:elec_server/src/ui/numeric_input.dart';
import 'package:elec_server/src/ui/numeric_range_filter.dart';
import 'package:elec_server/src/ui/radio_group_input.dart';

main() async {
  var messageCdcf = querySelector('#categorical-dropdown-checkbox-filter-message');
  var cdcf = CategoricalDropdownCheckboxFilter(
      querySelector('#categorical-dropdown-checkbox-filter'),
      ['Federer', 'Nadal'],
      'Tennis players');
  cdcf.onChange((e) => messageCdcf.text = 'You selected ${cdcf.value}');

  /// numeric input
  var messageNi = querySelector('#numeric-input-message');
  var numericInput = NumericInput(querySelector('#numeric-input'), 'Asset Id');
  numericInput
      .onChange((e) => messageNi.text = 'You entered ${numericInput.value}');


  /// numeric range
  var messageNr = querySelector('#numeric-range-message');
  var numericRange = NumericRangeFilter(querySelector('#numeric-range'), 0, 100, 'Percent');
  numericRange
      .onChange((e) => messageNr.text = 'The range is ${numericRange.minValue} - ${numericRange.maxValue}');


  /// a radio group
  var message = querySelector('#radio-group-message');
  var radioGroup =
      RadioGroupInput(querySelector('#radio-group'), ['Federer', 'Nadal']);
  radioGroup.onChange((e) => message.text = 'You selected ${radioGroup.value}');
}