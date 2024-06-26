library client.isoexpress.sevenday_capacity_forecast;

import 'package:date/date.dart';

class DailyForecast {
  DailyForecast({
    required this.dayIndex,
    required this.marketDate,
    required this.csoMw,
    required this.coldWeatherOutagesMw,
    required this.otherGenOutagesMw,
    required this.delistMw,
    required this.totalAvailableGenMw,
    required this.peakImportMw,
    required this.totalAvailableGenImportMw,
    required this.peakLoadMw,
    required this.replacementReserveRequirementMw,
    required this.requiredReserveMw,
    required this.requiredReserveInclReplMw,
    required this.totalLoadPlusRequiredReserveMw,
    required this.drrMw,
    required this.surplusDeficiencyMw,
    required this.isPowerWatch,
    required this.isPowerWarn,
    required this.isColdWeatherWatch,
    required this.isColdWeatherWarn,
    required this.isColdWeatherEvent,
    required this.bosHighTemperature,
    required this.bosDewPoint,
    required this.bdlHighTemperature,
    required this.bdlDewPoint,
  });

  final int dayIndex;
  final Date marketDate;
  final num csoMw;
  final num coldWeatherOutagesMw;
  final num otherGenOutagesMw;
  final num delistMw;
  final num totalAvailableGenMw;
  final num peakImportMw;
  final num totalAvailableGenImportMw;
  final num peakLoadMw;
  final num replacementReserveRequirementMw;
  final num requiredReserveMw;
  final num requiredReserveInclReplMw;
  final num totalLoadPlusRequiredReserveMw;
  final num drrMw;
  final num surplusDeficiencyMw;
  final bool isPowerWatch;
  final bool isPowerWarn;
  final bool isColdWeatherWatch;
  final bool isColdWeatherWarn;
  final bool isColdWeatherEvent;
  // in F
  final num bosHighTemperature;
  // in F
  final num bosDewPoint;
  // in F
  final num bdlHighTemperature;
  // in F
  final num bdlDewPoint;

  static const names = <String>[
    'dayIndex',
    'marketDate',
    'csoMw',
    'coldWeatherOutagesMw',
    'otherGenOutagesMw',
    'delistMw',
    'totalAvailableGenMw',
    'peakImportMw',
    'totalAvailableGenImportMw',
    'peakLoad',
    'replacementReserveRequirementMw',
    'requiredReserveMw',
    'requiredReserveInclReplMw',
    'totalLoadPlusRequiredReserveMw',
    'drrMw',
    'surplusDeficiencyMw',
    'isPowerWatch',
    'isPowerWarn',
    'isColdWeatherWatch',
    'isColdWeatherWarn',
    'isColdWeatherEvent',
    'bosHighTemperature',
    'bosDewPoint',
    'bdlHighTemperature',
    'bdlDewPoint',
  ];

  /// A file contains seven daily forecasts
  static DailyForecast fromJson(Map<String, dynamic> x) {
    final cityWeather = x['Weather']['CityWeather'] as List;
    final bos = cityWeather.firstWhere((e) => e['CityName'] == 'Boston');
    final bosHighTemperature = bos['HighTempF'];
    final bosDewPoint = bos['DewPointF'];

    final bdl = cityWeather.firstWhere((e) => e['CityName'] == 'Hartford');
    final bdlHighTemperature = bdl['HighTempF'];
    final bdlDewPoint = bdl['DewPointF'];

    return DailyForecast(
        dayIndex: int.parse(x['@Day']),
        marketDate: Date.parse(x['MarketDate'].substring(0, 10)),
        csoMw: x["CsoMw"],
        coldWeatherOutagesMw: x['ColdWeatherOutagesMw'],
        otherGenOutagesMw: x['OtherGenOutagesMw'],
        delistMw: x['DelistMw'],
        totalAvailableGenMw: x['TotAvailGenMw'],
        peakImportMw: x['PeakImportMw'],
        totalAvailableGenImportMw: x['TotAvailGenImportMw'],
        peakLoadMw: x['PeakLoadMw'],
        replacementReserveRequirementMw: x['ReplReserveReqMw'],
        requiredReserveMw: x['ReqdReserveMw'],
        requiredReserveInclReplMw: x['ReqdReserveInclReplMw'],
        totalLoadPlusRequiredReserveMw: x['TotLoadPlusReqdReserveMw'],
        drrMw: x['DrrMw'],
        surplusDeficiencyMw: x['SurplusDeficiencyMw'],
        isPowerWatch: x['PowerWatch'] == 'N' ? false : true,
        isPowerWarn: x['PowerWarn'] == 'N' ? false : true,
        isColdWeatherWatch: x['ColdWeatherWatch'] == 'N' ? false : true,
        isColdWeatherWarn: x['ColdWeatherWarn'] == 'N' ? false : true,
        isColdWeatherEvent: x['ColdWeatherEvent'] == 'N' ? false : true,
        bosHighTemperature: bosHighTemperature,
        bosDewPoint: bosDewPoint,
        bdlHighTemperature: bdlHighTemperature,
        bdlDewPoint: bdlDewPoint);
  }

  List<dynamic> toList() {
    return [
      dayIndex,
      marketDate,
      csoMw,
      coldWeatherOutagesMw,
      otherGenOutagesMw,
      delistMw,
      totalAvailableGenMw,
      peakImportMw,
      totalAvailableGenImportMw,
      peakLoadMw,
      replacementReserveRequirementMw,
      requiredReserveMw,
      requiredReserveInclReplMw,
      totalLoadPlusRequiredReserveMw,
      drrMw,
      surplusDeficiencyMw,
      isPowerWatch,
      isPowerWarn,
      isColdWeatherWatch,
      isColdWeatherWarn,
      isColdWeatherEvent,
      bosHighTemperature,
      bosDewPoint,
      bdlHighTemperature,
      bdlDewPoint,
    ];
  }
}
