library db.lib_mis_reports_test;

import 'dart:io';

import 'package:date/date.dart';
import 'package:elec_server/src/db/lib_mis_reports.dart';
import 'package:test/test.dart';

void tests() {
  group('MIS reports processing: ', () {
    test('read report', () {
      var file = File('test/_assets/sd_rtncpcpymt_000000001_2015100200_20141024155608.CSV');
      var report = MisReport(file);
      expect(report.accountNumber(), '000000001');
      expect(report.forDate(), Date.utc(2015, 10, 2));
      expect(report.timestamp(), DateTime.utc(2014, 10, 24, 15, 56, 8));
      var data = report.readTabAsMap(tab: 0);
      expect(data.length, 15);
    });
  });
}

void main() {
  tests();
}