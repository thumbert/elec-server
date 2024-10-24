
import 'package:date/date.dart';
import 'package:elec_server/src/db/isoexpress/sevenday_solar_forecast.dart';


void main() async {
  // final token = await getIsoxToken();
  // print('out:');
  // print(token);

  await downloadDays([
    Date.utc(2024, 10, 21),
    Date.utc(2024, 10, 22),
    Date.utc(2024, 10, 23),
  ]);
}

