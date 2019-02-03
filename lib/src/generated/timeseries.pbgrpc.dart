///
//  Generated code. Do not modify.
//  source: timeseries.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

import 'dart:async' as $async;

import 'package:grpc/grpc.dart';

import 'timeseries.pb.dart';
export 'timeseries.pb.dart';

class LmpClient extends Client {
  static final _$getLmp =
      new ClientMethod<HistoricalLmpRequest, NumericTimeSeries>(
          '/elec.Lmp/GetLmp',
          (HistoricalLmpRequest value) => value.writeToBuffer(),
          (List<int> value) => new NumericTimeSeries.fromBuffer(value));

  LmpClient(ClientChannel channel, {CallOptions options})
      : super(channel, options: options);

  ResponseFuture<NumericTimeSeries> getLmp(HistoricalLmpRequest request,
      {CallOptions options}) {
    final call = $createCall(
        _$getLmp, new $async.Stream.fromIterable([request]),
        options: options);
    return new ResponseFuture(call);
  }
}

abstract class LmpServiceBase extends Service {
  String get $name => 'elec.Lmp';

  LmpServiceBase() {
    $addMethod(new ServiceMethod<HistoricalLmpRequest, NumericTimeSeries>(
        'GetLmp',
        getLmp_Pre,
        false,
        false,
        (List<int> value) => new HistoricalLmpRequest.fromBuffer(value),
        (NumericTimeSeries value) => value.writeToBuffer()));
  }

  $async.Future<NumericTimeSeries> getLmp_Pre(
      ServiceCall call, $async.Future request) async {
    return getLmp(call, await request);
  }

  $async.Future<NumericTimeSeries> getLmp(
      ServiceCall call, HistoricalLmpRequest request);
}
