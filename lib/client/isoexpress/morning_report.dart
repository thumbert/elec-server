library client.isoexpress.morning_report;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:timezone/timezone.dart';

class MorningReport {
  MorningReport({
    required this.reportType,
    required this.marketDate,
    required this.creationDateTime,
    required this.peakLoadYesterdayHour,
    required this.peakLoadYesterdayMw,
    required this.csoMw,
    required this.capAdditionsMw,
    required this.genOutagesReductionMw,
    required this.uncommittedAvailGenMw,
    required this.drrCapacityMw,
    required this.uncommittedAvailableDrrGenMw,
    required this.netCapacityDeliveryMw,
    //
    required this.totalAvailableCapacityMw,
    required this.peakLoadTodayHour,
    required this.peakLoadTodayMw,
    required this.totalOperatingReserveRequirementsMw,
    required this.capacityRequiredMw,
    required this.surplusDeficiencyMw,
    required this.replacementReserveRequirementMw,
    required this.excessCommitMw,
    required this.largestFirstContingencyMw,
    required this.amsPeakLoadExpMw,
    required this.isNyisoSarAvailable,
    //
    required this.tenMinReserveReqMw,
    required this.tenMinReserveEstMw,
    required this.thirtyMinReserveReqMw,
    required this.thirtyMinReserveEstMw,
    required this.expectedActOp4Mw,
    required this.addlCapAvailOp4ActMw,
    //
    required this.importLimitInHighgateMw,
    required this.exportLimitOutHighgateMw,
    required this.scheduledHighgateMw,
    required this.tieFlowHigateMw,
    //
    required this.importLimitInNbMw,
    required this.exportLimitOutNbMw,
    required this.scheduledNbMw,
    required this.tieFlowNbMw,
    //
    required this.importLimitInNyisoAcMw,
    required this.exportLimitOutNyisoAcMw,
    required this.scheduledNyisoAcMw,
    required this.tieFlowNyisoAcMw,
    //
    required this.importLimitInNyisoCscMw,
    required this.exportLimitOutNyisoCscMw,
    required this.scheduledNyisoCscMw,
    required this.tieFlowNyisoCscMw,
    //
    required this.importLimitInNyisoNncMw,
    required this.exportLimitOutNyisoNncMw,
    required this.scheduledNyisoNncMw,
    required this.tieFlowNyisoNncMw,
    //
    required this.importLimitInPhase2Mw,
    required this.exportLimitOutPhase2Mw,
    required this.scheduledPhase2Mw,
    required this.tieFlowPhase2Mw,
    //
    required this.highTemperatureBoston,
    required this.weatherConditionsBoston,
    required this.windDirSpeedBoston,
    required this.highTemperatureHartford,
    required this.weatherConditionsHartford,
    required this.windDirSpeedHartford,
    //
    required this.nonCommUnitsCapMw,
    required this.unitsCommMinOrrCount,
    required this.unitsCommMinOrrMw,
    //
    required this.geoMagDistIsoAction,
    required this.geoMagDistOtherCentralAction,
    required this.geoMagDistIntensity,
    required this.geoMagDistObsActivity,
  });

  final String reportType;
  final Date marketDate;
  final TZDateTime creationDateTime;
  final Hour peakLoadYesterdayHour;
  final num peakLoadYesterdayMw;
  final num csoMw;
  final num capAdditionsMw;
  final num genOutagesReductionMw;
  final num uncommittedAvailGenMw;
  final num drrCapacityMw;
  final num uncommittedAvailableDrrGenMw;
  final num netCapacityDeliveryMw;
  //
  final num totalAvailableCapacityMw;
  final Hour peakLoadTodayHour;
  final num peakLoadTodayMw;
  final num totalOperatingReserveRequirementsMw;
  final num capacityRequiredMw;
  final num surplusDeficiencyMw;
  final num replacementReserveRequirementMw;
  final num excessCommitMw;
  final num largestFirstContingencyMw;
  final num amsPeakLoadExpMw;
  final bool isNyisoSarAvailable;
  // reserves
  final num tenMinReserveReqMw;
  final num tenMinReserveEstMw;
  final num thirtyMinReserveReqMw;
  final num thirtyMinReserveEstMw;
  final num expectedActOp4Mw;
  final num addlCapAvailOp4ActMw;

  /// tie info
  final num importLimitInHighgateMw;
  final num exportLimitOutHighgateMw;
  final num scheduledHighgateMw;
  final num tieFlowHigateMw;
  //
  final num importLimitInNbMw;
  final num exportLimitOutNbMw;
  final num scheduledNbMw;
  final num tieFlowNbMw;
  //
  final num importLimitInNyisoAcMw;
  final num exportLimitOutNyisoAcMw;
  final num scheduledNyisoAcMw;
  final num tieFlowNyisoAcMw;
  //
  final num importLimitInNyisoCscMw;
  final num exportLimitOutNyisoCscMw;
  final num scheduledNyisoCscMw;
  final num tieFlowNyisoCscMw;
  //
  final num importLimitInNyisoNncMw;
  final num exportLimitOutNyisoNncMw;
  final num scheduledNyisoNncMw;
  final num tieFlowNyisoNncMw;
  //
  final num importLimitInPhase2Mw;
  final num exportLimitOutPhase2Mw;
  final num scheduledPhase2Mw;
  final num tieFlowPhase2Mw;
  // weather
  final num highTemperatureBoston;
  final String weatherConditionsBoston;
  final String windDirSpeedBoston;
  final num highTemperatureHartford;
  final String weatherConditionsHartford;
  final String windDirSpeedHartford;
  //
  final num nonCommUnitsCapMw;
  final int unitsCommMinOrrCount;
  final num unitsCommMinOrrMw;
  //
  final String geoMagDistIsoAction;
  final String geoMagDistOtherCentralAction;
  final String? geoMagDistIntensity;
  final String? geoMagDistObsActivity;

  static const colnames = <String>[
    'reportType',
    'marketDate',
    'creationDateTime',
    'peakLoadYesterdayHour',
    'peakLoadYesterdayMw',
    'csoMw',
    'capAdditionsMw',
    'genOutagesReductionMw',
    'uncommittedAvailGenMw',
    'drrCapacityMw',
    'uncommittedAvailableDrrGenMw',
    'netCapacityDeliveryMw',
    'totalAvailableCapacityMw',
    'peakLoadTodayHour',
    'peakLoadTodayMw',
    'totalOperatingReserveRequirementsMw',
    'capacityRequiredMw',
    'surplusDeficiencyMw',
    'replacementReserveRequirementMw',
    'excessCommitMw',
    'largestFirstContingencyMw',
    'amsPeakLoadExpMw',
    'isNyisoSarAvailable',
    'tenMinReserveReqMw',
    'tenMinReserveEstMw',
    'thirtyMinReserveReqMw',
    'thirtyMinReserveEstMw',
    'expectedActOp4Mw',
    'addlCapAvailOp4ActMw',
    'importLimitInHighgateMw',
    'exportLimitOutHighgateMw',
    'scheduledHighgateMw',
    'tieFlowHigateMw',
    'importLimitInNbMw',
    'exportLimitOutNbMw',
    'scheduledNbMw',
    'tieFlowNbMw',
    'importLimitInNyisoAcMw',
    'exportLimitOutNyisoAcMw',
    'scheduledNyisoAcMw',
    'tieFlowNyisoAcMw',
    'importLimitInNyisoCscMw',
    'exportLimitOutNyisoCscMw',
    'scheduledNyisoCscMw',
    'tieFlowNyisoCscMw',
    'importLimitInNyisoNncMw',
    'exportLimitOutNyisoNncMw',
    'scheduledNyisoNncMw',
    'tieFlowNyisoNncMw',
    'importLimitInPhase2Mw',
    'exportLimitOutPhase2Mw',
    'scheduledPhase2Mw',
    'tieFlowPhase2Mw',
    'highTemperatureBoston',
    'weatherConditionsBoston',
    'windDirSpeedBoston',
    'highTemperatureHartford',
    'weatherConditionsHartford',
    'windDirSpeedHartford',
    'nonCommUnitsCapMw',
    'unitsCommMinOrrCount',
    'unitsCommMinOrrMw',
    'geoMagDistIsoAction',
    'geoMagDistOtherCentralAction',
    'geoMagDistIntensity',
    'geoMagDistObsActivity',
  ];

  /// A file contains two versions of the report the Final and Preliminary
  /// To process a json file, you need to run this function twice.
  static MorningReport fromJson(Map<String, dynamic> x) {
    var tieFlow = x['TieDelivery'] as List;
    var interchange = x['InterchangeDetail'] as List;
    var weather = x['CityForecastDetail'] as List;

    return MorningReport(
      reportType: x['ReportType'],
      marketDate: Date.parse(x['BeginDate'].substring(0, 10)),
      creationDateTime:
          TZDateTime.parse(IsoNewEngland.location, x['CreationDate']),
      peakLoadYesterdayHour: Hour.beginning(
          TZDateTime.parse(IsoNewEngland.location, x['PeakLoadYesterdayHour'])),
      peakLoadYesterdayMw: x['PeakLoadYesterdayMw'],
      csoMw: x["CsoMw"],
      capAdditionsMw: x['CapAdditionsMw'],
      genOutagesReductionMw: x['GenOutagesReductionMW'],
      uncommittedAvailGenMw: x['UncommittedAvailGenMw'],
      drrCapacityMw: x['DRRCapacityMw'],
      uncommittedAvailableDrrGenMw: x['UncommitedAvailDRRMw'],
      netCapacityDeliveryMw: x['NetCapDeliveryMw'],
      //
      tieFlowHigateMw:
          tieFlow.firstWhere((e) => e['TieName'] == 'Highgate')['TieFlowMw'],
      tieFlowNbMw: tieFlow.firstWhere((e) => e['TieName'] == 'NB')['TieFlowMw'],
      tieFlowNyisoAcMw:
          tieFlow.firstWhere((e) => e['TieName'] == 'NYISO AC')['TieFlowMw'],
      tieFlowNyisoCscMw:
          tieFlow.firstWhere((e) => e['TieName'] == 'NYISO CSC')['TieFlowMw'],
      tieFlowNyisoNncMw:
          tieFlow.firstWhere((e) => e['TieName'] == 'NYISO NNC')['TieFlowMw'],
      tieFlowPhase2Mw:
          tieFlow.firstWhere((e) => e['TieName'] == 'Phase 2')['TieFlowMw'],
      //
      totalAvailableCapacityMw: x['TotAvailCapMw'],
      peakLoadTodayHour: Hour.beginning(
          TZDateTime.parse(IsoNewEngland.location, x['PeakLoadTodayHour'])),
      peakLoadTodayMw: x['PeakLoadTodayMw'],
      totalOperatingReserveRequirementsMw: x['TotalOperReserveReqMw'],
      capacityRequiredMw: x['CapRequiredMw'],
      surplusDeficiencyMw: x['SurplusDeficiencyMw'],
      replacementReserveRequirementMw: x['ReplReserveRequiredMw'],
      excessCommitMw: x['ExcessCommitMw'],
      largestFirstContingencyMw: x['LargestFirstContMw'],
      amsPeakLoadExpMw: x['AmsPeakLoadExpMw'],
      isNyisoSarAvailable: x['NyIsoSarAvail'] == 'Y' ? true : false,
      //
      tenMinReserveReqMw: x['TenMinReserveReqMw'],
      tenMinReserveEstMw: x['TenMinReserveEstMw'],
      thirtyMinReserveReqMw: x['ThirtyMinReserveReqMw'],
      thirtyMinReserveEstMw: x['ThirtyMinReserveEstMw'],

      expectedActOp4Mw: x['ExpActOp4Mw'],
      addlCapAvailOp4ActMw: x['AddlCapAvailOp4ActMw'],
      //
      importLimitInHighgateMw: interchange
          .firstWhere((e) => e['TieName'] == 'Highgate')['ImportLimitInMw'],
      exportLimitOutHighgateMw: interchange
          .firstWhere((e) => e['TieName'] == 'Highgate')['ExportLimitOutMw'],
      scheduledHighgateMw: interchange
          .firstWhere((e) => e['TieName'] == 'Highgate')['ScheduledMw'],
      //
      importLimitInNbMw: interchange
          .firstWhere((e) => e['TieName'] == 'NB')['ImportLimitInMw'],
      exportLimitOutNbMw: interchange
          .firstWhere((e) => e['TieName'] == 'NB')['ExportLimitOutMw'],
      scheduledNbMw:
          interchange.firstWhere((e) => e['TieName'] == 'NB')['ScheduledMw'],
      //
      importLimitInNyisoAcMw: interchange
          .firstWhere((e) => e['TieName'] == 'NYISO AC')['ImportLimitInMw'],
      exportLimitOutNyisoAcMw: interchange
          .firstWhere((e) => e['TieName'] == 'NYISO AC')['ExportLimitOutMw'],
      scheduledNyisoAcMw: interchange
          .firstWhere((e) => e['TieName'] == 'NYISO AC')['ScheduledMw'],
      //
      importLimitInNyisoCscMw: interchange
          .firstWhere((e) => e['TieName'] == 'NYISO CSC')['ImportLimitInMw'],
      exportLimitOutNyisoCscMw: interchange
          .firstWhere((e) => e['TieName'] == 'NYISO CSC')['ExportLimitOutMw'],
      scheduledNyisoCscMw: interchange
          .firstWhere((e) => e['TieName'] == 'NYISO CSC')['ScheduledMw'],
      //
      importLimitInNyisoNncMw: interchange
          .firstWhere((e) => e['TieName'] == 'NYISO NNC')['ImportLimitInMw'],
      exportLimitOutNyisoNncMw: interchange
          .firstWhere((e) => e['TieName'] == 'NYISO NNC')['ExportLimitOutMw'],
      scheduledNyisoNncMw: interchange
          .firstWhere((e) => e['TieName'] == 'NYISO NNC')['ScheduledMw'],
      //
      importLimitInPhase2Mw: interchange
          .firstWhere((e) => e['TieName'] == 'Phase 2')['ImportLimitInMw'],
      exportLimitOutPhase2Mw: interchange
          .firstWhere((e) => e['TieName'] == 'Phase 2')['ExportLimitOutMw'],
      scheduledPhase2Mw: interchange
          .firstWhere((e) => e['TieName'] == 'Phase 2')['ScheduledMw'],
      //
      highTemperatureBoston: weather
          .firstWhere((e) => e['CityName'] == 'Boston')['HighTemperature'],
      weatherConditionsBoston: weather
          .firstWhere((e) => e['CityName'] == 'Boston')['WeatherConditions'].toString(),
      windDirSpeedBoston:
          weather.firstWhere((e) => e['CityName'] == 'Boston')['WindDirSpeed'],
      highTemperatureHartford: weather
          .firstWhere((e) => e['CityName'] == 'Hartford')['HighTemperature'],
      weatherConditionsHartford: weather
          .firstWhere((e) => e['CityName'] == 'Hartford')['WeatherConditions'].toString(),
      windDirSpeedHartford: weather
          .firstWhere((e) => e['CityName'] == 'Hartford')['WindDirSpeed'],
      //
      nonCommUnitsCapMw: x['NonCommUnitsCapMw'],
      unitsCommMinOrrCount: x['UnitCommMinOrrCount'],
      unitsCommMinOrrMw: x['UnitCommMinOrrMw'],
      geoMagDistIsoAction: x['GeoMagDistIsoAction'] ?? '',
      geoMagDistOtherCentralAction: x['GeoMagDistOthCntrAction'] ?? '',
      geoMagDistIntensity: x['GeoMagDistIntensity'],
      geoMagDistObsActivity: x['GeoMagDistObsActivity'] is int
          ? x['GeoMagDistObsActivity'].toString()
          : x['GeoMagDistObsActivity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportType': reportType,
      'marketDate': marketDate.toString(),
      'creationDateTime': creationDateTime.toIso8601String(),
      'peakLoadYesterdayHour': peakLoadTodayHour.start.toIso8601String(),
      'peakLoadYesterdayMw': peakLoadTodayMw,
      'csoMw': csoMw,
      'capAdditionsMw': capAdditionsMw,
      'genOutagesReductionMw': genOutagesReductionMw,
      'uncommittedAvailGenMw': uncommittedAvailGenMw,
      'drrCapacityMw': drrCapacityMw,
      'uncommittedAvailableDrrGenMw': uncommittedAvailableDrrGenMw,
      'netCapacityDeliveryMw': netCapacityDeliveryMw,
      //
      'totalAvailableCapacityMw': totalAvailableCapacityMw,
      'peakLoadTodayHour': peakLoadTodayHour.start.toIso8601String(),
      'peakLoadTodayMw': peakLoadTodayMw,
      'totalOperatingReserveRequirementsMw':
          totalOperatingReserveRequirementsMw,
      'capacityRequiredMw': capacityRequiredMw,
      'surplusDeficiencyMw': surplusDeficiencyMw,
      'replacementReserveRequirementMw': replacementReserveRequirementMw,
      'excessCommitMw': excessCommitMw,
      'largestFirstContingencyMw': largestFirstContingencyMw,
      'amsPeakLoadExpMw': amsPeakLoadExpMw,
      'isNyisoSarAvailable': isNyisoSarAvailable,
      //
      'tenMinReserveReqMw': tenMinReserveReqMw,
      'tenMinReserveEstMw': tenMinReserveEstMw,
      'thirtyMinReserveReqMw': thirtyMinReserveReqMw,
      'thirtyMinReserveEstMw': thirtyMinReserveEstMw,
      'expectedActOp4Mw': expectedActOp4Mw,
      'addlCapAvailOp4ActMw': addlCapAvailOp4ActMw,
      //
      'importLimitInHighgateMw': importLimitInHighgateMw,
      'exportLimitOutHighgateMw': exportLimitOutHighgateMw,
      'scheduledHighgateMw': scheduledHighgateMw,
      'tieFlowHigateMw': tieFlowHigateMw,
      //
      'importLimitInNbMw': importLimitInNbMw,
      'exportLimitOutNbMw': exportLimitOutNbMw,
      'scheduledNbMw': scheduledNbMw,
      'tieFlowNbMw': tieFlowNbMw,
      //
      'importLimitInNyisoAcMw': importLimitInNyisoAcMw,
      'exportLimitOutNyisoAcMw': exportLimitOutNyisoAcMw,
      'scheduledNyisoAcMw': scheduledNyisoAcMw,
      'tieFlowNyisoAcMw': tieFlowNyisoAcMw,
      //
      'importLimitInNyisoCscMw': importLimitInNyisoCscMw,
      'exportLimitOutNyisoCscMw': exportLimitOutNyisoCscMw,
      'scheduledNyisoCscMw': scheduledNyisoCscMw,
      'tieFlowNyisoCscMw': tieFlowNyisoCscMw,
      //
      'importLimitInNyisoNncMw': importLimitInNyisoNncMw,
      'exportLimitOutNyisoNncMw': exportLimitOutNyisoNncMw,
      'scheduledNyisoNncMw': scheduledNyisoNncMw,
      'tieFlowNyisoNncMw': tieFlowNyisoNncMw,
      //
      'importLimitInPhase2Mw': importLimitInPhase2Mw,
      'exportLimitOutPhase2Mw': exportLimitOutPhase2Mw,
      'scheduledPhase2Mw': scheduledPhase2Mw,
      'tieFlowPhase2Mw': tieFlowPhase2Mw,
      //
      'highTemperatureBoston': highTemperatureBoston,
      'weatherConditionsBoston': weatherConditionsBoston,
      'windDirSpeedBoston': windDirSpeedBoston,
      'highTemperatureHartford': highTemperatureHartford,
      'weatherConditionsHartford': weatherConditionsHartford,
      'windDirSpeedHartford': windDirSpeedHartford,
      //
      'nonCommUnitsCapMw': nonCommUnitsCapMw,
      'unitsCommMinOrrCount': unitsCommMinOrrCount,
      'unitsCommMinOrrMw': unitsCommMinOrrMw,
      //
      'geoMagDistIsoAction': geoMagDistIsoAction,
      'geoMagDistOtherCentralAction': geoMagDistOtherCentralAction,
      'geoMagDistIntensity': geoMagDistIntensity,
      'geoMagDistObsActivity': geoMagDistObsActivity,
    };
  }
}
