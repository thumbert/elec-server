
import 'package:elec_server/src/db/lib_iso_express.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:date/date.dart';

/// This will download the files in the default download directory
/// 
Future<void> downloadDays(List<Date> days) async {
  var browser = await puppeteer.launch(headless: false);
  var page = await browser.newPage();
  // need to visit this site first to get the right cookies
  await page.goto(
      'https://www.iso-ne.com/isoexpress/web/reports/operations/-/tree/seven-day-solar-power-forecast',
      wait: Until.networkIdle);
  // download each individual days    
  for (var date in days) {
    try {
      await page.goto(
          'https://www.iso-ne.com/transform/csv/sphf?start=${yyyymmdd(date)}',
          wait: Until.networkIdle);
    } catch (e) {
      // print(e);
    }
  }
  await Future.delayed(Duration(seconds: 2));
  await browser.close();
}


// Future<void> downloadOne() async {
//   // final response0 = await get(Uri.parse(
//   //     'https://www.iso-ne.com/isoexpress/web/reports/operations/-/tree/seven-day-solar-power-forecast'));
//   // var cookies = response0.headers['set-cookie']!.split(';');
//   // var token = cookies.firstWhere((e) => e.contains('isox_token'));
//   // print('token:');
//   // print(token);

//   // return token.replaceAll(RegExp(r"(.*)isox_token="), "");

//   final response0 = await get(Uri.parse(
//       'https://www.iso-ne.com/isoexpress/web/reports/operations/-/tree/seven-day-solar-power-forecast'));
//   final headers = response0.headers;
//   headers.forEach((k, v) => print('$k: $v'));
//   print(response0.request);

//   /// Need to get a token first.
//   /// The token gets set when you visit the main url first
//   final token =
//       '8C7Vl2RfY4h/S49Vg4E5lYcfAGfy/S+CWLiP3rvk5pjXqYineAJYPgKT63zIUYSG43m7y0tKtI555aRc49hgHHuRfy1I58blzu5P4yfSdanJmn+AQAGUhvG+GbCtxQubJAHqiRhjL1Tcdy2KJCNIxbwBIh8p4P+VgZYOXRAuuDI=';
//   
//   // make sure you have the correct user-agent, that matches your system 
//   final response = await get(
//     Uri.parse('https://www.iso-ne.com/transform/csv/sphf?start=20241021'),
//     // headers: headers,
//     headers: {
//       'cookie': 'COOKIE_SUPPORT=true; isox_token="$token";',
//       'user-agent':
//           'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36'
//     },
//   );

//   print(response.body);
// }

