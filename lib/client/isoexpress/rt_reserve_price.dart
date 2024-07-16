library client.isoexpress.rt_reserve_price;

import 'package:elec/elec.dart';
import 'package:timezone/timezone.dart';

class RtReservePrice {
  RtReservePrice({
    required this.fiveMinIntervalBeginning,
    required this.reserveZoneId,
    required this.reserveZoneName,
    required this.tenMinSpinRequirementMw,
    required this.total10MinRequirementMw,
    required this.total30MinRequirementMw,
    required this.tmsrDesignatedMw,
    required this.tmnsrDesignatedMw,
    required this.tmorDesignatedMw,
    required this.tmsrClearingPrice,
    required this.tmnsrClearingPrice,
    required this.tmorClearingPrice,
  });

  final TZDateTime fiveMinIntervalBeginning;
  final int reserveZoneId;
  final String reserveZoneName;
  final num tenMinSpinRequirementMw;
  final num total10MinRequirementMw;
  final num total30MinRequirementMw;
  final num tmsrDesignatedMw;
  final num tmnsrDesignatedMw;
  final num tmorDesignatedMw;
  final num tmsrClearingPrice;
  final num tmnsrClearingPrice;
  final num tmorClearingPrice;

  // static const columns = <String, String>{
  //   '5MinIntervalBeginning': '',
  //   'reserveZoneId': '',
  //   'reserveZoneName': '',
  //   'tenMinSpinRequirementMw': '',
  //   'total10MinRequirementMw': '',
  //   'total30MinRequirementMw': '',
  //   'tmsrDesignatedMw': '',
  //   'tmnsrDesignatedMw': '',
  //   'tmorDesignatedMw': '',
  //   'tmsrClearingPrice': '',
  //   'tmnsrClearingPrice': '',
  //   'tmorClearingPrice': '',
  // };

  /// A file contains a list of entries in this form:
  /// ```
  ///   {
  ///      "BeginDate": "2021-01-01T00:00:00.000-05:00",
  ///      "ReserveZoneId": 7000,
  ///      "ReserveZoneName": "ROS",
  ///      "TenMinSpinRequirement": 483,
  ///      "Total10MinRequirement": 1555,
  ///      "Total30MinRequirement": 2360,
  ///      "TmsrDesignatedMw": 187.5,
  ///      "TmnsrDesignatedMw": 2461.8,
  ///      "TmorDesignatedMw": 659.2,
  ///      "TmsrClearingPrice": 6.8,
  ///      "TmnsrClearingPrice": 0,
  ///      "TmorClearingPrice": 0
  ///    },
  /// ```
  static RtReservePrice fromJson(Map<String, dynamic> x) {
    return RtReservePrice(
        fiveMinIntervalBeginning:
            TZDateTime.parse(IsoNewEngland.location, x['BeginDate']),
        reserveZoneId: x['ReserveZoneId'],
        reserveZoneName: x['ReserveZoneName'],
        tenMinSpinRequirementMw: x['tenMinSpinRequirementMw'],
        total10MinRequirementMw: x['total10MinRequirementMw'],
        total30MinRequirementMw: x['total30MinRequirementMw'],
        tmsrDesignatedMw: x['tmsrDesignatedMw'],
        tmnsrDesignatedMw: x['tmnsrDesignatedMw'],
        tmorDesignatedMw: x['tmorDesignatedMw'],
        tmsrClearingPrice: x['tmsrClearingPrice'],
        tmnsrClearingPrice: x['tmnsrClearingPrice'],
        tmorClearingPrice: x['tmorClearingPrice']);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      '5MinIntervalBeginning': fiveMinIntervalBeginning.toIso8601String(),
      'reserveZoneId': reserveZoneId,
      'reserveZoneName': reserveZoneName,
      'tenMinSpinRequirementMw': tenMinSpinRequirementMw,
      'total10MinRequirementMw': total10MinRequirementMw,
      'total30MinRequirementMw': total30MinRequirementMw,
      'tmsrDesignatedMw': tmsrDesignatedMw,
      'tmnsrDesignatedMw': tmnsrDesignatedMw,
      'tmorDesignatedMw': tmorDesignatedMw,
      'tmsrClearingPrice': tmsrClearingPrice,
      'tmnsrClearingPrice': tmnsrClearingPrice,
      'tmorClearingPrice': tmorClearingPrice,
    };
  }
}
