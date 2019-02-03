///
//  Generated code. Do not modify.
//  source: timeseries.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, Map, override;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'timeseries.pbenum.dart';

export 'timeseries.pbenum.dart';

class HistoricalLmpRequest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('HistoricalLmpRequest', package: const $pb.PackageName('elec'))
    ..a<EnergyMarket>(1, 'market', $pb.PbFieldType.OM, EnergyMarket.getDefault, EnergyMarket.create)
    ..a<LmpComponent>(2, 'component', $pb.PbFieldType.OM, LmpComponent.getDefault, LmpComponent.create)
    ..a<int>(4, 'ptid', $pb.PbFieldType.O3)
    ..aInt64(5, 'start')
    ..aInt64(6, 'end')
    ..hasRequiredFields = false
  ;

  HistoricalLmpRequest() : super();
  HistoricalLmpRequest.fromBuffer(List<int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  HistoricalLmpRequest.fromJson(String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  HistoricalLmpRequest clone() => new HistoricalLmpRequest()..mergeFromMessage(this);
  HistoricalLmpRequest copyWith(void Function(HistoricalLmpRequest) updates) => super.copyWith((message) => updates(message as HistoricalLmpRequest));
  $pb.BuilderInfo get info_ => _i;
  static HistoricalLmpRequest create() => new HistoricalLmpRequest();
  HistoricalLmpRequest createEmptyInstance() => create();
  static $pb.PbList<HistoricalLmpRequest> createRepeated() => new $pb.PbList<HistoricalLmpRequest>();
  static HistoricalLmpRequest getDefault() => _defaultInstance ??= create()..freeze();
  static HistoricalLmpRequest _defaultInstance;
  static void $checkItem(HistoricalLmpRequest v) {
    if (v is! HistoricalLmpRequest) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  EnergyMarket get market => $_getN(0);
  set market(EnergyMarket v) { setField(1, v); }
  bool hasMarket() => $_has(0);
  void clearMarket() => clearField(1);

  LmpComponent get component => $_getN(1);
  set component(LmpComponent v) { setField(2, v); }
  bool hasComponent() => $_has(1);
  void clearComponent() => clearField(2);

  int get ptid => $_get(2, 0);
  set ptid(int v) { $_setSignedInt32(2, v); }
  bool hasPtid() => $_has(2);
  void clearPtid() => clearField(4);

  Int64 get start => $_getI64(3);
  set start(Int64 v) { $_setInt64(3, v); }
  bool hasStart() => $_has(3);
  void clearStart() => clearField(5);

  Int64 get end => $_getI64(4);
  set end(Int64 v) { $_setInt64(4, v); }
  bool hasEnd() => $_has(4);
  void clearEnd() => clearField(6);
}

class EnergyMarket extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('EnergyMarket', package: const $pb.PackageName('elec'))
    ..a<EnergyMarket>(1, 'market', $pb.PbFieldType.OM, EnergyMarket.getDefault, EnergyMarket.create)
    ..hasRequiredFields = false
  ;

  EnergyMarket() : super();
  EnergyMarket.fromBuffer(List<int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  EnergyMarket.fromJson(String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  EnergyMarket clone() => new EnergyMarket()..mergeFromMessage(this);
  EnergyMarket copyWith(void Function(EnergyMarket) updates) => super.copyWith((message) => updates(message as EnergyMarket));
  $pb.BuilderInfo get info_ => _i;
  static EnergyMarket create() => new EnergyMarket();
  EnergyMarket createEmptyInstance() => create();
  static $pb.PbList<EnergyMarket> createRepeated() => new $pb.PbList<EnergyMarket>();
  static EnergyMarket getDefault() => _defaultInstance ??= create()..freeze();
  static EnergyMarket _defaultInstance;
  static void $checkItem(EnergyMarket v) {
    if (v is! EnergyMarket) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  EnergyMarket get market => $_getN(0);
  set market(EnergyMarket v) { setField(1, v); }
  bool hasMarket() => $_has(0);
  void clearMarket() => clearField(1);
}

class LmpComponent extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('LmpComponent', package: const $pb.PackageName('elec'))
    ..e<LmpComponent_Component>(1, 'component', $pb.PbFieldType.OE, LmpComponent_Component.LMP, LmpComponent_Component.valueOf, LmpComponent_Component.values)
    ..hasRequiredFields = false
  ;

  LmpComponent() : super();
  LmpComponent.fromBuffer(List<int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  LmpComponent.fromJson(String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  LmpComponent clone() => new LmpComponent()..mergeFromMessage(this);
  LmpComponent copyWith(void Function(LmpComponent) updates) => super.copyWith((message) => updates(message as LmpComponent));
  $pb.BuilderInfo get info_ => _i;
  static LmpComponent create() => new LmpComponent();
  LmpComponent createEmptyInstance() => create();
  static $pb.PbList<LmpComponent> createRepeated() => new $pb.PbList<LmpComponent>();
  static LmpComponent getDefault() => _defaultInstance ??= create()..freeze();
  static LmpComponent _defaultInstance;
  static void $checkItem(LmpComponent v) {
    if (v is! LmpComponent) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  LmpComponent_Component get component => $_getN(0);
  set component(LmpComponent_Component v) { setField(1, v); }
  bool hasComponent() => $_has(0);
  void clearComponent() => clearField(1);
}

class TimeInterval extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('TimeInterval', package: const $pb.PackageName('elec'))
    ..e<TimeInterval_Interval>(1, 'interval', $pb.PbFieldType.OE, TimeInterval_Interval.IRREGULAR, TimeInterval_Interval.valueOf, TimeInterval_Interval.values)
    ..hasRequiredFields = false
  ;

  TimeInterval() : super();
  TimeInterval.fromBuffer(List<int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  TimeInterval.fromJson(String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  TimeInterval clone() => new TimeInterval()..mergeFromMessage(this);
  TimeInterval copyWith(void Function(TimeInterval) updates) => super.copyWith((message) => updates(message as TimeInterval));
  $pb.BuilderInfo get info_ => _i;
  static TimeInterval create() => new TimeInterval();
  TimeInterval createEmptyInstance() => create();
  static $pb.PbList<TimeInterval> createRepeated() => new $pb.PbList<TimeInterval>();
  static TimeInterval getDefault() => _defaultInstance ??= create()..freeze();
  static TimeInterval _defaultInstance;
  static void $checkItem(TimeInterval v) {
    if (v is! TimeInterval) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  TimeInterval_Interval get interval => $_getN(0);
  set interval(TimeInterval_Interval v) { setField(1, v); }
  bool hasInterval() => $_has(0);
  void clearInterval() => clearField(1);
}

class NumericTimeSeries_Observation extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('NumericTimeSeries.Observation', package: const $pb.PackageName('elec'))
    ..aInt64(1, 'start')
    ..a<double>(2, 'value', $pb.PbFieldType.OD)
    ..hasRequiredFields = false
  ;

  NumericTimeSeries_Observation() : super();
  NumericTimeSeries_Observation.fromBuffer(List<int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  NumericTimeSeries_Observation.fromJson(String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  NumericTimeSeries_Observation clone() => new NumericTimeSeries_Observation()..mergeFromMessage(this);
  NumericTimeSeries_Observation copyWith(void Function(NumericTimeSeries_Observation) updates) => super.copyWith((message) => updates(message as NumericTimeSeries_Observation));
  $pb.BuilderInfo get info_ => _i;
  static NumericTimeSeries_Observation create() => new NumericTimeSeries_Observation();
  NumericTimeSeries_Observation createEmptyInstance() => create();
  static $pb.PbList<NumericTimeSeries_Observation> createRepeated() => new $pb.PbList<NumericTimeSeries_Observation>();
  static NumericTimeSeries_Observation getDefault() => _defaultInstance ??= create()..freeze();
  static NumericTimeSeries_Observation _defaultInstance;
  static void $checkItem(NumericTimeSeries_Observation v) {
    if (v is! NumericTimeSeries_Observation) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  Int64 get start => $_getI64(0);
  set start(Int64 v) { $_setInt64(0, v); }
  bool hasStart() => $_has(0);
  void clearStart() => clearField(1);

  double get value => $_getN(1);
  set value(double v) { $_setDouble(1, v); }
  bool hasValue() => $_has(1);
  void clearValue() => clearField(2);
}

class NumericTimeSeries extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('NumericTimeSeries', package: const $pb.PackageName('elec'))
    ..aOS(1, 'name')
    ..aOS(2, 'tzLocation')
    ..a<TimeInterval>(3, 'timeInterval', $pb.PbFieldType.OM, TimeInterval.getDefault, TimeInterval.create)
    ..pp<NumericTimeSeries_Observation>(4, 'observation', $pb.PbFieldType.PM, NumericTimeSeries_Observation.$checkItem, NumericTimeSeries_Observation.create)
    ..hasRequiredFields = false
  ;

  NumericTimeSeries() : super();
  NumericTimeSeries.fromBuffer(List<int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromBuffer(i, r);
  NumericTimeSeries.fromJson(String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) : super.fromJson(i, r);
  NumericTimeSeries clone() => new NumericTimeSeries()..mergeFromMessage(this);
  NumericTimeSeries copyWith(void Function(NumericTimeSeries) updates) => super.copyWith((message) => updates(message as NumericTimeSeries));
  $pb.BuilderInfo get info_ => _i;
  static NumericTimeSeries create() => new NumericTimeSeries();
  NumericTimeSeries createEmptyInstance() => create();
  static $pb.PbList<NumericTimeSeries> createRepeated() => new $pb.PbList<NumericTimeSeries>();
  static NumericTimeSeries getDefault() => _defaultInstance ??= create()..freeze();
  static NumericTimeSeries _defaultInstance;
  static void $checkItem(NumericTimeSeries v) {
    if (v is! NumericTimeSeries) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get name => $_getS(0, '');
  set name(String v) { $_setString(0, v); }
  bool hasName() => $_has(0);
  void clearName() => clearField(1);

  String get tzLocation => $_getS(1, '');
  set tzLocation(String v) { $_setString(1, v); }
  bool hasTzLocation() => $_has(1);
  void clearTzLocation() => clearField(2);

  TimeInterval get timeInterval => $_getN(2);
  set timeInterval(TimeInterval v) { setField(3, v); }
  bool hasTimeInterval() => $_has(2);
  void clearTimeInterval() => clearField(3);

  List<NumericTimeSeries_Observation> get observation => $_getList(3);
}

