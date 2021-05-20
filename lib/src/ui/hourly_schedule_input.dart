// library ui.hourly_schedule_input;
//
// import 'dart:html';
//
// import 'package:date/date.dart';
// import 'package:elec_server/src/utils/iso_timestamp.dart';
// import 'package:intl/intl.dart';
// import 'package:jexcel_dart/jexcel_dart.dart';
// import 'package:timeseries/timeseries.dart';
// import 'package:timezone/timezone.dart';
// import 'package:elec/src/time/hourly_schedule.dart';
//
//
// class HourlyScheduleInput {
//   Term term;
//   DivElement inner;
//
//   /// What you use as a text label on the same row as the _close button
//   DivElement _headerDiv;
//   List<DivElement> _tables;
//   List<LIElement> _tabs;
//   List<Jexcel> _dataTables;
//   ButtonElement _clear, _save, _close;
//   TimeSeries<num> _ts;
//   HourlySchedule hourlySchedule;
//
//   /// keep track of which tab was saved last
//   int _tabSaved;
//
//   static final DateFormat _isoFmt = DateFormat('yyyy-MM');
//
//   /// Support only monthly data for now.  Hourly data is difficult to display
//   /// in the browser (I will investigate.)
//   HourlyScheduleInput(this.term, {String header = ''}) {
//     _initialize();
//     _headerDiv.text = header;
//   }
//
// //  HourlyScheduleInput.fromJson(Map<String,dynamic> xs) {
// //    var _location = getLocation(xs['tzLocation']);
// //    var _interval = Interval(TZDateTime.parse(_location, xs['term']['start']),
// //        TZDateTime.parse(_location, xs['term']['end']));
// //    term = Term.fromInterval(_interval);
// //    _initialize();
// //  }
//
//   void _initialize() {
//     _ts = TimeSeries<num>();
//     _tabs = [
//       LIElement()
//         ..className = 'page-item active'
//         ..children = [
//           AnchorElement()
//             ..className = 'page-link rounded-0'
//             ..href = '#monthly'
//             ..text = 'Monthly'
//         ],
//       LIElement()
//         ..className = 'page-item'
//         ..children = [
//           AnchorElement()
//             ..className = 'page-link rounded-0'
//             ..href = '#hourly'
//             ..text = 'Hourly'
//         ],
//     ];
//
//     _tables = List.generate(2, (i) => DivElement());
//     _tables[1]
//       ..setAttribute('style', 'display: none;')
//       ..children = [
//         DivElement()..text = 'To be implemented ...',
//         TextInputElement()
//           ..placeholder = 'Enter shooju tsdbid'
//           ..style.width = '200px',
//         ButtonElement()
//           ..className = 'btn btn-primary'
//           ..style.marginLeft = '10px'
//           ..children = [
//             SpanElement()
//               ..className = 'spinner-border spinner-border-sm'
//           ]
//           ..text = 'Load',
//     ];
//
//     _dataTables = <Jexcel>[
//       makeMonthlyTable(),
// //      makeHourlyTable(),
//     ];
//
//     _clear = ButtonElement()
//       ..setAttribute('type', 'button')
//       ..setAttribute('class', 'btn btn-primary save')
//       ..text = 'Clear';
//
//     _save = ButtonElement()
//       ..setAttribute('type', 'button')
//       ..setAttribute('class', 'btn btn-primary save')
//       ..text = 'Save';
//
//     _close = ButtonElement()
//       ..setAttribute('type', 'button')
//       ..setAttribute('class', 'btn btn-outline-light text-dark material-icons')
//       ..text = 'close';
//
//     var _content = DivElement()
//       ..children = [
//         UListElement()
//           ..className = 'pagination'
//           ..children = _tabs,
//         DivElement()
//           ..id = 'monthly'
//           ..children = [_tables[0]],
//         DivElement()
//           ..id = 'hourly'
//           ..children = [_tables[1]],
//       ];
//     _headerDiv = DivElement();
//
//     inner = DivElement()
//       ..setAttribute('style', 'width: 350px')
//       ..children = [
//         DivElement()
//           ..className = 'hourly-schedule'
//           ..children = [
//             // first row
//             _headerDiv,
//             _close,
//             // second row
//             _content,
//             DivElement(),
//             // third row
//             DivElement()..children = [
//               _clear,
//               _save..setAttribute('style', 'margin-left: 10px;'),
//             ],
//             DivElement(),
//           ],
//       ];
//
//     addEvents();
//   }
//
//   TimeSeries<num> get timeseries => _ts;
//
//   int getActiveTab() {
//     for (var i = 0; i < _tabs.length; i++) {
//       if (_tabs[i].className.contains('active')) return i;
//     }
//     throw StateError('No tab is active!');
//   }
//
//   set visibility(bool flag) {
//     if (flag) {
// //      inner.setAttribute('style', 'top: 0px; left: 0px;');
//       inner.style.display = 'block';
//       inner.style.zIndex = '1';
// //      inner.style.position = 'relative';
//       if (_tabSaved != null) {
//         /// restore this tab
//         populateTable(_tabSaved);
//       }
//     } else {
//       inner.style.display = 'none';
//     }
//   }
//
//   void addEvents() {
//     /// if you click on a tab, make it active, display the contents
//     for (var i = 0; i < _tabs.length; i++) {
//       var _tab = _tabs[i];
//       _tab.onClick.listen((event) {
//         /// set all tabs to inactive
//         for (var i = 0; i < _tabs.length; i++) {
//           _tabs[i].className = 'page-item';
//           _tables[i].setAttribute('style', 'display: none;');
//         }
//
//         /// set this tab to active
//         _tab.className = 'page-item active';
//         _tables[getActiveTab()].setAttribute('style', 'display: block;');
//       });
//     }
//
//     /// close the window
//     _close.onClick.listen((event) {
//       visibility = false;
//       for (var i = 0; i < _tables.length; i++) {
//         if (_tabSaved != null && _tabSaved == i) continue;
//         clearTable(i);
//       }
//     });
//
//     /// clear the data
//     _clear.onClick.listen((event) {
//       if (_ts.isNotEmpty) {
//         for (var i = 0; i < _tables.length; i++) {
//           clearTable(i);
//         }
//       }
//       _ts = TimeSeries<num>();
//     });
//
//     /// save the data
//     _save.onClick.listen((event) {
//       var i = getActiveTab();
//       if (i == 0) {
//         saveMonthlyTimeSeries();
//       } else if (i == 1) {
//         saveHourlyTimeSeries();
//       } else {
//         throw ArgumentError('Not supported tab: $i');
//       }
//       _tabSaved = i;
//     });
//   }
//
//   set header(String value) => _headerDiv.text = value;
//
//   void onClose(Function x) {
//     _close.onClick.listen(x);
//   }
//
//   void saveMonthlyTimeSeries() {
//     var location = term.interval.start.location;
//     var bux = _dataTables[0].options.data;
//     _ts = TimeSeries<num>.fromIterable([
//       for (List obs in bux)
//         IntervalTuple<num>(
//             Month.parse(obs[0], location: location, fmt: _isoFmt),
//             num.tryParse(obs[1]) ?? 0)
//     ]);
//     clearTable(1);
//   }
//
//   void saveHourlyTimeSeries() {
//     var location = term.interval.start.location;
//     var bux = _dataTables[1].options.data;
//     _ts = TimeSeries<num>();
//     for (List obs in bux) {
//       var hbUtc = parseHourEndingStamp(mmddyyyy(Date.parse(obs[0])), obs[1]);
//       var hourBeginning =
//           TZDateTime(location, hbUtc.year, hbUtc.month, hbUtc.day, hbUtc.hour);
//       IntervalTuple<num>(
//           Hour.beginning(hourBeginning), num.tryParse(obs[2]) ?? 0);
//     }
//     clearTable(0);
//   }
//
//   void clearTable(int i) {
//     if (i == 0) {
//       /// the monthly table
//       _dataTables[0].setColumnData(
//           1, List.filled(_dataTables[0].options.data.length, ''));
//     } else if (i == 1) {
//       /// the hourly table
//       _dataTables[1].setColumnData(
//           2, List.filled(_dataTables[1].options.data.length, ''));
//     } else {
//       throw ArgumentError('tab $i not supported');
//     }
//   }
//
//   void populateTable(int i) {
//     if (i == 0) {
//       /// the monthly table
//       _dataTables[0].setColumnData(1, _ts.values.toList());
//     } else if (i == 1) {
//       /// the hourly table
//       _dataTables[1].setColumnData(2, _ts.values.toList());
//     } else {
//       throw ArgumentError('tab $i not supported');
//     }
//   }
//
//   Jexcel makeHourlyTable() {
//     var hours = term.hours();
//
//     var data = [
//       for (var i = 0; i < hours.length; i++)
//         [...toIsoHourEndingStamp(hours[i].start), '']
//     ];
//
//     var columns = [
//       Column(title: 'Date', width: 100, type: 'text', readOnly: true),
//       Column(title: 'Hour Ending', width: 120, type: 'text', readOnly: true),
//       Column(title: 'MW', width: 80, type: 'numeric'),
//     ];
//
//     return Jexcel(
//         _tables[1],
//         Options(
//           data: data,
//           columns: columns,
//           allowDeleteColumn: false,
//           allowInsertRow: false,
//           allowInsertColumn: false,
//           rowResize: false,
//           columnSorting: false,
//           allowRenameColumn: false,
//           tableOverflow: true,
//           tableHeight: '400px',
//         ));
//   }
//
//   Jexcel makeMonthlyTable() {
//     var months = term.interval
//         .splitLeft((dt) => Month.fromTZDateTime(dt))
//         .map((e) => e.toIso8601String())
//         .toList();
//
//     var data = [
//       for (var i = 0; i < months.length; i++) [months[i], '']
//     ];
//
//     var columns = [
//       Column(title: 'Month', width: 80, type: 'text', readOnly: true),
//       Column(title: 'MW', width: 80, type: 'numeric'),
//     ];
//
//     return Jexcel(
//         _tables[0],
//         Options(
//           data: data,
//           columns: columns,
//           allowDeleteColumn: false,
//           allowInsertRow: false,
//           allowInsertColumn: false,
//           rowResize: false,
//           columnSorting: false,
//           allowRenameColumn: false,
//           tableOverflow: true,
//           tableHeight: '400px',
//         ));
//   }
//
//   /// Serialize it
// //  Map<String, dynamic> toJson() {
// //    var out = <String,dynamic>{
// //      'term': {
// //        'start': term.interval.start.toIso8601String(),
// //        'end': term.interval.end.toIso8601String(),
// //      },
// //      'tzLocation': '',
// //    };
// //    if (_tabSaved != null) {
// //      /// you saved some data
// //      out['tab'] = _tabSaved;
// //      out['timeseries'] = [
// //        for (var e in _ts) <String, dynamic>{
// //          'start': e.interval.start.toIso8601String(),
// //          'end': e.interval.end.toIso8601String(),
// //          'value': e.value,
// //        }
// //      ];
// //    }
// //    return out;
// //  }
//
// }
