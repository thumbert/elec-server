import 'dart:html';


import 'package:elec_server/src/ui2/selector_checkbox.dart';
import 'package:elec_server/src/ui2/selector_load_spec.dart';
import 'package:timezone/browser.dart';
import 'package:elec_server/ui.dart';
import 'package:elec_server/src/ui2/selector.dart';

void testsUi1() {
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
  var numericInput = NumericInput(querySelector('#numeric-input'), 'Asset Id',
      placeholder: 2481, rightLabel: 'Right label name');
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

  /// a term input
  var messageTi = querySelector('#term-input-message');
  var termInput = TermInput(querySelector('#term-input'), defaultValue: 'Jan19');
  termInput.onChange((e) => messageTi.text = 'You typed ${termInput.value}');


  /// a selectable list
  var messageSl = querySelector('#selectable-list-message');
  var fruits = ['Apple', 'Banana', 'Lemon', 'Orange', 'Strawberry',
    'Watermelon'];
  var selectableList = SelectableList(querySelector('#selectable-list'),
      fruits);
  selectableList.onChange((e) {
    messageSl.text = 'You selected ${selectableList.selected.join(', ')}';
  });


  /// a simple checkbox with a label
  var messageCl = querySelector('#checkbox-label-message');
  var checkboxLabel = CheckboxLabel(querySelector('#checkbox-label'),
      'Sprinkles?')..checked = true;
  checkboxLabel.onChange((e) {
    if (checkboxLabel.checked) {
      messageCl.text = 'You want sprinkles';
    } else {
      messageCl.text = 'No sprinkles for you!';
    }
  });

  /// text input with allowed values only
  var messageTextInputConstrained = querySelector('#text-input-constrained-message')
    ..text = 'Only Apple, Banana, Lemon, Orange, Strawberry, Watermelon are allowed';
  var textInputConstrained = TextInput(querySelector('#text-input-constrained'),
      'Fruit', initialValue: 'Banana', allow: (String x) => fruits.contains(x));
  textInputConstrained.onChange((e) {
    messageTextInputConstrained.text = 'You selected ${textInputConstrained.value}';
  });

  /// checkbox group
  var messageCheckboxGroup = querySelector('#checkbox-group-message')
    ..text = 'Select several';
  var checkboxGroup = CheckboxGroup(querySelector('#checkbox-group'),
      ['Roger', 'Rafa', 'Novak', 'Sacha']);
  checkboxGroup.onChange((e) {
    messageCheckboxGroup.text = 'You selected ${checkboxGroup.selected}';
  });

}


void testsUi2() {
  var zones = ['ALL', 'MAINE', 'NH', 'VT', 'CT', 'RI', 'SEMA', 'WCMA', 'NEMA'];
  var message1 = querySelector('#ui2-zone-selector-message');
  var zoneSelector = Selector(querySelector('#ui2-zone-selector'),
      zones, 'Load Zone');
  zoneSelector.onChange((e) =>
    message1.text = 'You selected ${zoneSelector.value}');

  var zoneSelectorCheckbox = SelectorCheckbox(querySelector('#ui2-zone-selector-checkbox'), zones, 'Load Zone');
  print(zoneSelectorCheckbox.value);

//  var loadSpecSelector = LoadSpecSelector(
//      querySelector('#ui2-load-spec-selector'));

}


void main() async {
  await initializeTimeZone();

//  testsUi2();

  testsUi1();



}
