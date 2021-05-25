///
//  Generated code. Do not modify.
//  source: timeseries.proto
//

// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

const HistoricalLmpRequest$json = const {
  '1': 'HistoricalLmpRequest',
  '2': const [
    const {'1': 'market', '3': 1, '4': 1, '5': 11, '6': '.elec.EnergyMarket', '10': 'market'},
    const {'1': 'component', '3': 2, '4': 1, '5': 11, '6': '.elec.LmpComponent', '10': 'component'},
    const {'1': 'ptid', '3': 4, '4': 1, '5': 5, '10': 'ptid'},
    const {'1': 'start', '3': 5, '4': 1, '5': 3, '10': 'start'},
    const {'1': 'end', '3': 6, '4': 1, '5': 3, '10': 'end'},
  ],
};

const EnergyMarket$json = const {
  '1': 'EnergyMarket',
  '2': const [
    const {'1': 'market', '3': 1, '4': 1, '5': 11, '6': '.elec.EnergyMarket', '10': 'market'},
  ],
  '4': const [EnergyMarket_Value$json],
};

const EnergyMarket_Value$json = const {
  '1': 'Value',
  '2': const [
    const {'1': 'DA', '2': 0},
    const {'1': 'RT', '2': 1},
  ],
};

const LmpComponent$json = const {
  '1': 'LmpComponent',
  '2': const [
    const {'1': 'component', '3': 1, '4': 1, '5': 14, '6': '.elec.LmpComponent.Component', '10': 'component'},
  ],
  '4': const [LmpComponent_Component$json],
};

const LmpComponent_Component$json = const {
  '1': 'Component',
  '2': const [
    const {'1': 'LMP', '2': 0},
    const {'1': 'CONGESTION', '2': 1},
    const {'1': 'MARGINAL_LOSS', '2': 2},
    const {'1': 'ENERGY', '2': 3},
  ],
};

const IntervalType$json = const {
  '1': 'IntervalType',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.elec.IntervalType.Type', '10': 'type'},
  ],
  '4': const [IntervalType_Type$json],
};

const IntervalType_Type$json = const {
  '1': 'Type',
  '2': const [
    const {'1': 'IRREGULAR', '2': 0},
    const {'1': 'HOURLY', '2': 1},
    const {'1': 'DAILY', '2': 2},
    const {'1': 'MONTHLY', '2': 3},
    const {'1': 'MIN15', '2': 4},
  ],
};

const NumericTimeSeries$json = const {
  '1': 'NumericTimeSeries',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'tzLocation', '3': 2, '4': 1, '5': 9, '10': 'tzLocation'},
    const {'1': 'timeInterval', '3': 3, '4': 1, '5': 11, '6': '.elec.IntervalType', '10': 'timeInterval'},
    const {'1': 'observation', '3': 4, '4': 3, '5': 11, '6': '.elec.NumericTimeSeries.Observation', '10': 'observation'},
  ],
  '3': const [NumericTimeSeries_Observation$json],
};

const NumericTimeSeries_Observation$json = const {
  '1': 'Observation',
  '2': const [
    const {'1': 'start', '3': 1, '4': 1, '5': 3, '10': 'start'},
    const {'1': 'value', '3': 2, '4': 1, '5': 1, '10': 'value'},
  ],
};

