
import 'dart:html' as html;
import 'package:elec_server/src/ui/slider2.dart';


void main() async {
  var wrapper = html.querySelector('#content')!;
  var slider = Slider2(3, 30,
      leftInitialValue: 3,
      rightInitialValue: 10,
      increment: 0.1,
      format: (x) => x!.toStringAsFixed(1));
  wrapper.children.add(slider.inner);

  var message = html.querySelector('#message');
  slider.onChange((e) {
    message!.text = 'Selected values between '
        '${slider.leftValue} and ${slider.rightValue}';
  });


}
