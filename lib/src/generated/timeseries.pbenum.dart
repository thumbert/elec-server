///
//  Generated code. Do not modify.
//  source: timeseries.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' show int, dynamic, String, List, Map;
import 'package:protobuf/protobuf.dart' as $pb;

class EnergyMarket_Value extends $pb.ProtobufEnum {
  static const EnergyMarket_Value DA = const EnergyMarket_Value._(0, 'DA');
  static const EnergyMarket_Value RT = const EnergyMarket_Value._(1, 'RT');

  static const List<EnergyMarket_Value> values = const <EnergyMarket_Value> [
    DA,
    RT,
  ];

  static final Map<int, EnergyMarket_Value> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EnergyMarket_Value valueOf(int value) => _byValue[value];
  static void $checkItem(EnergyMarket_Value v) {
    if (v is! EnergyMarket_Value) $pb.checkItemFailed(v, 'EnergyMarket_Value');
  }

  const EnergyMarket_Value._(int v, String n) : super(v, n);
}

class LmpComponent_Component extends $pb.ProtobufEnum {
  static const LmpComponent_Component LMP = const LmpComponent_Component._(0, 'LMP');
  static const LmpComponent_Component CONGESTION = const LmpComponent_Component._(1, 'CONGESTION');
  static const LmpComponent_Component MARGINAL_LOSS = const LmpComponent_Component._(2, 'MARGINAL_LOSS');
  static const LmpComponent_Component ENERGY = const LmpComponent_Component._(3, 'ENERGY');

  static const List<LmpComponent_Component> values = const <LmpComponent_Component> [
    LMP,
    CONGESTION,
    MARGINAL_LOSS,
    ENERGY,
  ];

  static final Map<int, LmpComponent_Component> _byValue = $pb.ProtobufEnum.initByValue(values);
  static LmpComponent_Component valueOf(int value) => _byValue[value];
  static void $checkItem(LmpComponent_Component v) {
    if (v is! LmpComponent_Component) $pb.checkItemFailed(v, 'LmpComponent_Component');
  }

  const LmpComponent_Component._(int v, String n) : super(v, n);
}

class TimeInterval_Interval extends $pb.ProtobufEnum {
  static const TimeInterval_Interval IRREGULAR = const TimeInterval_Interval._(0, 'IRREGULAR');
  static const TimeInterval_Interval HOURLY = const TimeInterval_Interval._(1, 'HOURLY');
  static const TimeInterval_Interval DAILY = const TimeInterval_Interval._(2, 'DAILY');
  static const TimeInterval_Interval MONTHLY = const TimeInterval_Interval._(3, 'MONTHLY');
  static const TimeInterval_Interval MIN15 = const TimeInterval_Interval._(4, 'MIN15');

  static const List<TimeInterval_Interval> values = const <TimeInterval_Interval> [
    IRREGULAR,
    HOURLY,
    DAILY,
    MONTHLY,
    MIN15,
  ];

  static final Map<int, TimeInterval_Interval> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TimeInterval_Interval valueOf(int value) => _byValue[value];
  static void $checkItem(TimeInterval_Interval v) {
    if (v is! TimeInterval_Interval) $pb.checkItemFailed(v, 'TimeInterval_Interval');
  }

  const TimeInterval_Interval._(int v, String n) : super(v, n);
}

