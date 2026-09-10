import 'dart:io';
import 'dart:math' as math;

import 'package:dama/stat/descriptive/summary.dart';
import 'package:elec_server/utils.dart';
import 'package:table/table_base.dart';

/// Calculates the payoff for the basket option at a given time.
num payoff({
  required num powerPrice,
  required num gasPrice,
  required num rggiPrice,
}) {
  return math.max(powerPrice - 7.0 * (gasPrice + rggiPrice), 0);
}

double _standardNormal(math.Random random) {
  final u1 = 1.0 - random.nextDouble();
  final u2 = random.nextDouble();
  return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
}

List<List<double>> _choleskyDecomposition(List<List<num>> matrix) {
  final n = matrix.length;
  final result = List.generate(n, (_) => List.filled(n, 0.0));

  for (var i = 0; i < n; i++) {
    for (var j = 0; j <= i; j++) {
      var sum = 0.0;
      for (var k = 0; k < j; k++) {
        sum += result[i][k] * result[j][k];
      }
      final value = i == j
          ? math.sqrt((matrix[i][i]).toDouble() - sum)
          : ((matrix[i][j]).toDouble() - sum) / result[j][j];
      if (value.isNaN || value.isInfinite) {
        throw ArgumentError(
            'Correlation matrix must be positive semidefinite.');
      }
      result[i][j] = value;
    }
  }

  return result;
}

({List<num> power, List<num> gas, List<num> rggi}) actualPrices(
    {required ({num power, num gas, num rggi}) initialPrices,
    required int steps}) {
  var simulatedPrices = simulate(
    start: initialPrices,
    growthRate: growthRate,
    volatility: volatilities,
    correlationMatrix: correlationMatrix,
    numSimulations: 1,
    numSteps: steps,
    seed: 9,
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

  final random = seed != null ? math.Random(seed) : math.Random();
  final cholesky = _choleskyDecomposition(correlationMatrix);
  final drifts = [
    growthRate.power.toDouble(),
    growthRate.gas.toDouble(),
    growthRate.rggi.toDouble(),
  ];
  final sigmas = [
    volatility.power.toDouble(),
    volatility.gas.toDouble(),
    volatility.rggi.toDouble(),
  ];

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
      final standardNormals = List<double>.filled(3, 0.0);
      for (var j = 0; j < 3; j++) {
        var sum = 0.0;
        for (var k = 0; k <= j; k++) {
          sum += cholesky[j][k] * _standardNormal(random);
        }
        standardNormals[j] = sum;
      }

      final nextPower = currentPower *
          math.exp((drifts[0] - 0.5 * sigmas[0] * sigmas[0]) +
              sigmas[0] * standardNormals[0]);
      final nextGas = currentGas *
          math.exp((drifts[1] - 0.5 * sigmas[1] * sigmas[1]) +
              sigmas[1] * standardNormals[1]);
      final nextRggi = currentRggi *
          math.exp((drifts[2] - 0.5 * sigmas[2] * sigmas[2]) +
              sigmas[2] * standardNormals[2]);

      currentPower = nextPower;
      currentGas = nextGas;
      currentRggi = nextRggi;

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

final outputDir =
    '/home/adrian/Documents/repos/git/thumbert/rascal/html/docs/projects/basket_option/web';

void makePlotSimulatedPrices(
    ({
      List<List<num>> power,
      List<List<num>> gas,
      List<List<num>> rggi
    }) simulatedPrices) {
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
      'title': {'text': 'Gas/Emission Price, \$/MMBtu'}
    },
    'yaxis': {
      'title': {'text': 'Power Price, \$/MWh'}
    },
    'width': 800,
    'height': 600,
  };

  Plotly.exportJs(traces, layout,
      file: File('$outputDir/assets/simulated_prices.js'));
}

void makePlotPayoff(
    ({
      List<List<num>> power,
      List<List<num>> gas,
      List<List<num>> rggi
    }) simulatedPrices) {
  // final N = simulatedPrices.power.length - 1;
  final p = simulatedPrices.power.map((e) => e.last).toList();
  final g = simulatedPrices.gas.map((e) => e.last).toList();
  final r = simulatedPrices.rggi.map((e) => e.last).toList();

  final spark = List<num>.generate(p.length, (i) => p[i] - 7 * (g[i] + r[i]));
  final payoff = spark.map((e) => e > 0 ? e : 0).toList();

  var traces = [
    {
      'x': spark,
      'y': payoff,
      'type': 'scatter',
      'mode': 'markers',
    },
    // {
    //   'x': simulatedPrices.rggi.map((e) => e.last).toList(),
    //   'y': simulatedPrices.power.map((e) => e.last).toList(),
    //   'type': 'scatter',
    //   'mode': 'markers',
    //   'name': 'Power vs. RGGI',
    // },
  ];
  var layout = {
    'title': {'text': 'Payoff at expiration'},
    'xaxis': {
      'title': {'text': 'Spark spread, \$/MWh'}
    },
    'yaxis': {
      'title': {'text': 'Payoff, \$/MWh'}
    },
    'width': 800,
    'height': 600,
  };

  Plotly.exportJs(traces, layout, file: File('$outputDir/assets/payoff.js'));
}

/// Calculate the option price and the deltas given the prices at expiration.
Map<String, num> optionPricing(
    {required ({
      List<num> power,
      List<num> gas,
      List<num> rggi
    }) simulatedTerminalPrices}) {
  var out = <String, num>{};

  var p = simulatedTerminalPrices.power;
  var g = simulatedTerminalPrices.gas;
  var r = simulatedTerminalPrices.rggi;
  var spark = List<num>.generate(p.length, (i) => p[i] - 7 * (g[i] + r[i]));
  var payoff = spark.map((e) => e > 0 ? e : 0).toList();
  out['optionPrice'] = mean(payoff);

  // power delta
  var pUp = List<num>.generate(p.length, (i) => p[i] + 0.1);
  var pDown = List<num>.generate(p.length, (i) => p[i] - 0.1);
  var sparkUp = List<num>.generate(p.length, (i) => pUp[i] - 7 * (g[i] + r[i]));
  var sparkDown =
      List<num>.generate(p.length, (i) => pDown[i] - 7 * (g[i] + r[i]));
  var payoffUp = sparkUp.map((e) => e > 0 ? e : 0).toList();
  var payoffDown = sparkDown.map((e) => e > 0 ? e : 0).toList();
  out['powerDelta'] = (mean(payoffUp) - mean(payoffDown)) / 0.2;

  // gas delta
  var gUp = List<num>.generate(g.length, (i) => g[i] + 0.1);
  var gDown = List<num>.generate(g.length, (i) => g[i] - 0.1);
  var sparkUpG =
      List<num>.generate(p.length, (i) => p[i] - 7 * (gUp[i] + r[i]));
  var sparkDownG =
      List<num>.generate(p.length, (i) => p[i] - 7 * (gDown[i] + r[i]));
  var payoffUpG = sparkUpG.map((e) => e > 0 ? e : 0).toList();
  var payoffDownG = sparkDownG.map((e) => e > 0 ? e : 0).toList();
  out['gasDelta'] = (mean(payoffUpG) - mean(payoffDownG)) / 0.2;

  // rggi delta
  out['rggiDelta'] = out['gasDelta']!;

  return out;
}

List<Map<String, num>> dynamicHedging(
    List<num> powerPrices, List<num> gasPrices, List<num> rggiPrices) {
  var steps = powerPrices.length;
  var currentPrices =
      (power: powerPrices.first, gas: gasPrices.first, rggi: rggiPrices.first);

  var out = <Map<String, num>>[];
  for (var step = 0; step < steps; step++) {
    // print('Evaluating step: $step');
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
    out.add(
      {
        'day': step,
        ...optionPricing(simulatedTerminalPrices: (
          power: simulatedPrices.power.map((e) => e.last).toList(),
          gas: simulatedPrices.gas.map((e) => e.last).toList(),
          rggi: simulatedPrices.rggi.map((e) => e.last).toList()
        ))
      },
    );
  }
  return out;
}

final growthRate = (power: 0.0005, gas: 0.0005, rggi: 0.000);
final volatilities = (
  power: 0.02,
  gas: 0.03,
  rggi: 0.05,
);
final correlationMatrix = [
  [1.0, 0.8, 0.5],
  [0.8, 1.0, 0.0],
  [0.5, 0.0, 1.0],
];

void main(List<String> args) {
  var start = (power: 45.0, gas: 3.5, rggi: 2.4);
  var prices = actualPrices(
    initialPrices: start,
    steps: 10,
  );
  var tblPrices = Table.from(
      List.generate(
          prices.power.length,
          (i) => {
                'day': i,
                'Power': prices.power[i],
                'Gas': prices.gas[i],
                'RGGI': prices.rggi[i],
                'Spark': prices.power[i] - 7 * (prices.gas[i] + prices.rggi[i]),
              }),
      options: {
        'format': {
          'Power': (v) => (v as num).toStringAsFixed(2),
          'Gas': (v) => (v as num).toStringAsFixed(2),
          'RGGI': (v) => (v as num).toStringAsFixed(2),
          'Spark': (v) => (v as num).toStringAsFixed(2),
        }
      });

  var tblValue = dynamicHedging(prices.power, prices.gas, prices.rggi);
  var res = tblPrices.joinTable(Table.from(tblValue), JoinType.outer)
    ..options = {
      'format': {
        'day': (v) => (v as num).toStringAsFixed(0),
        'Power': (v) => (v as num).toStringAsFixed(2),
        'Gas': (v) => (v as num).toStringAsFixed(2),
        'RGGI': (v) => (v as num).toStringAsFixed(2),
        'Spark': (v) => (v as num).toStringAsFixed(2),
        'optionPrice': (v) => (v as num).toStringAsFixed(2),
        'powerDelta': (v) => (v as num).toStringAsFixed(4),
        'gasDelta': (v) => (v as num).toStringAsFixed(4),
        'rggiDelta': (v) => (v as num).toStringAsFixed(4),
      }
    };
  print(res);
}
