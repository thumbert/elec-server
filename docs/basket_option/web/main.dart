import 'dart:js_interop';
import 'dart:math' as math;

import 'package:web/web.dart' as web;
import 'package:dama/analysis/interpolation/linear_interpolator.dart';
import 'package:dama/distribution/lognormal_distribution.dart';
import 'package:date/date.dart';
import 'package:elec/finance.dart';
import 'package:elec/risk_system.dart';
import 'package:more/collection.dart';
import 'package:dama/distribution/multivariate_gaussian_distribution.dart';
import 'package:dama/linear/matrix.dart';
import 'package:dama/stat/descriptive/summary.dart';
import 'package:plotly_dart/plotly_dart.dart';
import 'package:table/table_base.dart';

/// Calculates the payoff for the basket option at a given time.
num payoff({
  required num powerPrice,
  required num gasPrice,
  required num rggiPrice,
}) {
  return math.max(powerPrice - 7.0 * (gasPrice + rggiPrice), 0);
}

({List<num> power, List<num> gas, List<num> rggi}) actualPrices({
  required ({num power, num gas, num rggi}) initialPrices,
  required int steps,
}) {
  var simulatedPrices = simulate(
    start: initialPrices,
    growthRate: growthRate,
    volatility: volatilities,
    correlationMatrix: correlationMatrix,
    numSimulations: 1,
    numSteps: steps,
    seed: 1,
  );
  return (
    power: simulatedPrices.power.first,
    gas: simulatedPrices.gas.first,
    rggi: simulatedPrices.rggi.first,
  );
}

/// Simulate joint price paths given a correlation matrix. Prices are
/// assumed to follow a log-normal distribution.
///
/// [start] is the initial value for each asset at step 0. The simulation then
/// iterates forward [numSteps] times, where each simulated value becomes the
/// starting value for the next step.
///
/// Returns simulation paths for power, gas, and RGGI. Each path contains the
/// start value followed by [numSteps] forward simulated values.
({List<List<num>> power, List<List<num>> gas, List<List<num>> rggi}) simulate({
  required ({num power, num gas, num rggi}) start,
  required ({num power, num gas, num rggi}) growthRate,
  required ({num power, num gas, num rggi}) volatility,
  required List<List<num>> correlationMatrix,
  required int numSimulations,
  required int numSteps,
  int? seed,
}) {
  if (correlationMatrix.length != 3) {
    throw ArgumentError('correlationMatrix must have 3 rows.');
  }
  if (correlationMatrix.any((row) => row.length != 3)) {
    throw ArgumentError('Each row in correlationMatrix must have 3 entries.');
  }
  if (numSimulations <= 0) {
    throw ArgumentError('numSimulations must be positive.');
  }
  if (numSteps < 0) {
    throw ArgumentError('numSteps must be non-negative.');
  }

  final sigmas = [
    volatility.power.toDouble(),
    volatility.gas.toDouble(),
    volatility.rggi.toDouble(),
  ];
  final logReturnMean = [
    growthRate.power.toDouble() - 0.5 * sigmas[0] * sigmas[0],
    growthRate.gas.toDouble() - 0.5 * sigmas[1] * sigmas[1],
    growthRate.rggi.toDouble() - 0.5 * sigmas[2] * sigmas[2],
  ];
  final distribution = MultivariateGaussianDistribution(
    logReturnMean,
    sigmas,
    Matrix(correlationMatrix.expand((row) => row).toList(), 3, 3, byRow: true),
  );
  if (seed != null) {
    distribution.rand = math.Random(seed);
  }

  final powerPaths = <List<num>>[];
  final gasPaths = <List<num>>[];
  final rggiPaths = <List<num>>[];

  for (var sim = 0; sim < numSimulations; sim++) {
    var currentPower = start.power.toDouble();
    var currentGas = start.gas.toDouble();
    var currentRggi = start.rggi.toDouble();

    final powerPath = <num>[currentPower];
    final gasPath = <num>[currentGas];
    final rggiPath = <num>[currentRggi];

    for (var step = 0; step < numSteps; step++) {
      final logReturns = distribution.sample();

      currentPower *= math.exp(logReturns[0]);
      currentGas *= math.exp(logReturns[1]);
      currentRggi *= math.exp(logReturns[2]);

      powerPath.add(currentPower);
      gasPath.add(currentGas);
      rggiPath.add(currentRggi);
    }

    powerPaths.add(powerPath);
    gasPaths.add(gasPath);
    rggiPaths.add(rggiPath);
  }

  return (power: powerPaths, gas: gasPaths, rggi: rggiPaths);
}

void makePlotSimulatedPrices(
  ({List<List<num>> power, List<List<num>> gas, List<List<num>> rggi})
  simulatedPrices,
) {
  var traces = [
    {
      'x': simulatedPrices.gas.map((e) => e.last).toList(),
      'y': simulatedPrices.power.map((e) => e.last).toList(),
      'type': 'scatter',
      'mode': 'markers',
      'name': 'Power vs. Gas',
    },
    {
      'x': simulatedPrices.rggi.map((e) => e.last).toList(),
      'y': simulatedPrices.power.map((e) => e.last).toList(),
      'type': 'scatter',
      'mode': 'markers',
      'name': 'Power vs. RGGI',
    },
  ];
  var layout = {
    'title': {'text': 'Simulated Prices at expiration'},
    'xaxis': {
      'title': {'text': 'Gas/Emission Price, \$/MMBtu'},
    },
    'yaxis': {
      'title': {'text': 'Power Price, \$/MWh'},
    },
    'width': 800,
    'height': 600,
  };

  var container = web.document.getElementById('hedging')! as web.HTMLElement;
  Plotly(
    container: container,
    divId: 'hedging-plotly',
    traces: traces,
    layout: layout,
  );
}

Plotly? _pricesPlot;

void makePlotPrices(({List<num> power, List<num> gas, List<num> rggi}) prices) {
  final shapes = [
    {
      'type': 'line',
      'x0': 0,
      'y0': prices.power.first,
      'x1': 1,
      'y1': prices.power.first,
      'xref': 'paper',
      'line': {'color': 'gray', 'width': 2, 'dash': 'dash'},
    },
  ];
  if (_pricesPlot != null) {
    _pricesPlot!.update(
      {
        'x': [List.generate(prices.power.length, (i) => i)],
        'y': [prices.power],
      },
      {'shapes': shapes},
      [0],
    );
    return;
  }

  var traces = [
    {
      'x': List.generate(prices.power.length, (i) => i),
      'y': prices.power,
      'type': 'scatter',
      'mode': 'markers+lines',
      'name': 'Power',
    },
    // {
    //   'x': List.generate(prices.gas.length, (i) => i),
    //   'y': prices.gas,
    //   'type': 'scatter',
    //   'mode': 'markers+lines',
    //   'name': 'Gas',
    //   'yaxis': 'y2',
    // },
    // {
    //   'x': List.generate(prices.rggi.length, (i) => i),
    //   'y': prices.rggi,
    //   'type': 'scatter',
    //   'mode': 'markers+lines',
    //   'name': 'RGGI',
    //   'yaxis': 'y2',
    // },
  ];

  var layout = {
    // 'title': {'text': 'Actual Prices'},
    'xaxis': {
      'title': {'text': 'Time step'},
    },
    'yaxis': {
      'title': {'text': 'Power Price, \$/MWh'},
    },
    // 'yaxis2': {
    //   'title': {'text': 'Slippage, \$/MMBtu'},
    //   'overlaying': 'y',
    //   'side': 'right',
    // },
    'width': 800,
    'height': 600,
    'grid': {'rows': 2, 'columns': 1},
    'shapes': shapes,
  };

  var container =
      web.document.getElementById('actual-prices')! as web.HTMLElement;
  _pricesPlot = Plotly(
    container: container,
    divId: 'actual-prices-plotly',
    traces: traces,
    layout: layout,
  );
}

void makePlotPayoff(
  ({List<List<num>> power, List<List<num>> gas, List<List<num>> rggi})
  simulatedPrices,
) {
  final p = simulatedPrices.power.map((e) => e.last).toList();
  final g = simulatedPrices.gas.map((e) => e.last).toList();
  final r = simulatedPrices.rggi.map((e) => e.last).toList();

  final spark = List<num>.generate(p.length, (i) => p[i] - 7 * (g[i] + r[i]));
  final payoff = spark.map((e) => e > 0 ? e : 0).toList();

  var traces = [
    {'x': spark, 'y': payoff, 'type': 'scatter', 'mode': 'markers'},
  ];
  var layout = {
    'title': {'text': 'Payoff at expiration'},
    'xaxis': {
      'title': {'text': 'Spark spread, \$/MWh'},
    },
    'yaxis': {
      'title': {'text': 'Payoff, \$/MWh'},
    },
    'width': 800,
    'height': 600,
  };

  var container = web.document.getElementById('payoff')! as web.HTMLElement;
  Plotly(
    container: container,
    divId: 'payoff-plotly',
    traces: traces,
    layout: layout,
  );
}

/// Calculate the option price and the deltas given the prices at expiration.
Map<String, num> optionPricing({
  required ({List<num> power, List<num> gas, List<num> rggi})
  simulatedTerminalPrices,
}) {
  var out = <String, num>{};

  var p = simulatedTerminalPrices.power;
  var g = simulatedTerminalPrices.gas;
  var r = simulatedTerminalPrices.rggi;
  var spark = List<num>.generate(p.length, (i) => p[i] - 7 * (g[i] + r[i]));
  var payoff = spark.map((e) => e > 0 ? e : 0).toList();
  out['optionValue'] = mean(payoff);

  // power delta
  var pUp = List<num>.generate(p.length, (i) => p[i] + 0.1);
  var pDown = List<num>.generate(p.length, (i) => p[i] - 0.1);
  var sparkUp = List<num>.generate(p.length, (i) => pUp[i] - 7 * (g[i] + r[i]));
  var sparkDown = List<num>.generate(
    p.length,
    (i) => pDown[i] - 7 * (g[i] + r[i]),
  );
  var payoffUp = sparkUp.map((e) => e > 0 ? e : 0).toList();
  var payoffDown = sparkDown.map((e) => e > 0 ? e : 0).toList();
  out['powerDelta'] = (mean(payoffUp) - mean(payoffDown)) / 0.2;

  // gas delta
  var gUp = List<num>.generate(g.length, (i) => g[i] + 0.1);
  var gDown = List<num>.generate(g.length, (i) => g[i] - 0.1);
  var sparkUpG = List<num>.generate(
    p.length,
    (i) => p[i] - 7 * (gUp[i] + r[i]),
  );
  var sparkDownG = List<num>.generate(
    p.length,
    (i) => p[i] - 7 * (gDown[i] + r[i]),
  );
  var payoffUpG = sparkUpG.map((e) => e > 0 ? e : 0).toList();
  var payoffDownG = sparkDownG.map((e) => e > 0 ? e : 0).toList();
  out['gasDelta'] = (mean(payoffUpG) - mean(payoffDownG)) / 0.2;

  // rggi delta
  out['rggiDelta'] = out['gasDelta']!;

  return out;
}

List<Map<String, num>> dynamicHedging(
  List<num> powerPrices,
  List<num> gasPrices,
  List<num> rggiPrices,
) {
  var steps = powerPrices.length;
  var currentPrices = (
    power: powerPrices.first,
    gas: gasPrices.first,
    rggi: rggiPrices.first,
  );

  var out = <Map<String, num>>[];
  for (var step = 0; step < steps; step++) {
    var numSimulations = 100;
    var simulatedPrices = simulate(
      start: currentPrices,
      growthRate: growthRate,
      volatility: volatilities,
      correlationMatrix: correlationMatrix,
      numSimulations: numSimulations,
      numSteps: steps - step,
    );
    if (step == 0) {
      makePlotSimulatedPrices(simulatedPrices);
      makePlotPayoff(simulatedPrices);
    }
    currentPrices = (
      power: powerPrices[step],
      gas: gasPrices[step],
      rggi: rggiPrices[step],
    );
    out.add({
      'day': step,
      ...optionPricing(
        simulatedTerminalPrices: (
          power: simulatedPrices.power.map((e) => e.last).toList(),
          gas: simulatedPrices.gas.map((e) => e.last).toList(),
          rggi: simulatedPrices.rggi.map((e) => e.last).toList(),
        ),
      ),
    });
  }

  /// calculate hedged value
  /// At step t=1,

  for (var i = 0; i < out.length; i++) {
    var row = out[i];
    if (i == 0) {
      row['hedgedValue'] = row['optionValue']!;
      row['slippage'] = 0;
    } else {
      var prev = out[i - 1];
      row['hedgedValue'] =
          prev['optionValue']! +
          prev['powerDelta']! * (powerPrices[i] - powerPrices[i - 1]) -
          prev['gasDelta']! * (gasPrices[i] - gasPrices[i - 1]) -
          prev['rggiDelta']! * (rggiPrices[i] - rggiPrices[i - 1]);
      row['slippage'] = row['hedgedValue']! - row['optionValue']!;
    }
  }

  return out;
}

final growthRate = (power: 0.000, gas: 0.000, rggi: 0.000);
final volatilities = (power: 0.01, gas: 0.03, rggi: 0.05);
final correlationMatrix = [
  [1.0, 0.8, 0.5],
  [0.8, 1.0, 0.0],
  [0.5, 0.0, 1.0],
];

void makePlotSlippage(
  List<num> prices,
  List<num> optionPrice,
  List<num> deltaApprox,
  List<num> deltaGammaApprox,
) {
  var traces = [
    {
      'x': List.generate(prices.length, (i) => i),
      'y': prices,
      'type': 'scatter',
      'mode': 'markers+lines',
      'name': 'Power',
    },
  ];

  var layout = {
    // 'title': {'text': 'Actual Prices'},
    'xaxis': {
      'title': {'text': 'Time step'},
    },
    'yaxis': {
      'title': {'text': 'Power Price, \$/MWh'},
    },
    // 'yaxis2': {
    //   'title': {'text': 'Slippage, \$/MMBtu'},
    //   'overlaying': 'y',
    //   'side': 'right',
    // },
    'width': 800,
    'height': 600,
    'grid': {'rows': 2, 'columns': 1},
    'shapes': [
      {
        'type': 'line',
        'x0': 0,
        'y0': prices.first,
        'x1': 1,
        'y1': prices.first,
        'xref': 'paper',
        'line': {'color': 'gray', 'width': 2, 'dash': 'dash'},
      },
    ],
  };

  var container =
      web.document.getElementById('actual-prices')! as web.HTMLElement;
  Plotly(
    container: container,
    divId: 'actual-prices-plotly',
    traces: traces,
    layout: layout,
  );
}

void dynamicHedgingOnePowerOption() {
  final steps = 50;
  final expiration = Date.utc(2024, 12, 31);
  final strike = 41;
  final volatility = 0.5;

  var prices = simulatePricesGbm(
    initialPrice: strike,
    volatility: volatility,
    riskFreeRate: 0,
    numSteps: steps,
  );

  var res = <Map<String, dynamic>>[];
  for (var i = 0; i < steps; i++) {
    var option = BlackScholes(
      strike: strike,
      volatility: volatility,
      type: CallPut.call,
      expirationDate: expiration,
      asOfDate: expiration.subtract(steps - i),
      underlyingPrice: prices[i],
      riskFreeRate: 0,
    );
    res.add({
      'step': i,
      'asOfDate': expiration.subtract(steps - i).toString(),
      'powerPrice': prices[i],
      'optionValue': option.value(),
      'delta': option.delta(),
      'gamma': option.gamma(),
      'theta': option.theta(),
    });
  }

  // calculate the hedged value
  for (var i = 0; i < res.length; i++) {
    var row = res[i];
    if (i == 0) {
      row['hedgedValue (delta)'] = row['optionValue']!;
      row['slippage (delta)'] = 0;
      row['hedgedValue (delta + gamma)'] = row['optionValue']!;
      row['slippage (delta + gamma)'] = 0;
    } else {
      var prev = res[i - 1];
      var dP = prices[i] - prices[i - 1];
      row['hedgedValue (delta)'] =
          prev['optionValue']! + prev['delta']! * dP + prev['theta']!;
      row['slippage (delta)'] =
          row['hedgedValue (delta)']! - row['optionValue']!;
      row['hedgedValue (delta + gamma)'] =
          prev['optionValue']! +
          prev['delta']! * dP +
          0.5 * prev['gamma']! * dP * dP +
          prev['theta']!;
      row['slippage (delta + gamma)'] =
          row['hedgedValue (delta + gamma)']! - row['optionValue']!;
    }
  }
  var tbl = Table.from(
    res,
    options: {
      'format': {
        'day': (v) => (v as num).toStringAsFixed(0),
        'powerPrice': (v) => (v as num).toStringAsFixed(2),
        'optionValue': (v) => (v as num).toStringAsFixed(2),
        'delta': (v) => (v as num).toStringAsFixed(4),
        'gamma': (v) => (v as num).toStringAsFixed(4),
        'theta': (v) => (v as num).toStringAsFixed(4),
        'hedgedValue (delta)': (v) => (v as num).toStringAsFixed(2),
        'slippage (delta)': (v) => (v as num).toStringAsFixed(2),
        'hedgedValue (delta + gamma)': (v) => (v as num).toStringAsFixed(2),
        'slippage (delta + gamma)': (v) => (v as num).toStringAsFixed(2),
      },
    },
  );

  var container2 =
      web.document.getElementById('summary-table')! as web.HTMLElement;
  container2.innerHTML = tbl.toHtml().toJS;
}

// /// Creates a plot for the Black-Scholes option pricing model and
// /// the two approximations.
// ///
// void makePlotBlackScholes() {
//   /// make a plot with the true option value and approximations
//   var option0 = BlackScholes(
//     strike: strike,
//     volatility: volatility,
//     type: CallPut.call,
//     expirationDate: expiration,
//     asOfDate: expiration.subtract(steps),
//     underlyingPrice: prices.first, // initial price
//     riskFreeRate: 0,
//   );
//   final value0 = option0.value();
//   final delta0 = option0.delta();
//   final gamma0 = option0.gamma();
//   final theta0 = option0.theta();
//   final px = DoubleRange(38, 44, 0.1).toList();
//   final li = LinearInterpolator.fromSlope(
//     slope: delta0,
//     point: (prices.first, value0),
//   );
//   num quadraticApprox(e) =>
//       value0 +
//       delta0 * (e - prices.first) +
//       0.5 * gamma0 * (e - prices.first) * (e - prices.first);
//   num fullValue(e) => BlackScholes(
//         strike: strike,
//         volatility: volatility,
//         type: CallPut.call,
//         expirationDate: expiration,
//         asOfDate: expiration.subtract(steps),
//         underlyingPrice: e,
//         riskFreeRate: 0,
//       ).value();
//   var traces = [
//     {
//       'x': px,
//       'y': px.map((e) => fullValue(e)),
//       'type': 'scatter',
//       'mode': 'lines',
//       'name': 'BlackScholes',
//     },
//     {
//       'x': px,
//       'y': px.map((e) => li.valueAt(e)),
//       'type': 'scatter',
//       'mode': 'lines',
//       'name': 'Delta Approx.',
//     },
//     {
//       'x': px,
//       'y': px.map((e) => quadraticApprox(e)),
//       'type': 'scatter',
//       'mode': 'lines',
//       'name': 'Delta + Gamma Approx.',
//     },
//   ];
//   var layout = {
//     'width': 800,
//     'height': 600,
//     'title': {'text': 'Actual Prices'},
//     'xaxis': {
//       'title': {'text': 'Price'},
//     },
//     'yaxis': {
//       'title': {'text': 'Value, \$/MWh'},
//     },
//     'shapes': [
//       {
//         'type': 'line',
//         'x0': prices.first,
//         'y0': 0,
//         'x1': prices.first,
//         'y1': 1,
//         'yref': 'paper',
//         'line': {'color': 'gray', 'width': 2, 'dash': 'dash'},
//       },
//     ],
//   };
//   var container =
//       web.document.getElementById('hedge-performance')! as web.HTMLElement;
//   Plotly(
//     container: container,
//     divId: 'hedge-performance-plotly',
//     traces: traces,
//     layout: layout,
//   );
// }

void main(List<String> args) {
  dynamicHedgingOnePowerOption();

  final inputPower =
      web.document.getElementById('input-power')! as web.HTMLInputElement;
  final inputGas =
      web.document.getElementById('input-gas')! as web.HTMLInputElement;
  final inputRggi =
      web.document.getElementById('input-rggi')! as web.HTMLInputElement;

  ({num power, num gas, num rggi})? readStart() {
    final power = num.tryParse(inputPower.value);
    final gas = num.tryParse(inputGas.value);
    final rggi = num.tryParse(inputRggi.value);
    if (power == null || gas == null || rggi == null) return null;
    if (power <= 0 || gas <= 0 || rggi <= 0) return null;
    return (power: power, gas: gas, rggi: rggi);
  }

  void redraw() {
    final start = readStart();
    if (start == null) return;
    makePlotPrices(actualPrices(initialPrices: start, steps: 50));
  }

  for (final input in [inputPower, inputGas, inputRggi]) {
    input.addEventListener(
      'input',
      ((web.Event _) {
        final v = num.tryParse(input.value);
        input.classList.toggle('is-invalid', v == null || v <= 0);
        redraw();
      }).toJS,
    );
  }

  var start = readStart()!;
  var prices = actualPrices(initialPrices: start, steps: 50);
  makePlotPrices(prices);

  
  var tblPrices = Table.from(
    List.generate(
      prices.power.length,
      (i) => {
        'day': i,
        'Power': prices.power[i],
        'Gas': prices.gas[i],
        'RGGI': prices.rggi[i],
        'Spark': prices.power[i] - 7 * (prices.gas[i] + prices.rggi[i]),
      },
    ),
    options: {
      'format': {
        'Power': (v) => (v as num).toStringAsFixed(2),
        'Gas': (v) => (v as num).toStringAsFixed(2),
        'RGGI': (v) => (v as num).toStringAsFixed(2),
        'Spark': (v) => (v as num).toStringAsFixed(2),
      },
    },
  );

  // var tblValue = dynamicHedging(prices.power, prices.gas, prices.rggi);
  // var res = tblPrices.joinTable(Table.from(tblValue), JoinType.outer)
  //   ..options = {
  //     'format': {
  //       'day': (v) => (v as num).toStringAsFixed(0),
  //       'Power': (v) => (v as num).toStringAsFixed(2),
  //       'Gas': (v) => (v as num).toStringAsFixed(2),
  //       'RGGI': (v) => (v as num).toStringAsFixed(2),
  //       'Spark': (v) => (v as num).toStringAsFixed(2),
  //       'optionValue': (v) => (v as num).toStringAsFixed(2),
  //       'powerDelta': (v) => (v as num).toStringAsFixed(4),
  //       'gasDelta': (v) => (v as num).toStringAsFixed(4),
  //       'rggiDelta': (v) => (v as num).toStringAsFixed(4),
  //       'hedgedValue': (v) => (v as num).toStringAsFixed(2),
  //       'slippage': (v) => (v as num).toStringAsFixed(2),
  //     },
  //   };
  // print(res);

  // var container =
  //     web.document.getElementById('summary-table')! as web.HTMLElement;
  // container.innerHTML = res.toHtml().toJS;
}
