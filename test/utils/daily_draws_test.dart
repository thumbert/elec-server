
import 'dart:math';

import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';

class Contract {
  int contractId;
  num maxDailyQuantity;  // in MMBTU
  num annualContractQuantity;  // in MMBTU
  Interval interval;
  String pipeline;

  TimeSeries<num> calls;

  Contract.fromMap(Map<String,dynamic> x) {
    contractId = x['contractId'] ?? ArgumentError('contractId is required');
    maxDailyQuantity = x['maxDailyQuantity'] ?? ArgumentError('maxDailyQuantity is required');
    annualContractQuantity = x['annualContractQuantity'] ?? ArgumentError('annualDailyQuantity is required');
    interval = parseTerm(x['term']) ?? ArgumentError('term is required');
    pipeline = x['pipeline'];
  }
}

List<Contract> getContracts() {
  var contracts = [
    {
      'contractId': 1,
      'maxDailyQuantity': 1900,
      'annualContractQuantity': 171000,
      'term': 'Nov19-Mar20',
      'pipeline': 'A',
    },
    {
      'contractId': 2,
      'maxDailyQuantity': 5400,
      'annualContractQuantity': 243000,
      'term': 'Nov19-Mar20',
      'pipeline': 'A',
    },
    {
      'contractId': 3,
      'maxDailyQuantity': 2700,
      'annualContractQuantity': 200000,
      'term': 'Dec19-Feb20',
      'pipeline': 'B',
    },
  ];
  return contracts.map((e) => Contract.fromMap(e)).toList();
}

/// Simulate the calls on this contract from startDate to asOfDate
TimeSeries<num> simulateCalls(Contract contract, Date asOfDate) {
  var ts = TimeSeries<num>();
  var lastDate = asOfDate;
  var contractLastDate = Date.fromTZDateTime(contract.interval.end).subtract(1);
  if (asOfDate.isAfter(lastDate)) lastDate = contractLastDate;
  var days = Interval(contract.interval.start, lastDate.end)
      .splitLeft((dt) => Date.fromTZDateTime(dt));
  var rand = Random(contract.contractId);
  for (var day in days) {
    var draw = 0;
    ts.add(IntervalTuple(day, draw));
  }
  return ts;
}


void main() {

}