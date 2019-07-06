
import 'dart:async';
import 'dart:html' as html;
import 'package:elec_server/src/ui/spinner.dart';

longComputation(Spinner spinner) async {
  Timer(Duration(seconds: 5), () {
    spinner.visibility(false);
    print('Done computation');
  });
}

main() async {
  var wrapper = html.querySelector('#content');

  var spinner = Spinner(wrapper);
  longComputation(spinner);

}
