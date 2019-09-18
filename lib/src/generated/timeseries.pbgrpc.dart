///
//  Generated code. Do not modify.
//  source: timeseries.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'timeseries.pb.dart' as $0;
export 'timeseries.pb.dart';

class LmpClient extends $grpc.Client {
  static final _$getLmp =
      $grpc.ClientMethod<$0.HistoricalLmpRequest, $0.NumericTimeSeries>(
          '/elec.Lmp/GetLmp',
          ($0.HistoricalLmpRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.NumericTimeSeries.fromBuffer(value));

  LmpClient($grpc.ClientChannel channel, {$grpc.CallOptions options})
      : super(channel, options: options);

  $grpc.ResponseFuture<$0.NumericTimeSeries> getLmp(
      $0.HistoricalLmpRequest request,
      {$grpc.CallOptions options}) {
    final call = $createCall(_$getLmp, $async.Stream.fromIterable([request]),
        options: options);
    return $grpc.ResponseFuture(call);
  }
}

abstract class LmpServiceBase extends $grpc.Service {
  $core.String get $name => 'elec.Lmp';

  LmpServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.HistoricalLmpRequest, $0.NumericTimeSeries>(
            'GetLmp',
            getLmp_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.HistoricalLmpRequest.fromBuffer(value),
            ($0.NumericTimeSeries value) => value.writeToBuffer()));
  }

  $async.Future<$0.NumericTimeSeries> getLmp_Pre($grpc.ServiceCall call,
      $async.Future<$0.HistoricalLmpRequest> request) async {
    return getLmp(call, await request);
  }

  $async.Future<$0.NumericTimeSeries> getLmp(
      $grpc.ServiceCall call, $0.HistoricalLmpRequest request);
}
