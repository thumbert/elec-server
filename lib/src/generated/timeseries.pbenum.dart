///
//  Generated code. Do not modify.
//  source: timeseries.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

// ignore_for_file: UNDEFINED_SHOWN_NAME,UNUSED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class EnergyMarket_Value extends $pb.ProtobufEnum {
  static const EnergyMarket_Value DA = EnergyMarket_Value._(0, 'DA');
  static const EnergyMarket_Value RT = EnergyMarket_Value._(1, 'RT');

  static const $core.List<EnergyMarket_Value> values = <EnergyMarket_Value> [
    DA,
    RT,
  ];

  static final $core.Map<$core.int, EnergyMarket_Value> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EnergyMarket_Value valueOf($core.int value) => _byValue[value];

  const EnergyMarket_Value._($core.int v, $core.String n) : super(v, n);
}

class LmpComponent_Component extends $pb.ProtobufEnum {
  static const LmpComponent_Component LMP = LmpComponent_Component._(0, 'LMP');
  static const LmpComponent_Component CONGESTION = LmpComponent_Component._(1, 'CONGESTION');
  static const LmpComponent_Component MARGINAL_LOSS = LmpComponent_Component._(2, 'MARGINAL_LOSS');
  static const LmpComponent_Component ENERGY = LmpComponent_Component._(3, 'ENERGY');

  static const $core.List<LmpComponent_Component> values = <LmpComponent_Component> [
    LMP,
    CONGESTION,
    MARGINAL_LOSS,
    ENERGY,
  ];

  static final $core.Map<$core.int, LmpComponent_Component> _byValue = $pb.ProtobufEnum.initByValue(values);
  static LmpComponent_Component valueOf($core.int value) => _byValue[value];

  const LmpComponent_Component._($core.int v, $core.String n) : super(v, n);
}

class IntervalType_Type extends $pb.ProtobufEnum {
  static const IntervalType_Type IRREGULAR = IntervalType_Type._(0, 'IRREGULAR');
  static const IntervalType_Type HOURLY = IntervalType_Type._(1, 'HOURLY');
  static const IntervalType_Type DAILY = IntervalType_Type._(2, 'DAILY');
  static const IntervalType_Type MONTHLY = IntervalType_Type._(3, 'MONTHLY');
  static const IntervalType_Type MIN15 = IntervalType_Type._(4, 'MIN15');

  static const $core.List<IntervalType_Type> values = <IntervalType_Type> [
    IRREGULAR,
    HOURLY,
    DAILY,
    MONTHLY,
    MIN15,
  ];

  static final $core.Map<$core.int, IntervalType_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static IntervalType_Type valueOf($core.int value) => _byValue[value];

  const IntervalType_Type._($core.int v, $core.String n) : super(v, n);
}

