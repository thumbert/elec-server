import 'package:elec_server/src/db/lib_prod_dbs.dart';
import 'package:timezone/data/latest.dart';
import 'package:elec_server/src/db/weather/winter_storms.dart';
import 'package:html/parser.dart';

/// Go to https://www.weather.gov/box/pastevents#, open the editor and copy the
/// html table with the year you want.
void getStormNames() {
  var input =
      r"""<li class="ui-menu-item"><div aria-haspopup="true" id="ui-id-14" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper"><span class="ui-menu-icon ui-icon ui-icon-caret-1-e"></span>2019</div>
      <ul role="menu" aria-expanded="false" class="ui-menu ui-widget ui-widget-content ui-front" style="display: none; top: 82px; left: 150px;" aria-hidden="true">
  <li class="ui-menu-item"><div id="Dec_29-30_2019" title="Max Gust, Snowfall, Ice Accum" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Dec 29-30, 2019</div></li>
  <li class="ui-menu-item"><div id="Dec_17-18_2019" title="Snowfall, Ice Accum" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Dec 17-18, 2019</div></li>
  <li class="ui-menu-item"><div id="Dec_13-14_2019" title="pcpn,gust" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Dec 13-14, 2019</div></li>
  <li class="ui-menu-item"><div id="Dec_11_2019" title="Snowfall" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Dec 11, 2019</div></li>
  <li class="ui-menu-item"><div id="Dec_09-10_2019" title="Precip" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Dec 09-10, 2019</div></li>
  <li class="ui-menu-item"><div id="Dec_06_2019" title="Snowfall" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Dec 06, 2019</div></li>
  <li class="ui-menu-item"><div id="Dec_01-03_2019" title="Snowfall" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Dec 01-03, 2019</div></li>
  <li class="ui-menu-item"><div id="Nov_24_2019" title="Max Gust, Snowfall, Precip" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Nov 24, 2019</div></li>
  <li class="ui-menu-item"><div id="Oct_31-Nov_01_2019" title="Max Gust, Sustained Wind" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Oct 31-Nov, 01</div></li>
  <li class="ui-menu-item"><div id="Oct_27_2019" title="Max Gust, Precip" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Oct 27, 2019</div></li>
  <li class="ui-menu-item"><div id="Oct_16-17_2019" title="pcpn,gust,wind,pcpn24" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Oct 16-17, 2019</div></li>
  <li class="ui-menu-item"><div id="Oct_10-12_2019" title="Max Gust, Precip, Sustained Wind" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Oct 10-12, 2019</div></li>
  <li class="ui-menu-item"><div id="Jun_13-14_2019" title="pcpn,pcpn24" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Jun 13-14, 2019</div></li>
  <li class="ui-menu-item"><div id="Jun_11_2019" title="pcpn,pcpn24,gust" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Jun 11, 2019</div></li>
  <li class="ui-menu-item"><div id="Apr_26-27_2019" title="pcpn" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Apr 26-27, 2019</div></li>
  <li class="ui-menu-item"><div id="Apr_22-23_2019" title="pcpn" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Apr 22-23, 2019</div></li>
  <li class="ui-menu-item"><div id="Apr_15-16_2019" title="pcpn,gust,wind" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Apr 15-16, 2019</div></li>
  <li class="ui-menu-item"><div id="Apr_03-04_2019" title="gust,wind" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Apr 03-04, 2019</div></li>
  <li class="ui-menu-item"><div id="Mar_22-23_2019" title="snow,snow24" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Mar 22-23, 2019</div></li>
  <li class="ui-menu-item"><div id="Mar_10_2019" title="snow,snow24" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Mar 10, 2019</div></li>
  <li class="ui-menu-item"><div id="Mar_03-04_2019" title="Snowfall" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Mar 03-04, 2019</div></li>
  <li class="ui-menu-item"><div id="Mar_02_2019" title="Snowfall" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Mar 02, 2019</div></li>
  <li class="ui-menu-item"><div id="Feb_27-28_2019" title="Snowfall" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Feb 27-28, 2019</div></li>
  <li class="ui-menu-item"><div id="Feb_24-25_2019" title="Max Gust" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Feb 24-25, 2019</div></li>
  <li class="ui-menu-item"><div id="Feb_20-21_2019" title="snow,snow24,ice" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Feb 20-21, 2019</div></li>
  <li class="ui-menu-item"><div id="Feb_17-18_2019" title="Snowfall" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Feb 17-18, 2019</div></li>
  <li class="ui-menu-item"><div id="Feb_12_2019" title="Snowfall, Ice Accum" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Feb 12, 2019</div></li>
  <li class="ui-menu-item"><div id="Feb_08-09_2019" title="gust,wind" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Feb 08-09, 2019</div></li>
  <li class="ui-menu-item"><div id="Jan_29-30_2019" title="Snowfall" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Jan 29-30, 2019</div></li>
  <li class="ui-menu-item"><div id="Jan_24_2019" title="Max Gust, Precip, Sustained Wind" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Jan 24, 2019</div></li>
  <li class="ui-menu-item"><div id="Jan_19-20_2019" title="snow,ice,pcpn,gust,wind" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Jan 19-20, 2019</div></li>
  <li class="ui-menu-item"><div id="Jan_09_2019" title="snow,gust,wind" tabindex="-1" role="menuitem" class="ui-menu-item-wrapper">Jan 09, 2019</div></li>
  </ul>
  </li>""";
  var doc = parse(input);
  var items = doc.getElementsByClassName('ui-menu-item');
  for (var item in items) {
    var id = item.firstChild?.attributes['id'];
    print("'$id',");
  }
}

Future<void> tests() async {
  // group('Winter storms tests', () {
  //   var archive = WinterStormsArchive();
  //
  // });
}

winterStormTests() async {
  var archive = WinterStormsArchive();

  await archive.setupDb();

  await archive.dbConfig.db.open();
  await archive.updateDb();
  await archive.dbConfig.db.close();
}

Future<void> main() async {
  initializeTimeZones();
  DbProd();
  await winterStormTests();

  // getStormNames();

//  var date = '4/19/2018';
//  var time = ' 700 AM';
//  var fmt1 = new DateFormat('M/dd/yyyy');
//  print(fmt1.parse(date));
//
//  var fmt2 = new DateFormat('M/dd/yyyy h:mm a');
//  print(fmt2.parse('4/19/2018 7:00 AM'));

  //print(dt);
}
