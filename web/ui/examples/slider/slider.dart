
import 'dart:html' as html;
import 'package:elec_server/src/ui/slider2.dart';


void main() async {
  var wrapper = html.querySelector('#content');
  var spinner = Slider2(3, 30,
      leftInitialValue: 3,
      rightInitialValue: 10,
      increment: 0.1,
      format: (num x) => x.toStringAsFixed(1));
  wrapper.children.add(spinner.inner);

  var message = html.querySelector('#message');
  spinner.onChange((e) {
    message.text = 'Selected values between '
        '${spinner.leftValue} and ${spinner.rightValue}';
  });


}
