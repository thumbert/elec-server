// ///
// //  Generated code. Do not modify.
// //  source: timeseries.proto
// //
//
// // ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type
//
// import 'dart:core' as $core;
//
// import 'package:fixnum/fixnum.dart';
// import 'package:protobuf/protobuf.dart' as $pb;
//
// import 'timeseries.pbenum.dart';
//
// export 'timeseries.pbenum.dart';
//
// class HistoricalLmpRequest extends $pb.GeneratedMessage {
//   static final $pb.BuilderInfo _i = $pb.BuilderInfo('HistoricalLmpRequest', package: const $pb.PackageName('elec'), createEmptyInstance: create)
//     ..a<EnergyMarket>(1, 'market', $pb.PbFieldType.OM, defaultOrMaker: EnergyMarket.getDefault, subBuilder: EnergyMarket.create)
//     ..a<LmpComponent>(2, 'component', $pb.PbFieldType.OM, defaultOrMaker: LmpComponent.getDefault, subBuilder: LmpComponent.create)
//     ..a<$core.int>(4, 'ptid', $pb.PbFieldType.O3)
//     ..aInt64(5, 'start')
//     ..aInt64(6, 'end')
//     ..hasRequiredFields = false
//   ;
//
//   HistoricalLmpRequest._() : super();
//   factory HistoricalLmpRequest() => create();
//   factory HistoricalLmpRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
//   factory HistoricalLmpRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
//   HistoricalLmpRequest clone() => HistoricalLmpRequest()..mergeFromMessage(this);
//   HistoricalLmpRequest copyWith(void Function(HistoricalLmpRequest) updates) => super.copyWith((message) => updates(message as HistoricalLmpRequest)) as HistoricalLmpRequest;
//   $pb.BuilderInfo get info_ => _i;
//   @$core.pragma('dart2js:noInline')
//   static HistoricalLmpRequest create() => HistoricalLmpRequest._();
//   HistoricalLmpRequest createEmptyInstance() => create();
//   static $pb.PbList<HistoricalLmpRequest> createRepeated() => $pb.PbList<HistoricalLmpRequest>();
//   static HistoricalLmpRequest getDefault() => _defaultInstance ??= create()..freeze();
//   static HistoricalLmpRequest? _defaultInstance;
//
//   EnergyMarket get market => $_getN(0);
//   set market(EnergyMarket v) { setField(1, v); }
//   $core.bool hasMarket() => $_has(0);
//   void clearMarket() => clearField(1);
//
//   LmpComponent get component => $_getN(1);
//   set component(LmpComponent v) { setField(2, v); }
//   $core.bool hasComponent() => $_has(1);
//   void clearComponent() => clearField(2);
//
//   $core.int get ptid => $_get(2, 0);
//   set ptid($core.int v) { $_setSignedInt32(2, v); }
//   $core.bool hasPtid() => $_has(2);
//   void clearPtid() => clearField(4);
//
//   Int64 get start => $_getI64(3);
//   set start(Int64 v) { $_setInt64(3, v); }
//   $core.bool hasStart() => $_has(3);
//   void clearStart() => clearField(5);
//
//   Int64 get end => $_getI64(4);
//   set end(Int64 v) { $_setInt64(4, v); }
//   $core.bool hasEnd() => $_has(4);
//   void clearEnd() => clearField(6);
// }
//
// class EnergyMarket extends $pb.GeneratedMessage {
//   static final $pb.BuilderInfo _i = $pb.BuilderInfo('EnergyMarket', package: const $pb.PackageName('elec'), createEmptyInstance: create)
//     ..a<EnergyMarket>(1, 'market', $pb.PbFieldType.OM, defaultOrMaker: EnergyMarket.getDefault, subBuilder: EnergyMarket.create)
//     ..hasRequiredFields = false
//   ;
//
//   EnergyMarket._() : super();
//   factory EnergyMarket() => create();
//   factory EnergyMarket.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
//   factory EnergyMarket.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
//   EnergyMarket clone() => EnergyMarket()..mergeFromMessage(this);
//   EnergyMarket copyWith(void Function(EnergyMarket) updates) => super.copyWith((message) => updates(message as EnergyMarket)) as EnergyMarket;
//   $pb.BuilderInfo get info_ => _i;
//   @$core.pragma('dart2js:noInline')
//   static EnergyMarket create() => EnergyMarket._();
//   EnergyMarket createEmptyInstance() => create();
//   static $pb.PbList<EnergyMarket> createRepeated() => $pb.PbList<EnergyMarket>();
//   static EnergyMarket getDefault() => _defaultInstance ??= create()..freeze();
//   static EnergyMarket? _defaultInstance;
//
//   EnergyMarket get market => $_getN(0);
//   set market(EnergyMarket v) { setField(1, v); }
//   $core.bool hasMarket() => $_has(0);
//   void clearMarket() => clearField(1);
// }
//
// class LmpComponent extends $pb.GeneratedMessage {
//   static final $pb.BuilderInfo _i = $pb.BuilderInfo('LmpComponent', package: const $pb.PackageName('elec'), createEmptyInstance: create)
//     ..e<LmpComponent_Component>(1, 'component', $pb.PbFieldType.OE, defaultOrMaker: LmpComponent_Component.LMP, valueOf: LmpComponent_Component.valueOf, enumValues: LmpComponent_Component.values)
//     ..hasRequiredFields = false
//   ;
//
//   LmpComponent._() : super();
//   factory LmpComponent() => create();
//   factory LmpComponent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
//   factory LmpComponent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
//   LmpComponent clone() => LmpComponent()..mergeFromMessage(this);
//   LmpComponent copyWith(void Function(LmpComponent) updates) => super.copyWith((message) => updates(message as LmpComponent)) as LmpComponent;
//   $pb.BuilderInfo get info_ => _i;
//   @$core.pragma('dart2js:noInline')
//   static LmpComponent create() => LmpComponent._();
//   LmpComponent createEmptyInstance() => create();
//   static $pb.PbList<LmpComponent> createRepeated() => $pb.PbList<LmpComponent>();
//   static LmpComponent getDefault() => _defaultInstance ??= create()..freeze();
//   static LmpComponent? _defaultInstance;
//
//   LmpComponent_Component get component => $_getN(0);
//   set component(LmpComponent_Component v) { setField(1, v); }
//   $core.bool hasComponent() => $_has(0);
//   void clearComponent() => clearField(1);
// }
//
// class IntervalType extends $pb.GeneratedMessage {
//   static final $pb.BuilderInfo _i = $pb.BuilderInfo('IntervalType', package: const $pb.PackageName('elec'), createEmptyInstance: create)
//     ..e<IntervalType_Type>(1, 'type', $pb.PbFieldType.OE, defaultOrMaker: IntervalType_Type.IRREGULAR, valueOf: IntervalType_Type.valueOf, enumValues: IntervalType_Type.values)
//     ..hasRequiredFields = false
//   ;
//
//   IntervalType._() : super();
//   factory IntervalType() => create();
//   factory IntervalType.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
//   factory IntervalType.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
//   IntervalType clone() => IntervalType()..mergeFromMessage(this);
//   IntervalType copyWith(void Function(IntervalType) updates) => super.copyWith((message) => updates(message as IntervalType)) as IntervalType;
//   $pb.BuilderInfo get info_ => _i;
//   @$core.pragma('dart2js:noInline')
//   static IntervalType create() => IntervalType._();
//   IntervalType createEmptyInstance() => create();
//   static $pb.PbList<IntervalType> createRepeated() => $pb.PbList<IntervalType>();
//   static IntervalType getDefault() => _defaultInstance ??= create()..freeze();
//   static IntervalType? _defaultInstance;
//
//   IntervalType_Type get type => $_getN(0);
//   set type(IntervalType_Type v) { setField(1, v); }
//   $core.bool hasType() => $_has(0);
//   void clearType() => clearField(1);
// }
//
// class NumericTimeSeries_Observation extends $pb.GeneratedMessage {
//   static final $pb.BuilderInfo _i = $pb.BuilderInfo('NumericTimeSeries.Observation', package: const $pb.PackageName('elec'), createEmptyInstance: create)
//     ..aInt64(1, 'start')
//     ..a<$core.double>(2, 'value', $pb.PbFieldType.OD)
//     ..hasRequiredFields = false
//   ;
//
//   NumericTimeSeries_Observation._() : super();
//   factory NumericTimeSeries_Observation() => create();
//   factory NumericTimeSeries_Observation.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
//   factory NumericTimeSeries_Observation.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
//   NumericTimeSeries_Observation clone() => NumericTimeSeries_Observation()..mergeFromMessage(this);
//   NumericTimeSeries_Observation copyWith(void Function(NumericTimeSeries_Observation) updates) => super.copyWith((message) => updates(message as NumericTimeSeries_Observation)) as NumericTimeSeries_Observation;
//   $pb.BuilderInfo get info_ => _i;
//   @$core.pragma('dart2js:noInline')
//   static NumericTimeSeries_Observation create() => NumericTimeSeries_Observation._();
//   NumericTimeSeries_Observation createEmptyInstance() => create();
//   static $pb.PbList<NumericTimeSeries_Observation> createRepeated() => $pb.PbList<NumericTimeSeries_Observation>();
//   static NumericTimeSeries_Observation getDefault() => _defaultInstance ??= create()..freeze();
//   static NumericTimeSeries_Observation? _defaultInstance;
//
//   Int64 get start => $_getI64(0);
//   set start(Int64 v) { $_setInt64(0, v); }
//   $core.bool hasStart() => $_has(0);
//   void clearStart() => clearField(1);
//
//   $core.double get value => $_getN(1);
//   set value($core.double v) { $_setDouble(1, v); }
//   $core.bool hasValue() => $_has(1);
//   void clearValue() => clearField(2);
// }
//
// class NumericTimeSeries extends $pb.GeneratedMessage {
//   static final $pb.BuilderInfo _i = $pb.BuilderInfo('NumericTimeSeries', package: const $pb.PackageName('elec'), createEmptyInstance: create)
//     ..aOS(1, 'name')
//     ..aOS(2, 'tzLocation', protoName: 'tzLocation')
//     ..a<IntervalType>(3, 'timeInterval', $pb.PbFieldType.OM, protoName: 'timeInterval', defaultOrMaker: IntervalType.getDefault, subBuilder: IntervalType.create)
//     ..pc<NumericTimeSeries_Observation>(4, 'observation', $pb.PbFieldType.PM, subBuilder: NumericTimeSeries_Observation.create)
//     ..hasRequiredFields = false
//   ;
//
//   NumericTimeSeries._() : super();
//   factory NumericTimeSeries() => create();
//   factory NumericTimeSeries.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
//   factory NumericTimeSeries.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
//   NumericTimeSeries clone() => NumericTimeSeries()..mergeFromMessage(this);
//   NumericTimeSeries copyWith(void Function(NumericTimeSeries) updates) => super.copyWith((message) => updates(message as NumericTimeSeries)) as NumericTimeSeries;
//   $pb.BuilderInfo get info_ => _i;
//   @$core.pragma('dart2js:noInline')
//   static NumericTimeSeries create() => NumericTimeSeries._();
//   NumericTimeSeries createEmptyInstance() => create();
//   static $pb.PbList<NumericTimeSeries> createRepeated() => $pb.PbList<NumericTimeSeries>();
//   static NumericTimeSeries getDefault() => _defaultInstance ??= create()..freeze();
//   static NumericTimeSeries? _defaultInstance;
//
//   $core.String get name => $_getS(0, '');
//   set name($core.String v) { $_setString(0, v); }
//   $core.bool hasName() => $_has(0);
//   void clearName() => clearField(1);
//
//   $core.String get tzLocation => $_getS(1, '');
//   set tzLocation($core.String v) { $_setString(1, v); }
//   $core.bool hasTzLocation() => $_has(1);
//   void clearTzLocation() => clearField(2);
//
//   IntervalType get timeInterval => $_getN(2);
//   set timeInterval(IntervalType v) { setField(3, v); }
//   $core.bool hasTimeInterval() => $_has(2);
//   void clearTimeInterval() => clearField(3);
//
//   $core.List<NumericTimeSeries_Observation> get observation => $_getList(3);
// }
//
