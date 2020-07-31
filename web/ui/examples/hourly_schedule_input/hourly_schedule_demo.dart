
import 'dart:html';
import 'package:date/date.dart';
import 'package:elec_server/src/ui/hourly_schedule_input.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';


void main() async {
  await initializeTimeZones();

  var location = getLocation('US/Eastern');
  var term = Term.parse('Jan21-Mar21', location);
//  var hs1 = HourlyScheduleInput(term);
//  querySelector('#wrapper').children.add(hs1.inner);


  /// make an HourlyScheduleInput show up when editing
  ///
  var input = querySelector('#value-input');
  var hs2 = HourlyScheduleInput(term, header: 'Quantity schedule')
    ..visibility = false;
  querySelector('#hs2').children.add(hs2.inner);
  input.onKeyDown.listen((e) {
    if (e.altKey == true && e.keyCode == 49) {
      e.preventDefault();
      hs2.visibility = true;
    }
  });
  hs2.onClose((e) {
    print('input closed');
    print(hs2.timeseries);
  });




}

