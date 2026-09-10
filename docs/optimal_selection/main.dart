/// Dynamic programming solution to the "select the K highest of N iid draws"
/// optimal stopping problem, for an arbitrary probability density function.
///
/// At state (n, k) -- n draws remaining, k selections still to make -- the
/// optimal policy is a threshold rule: accept the current draw x iff
///   x > t(n, k) = V(n-1, k) - V(n-1, k-1)
/// where V(n, k) is the optimal expected sum of the k selected values.
/// See Kennedy (1987), "Prophet-type inequalities for multi-choice optimal
/// stopping," Stoch. Proc. Appl. 24, and Gilbert & Mosteller (1966) for the
/// K=1 special case.
library;

import 'dart:math';

/// Solves the DP for a distribution given by its pdf [f] on finite support
/// [a, b] (truncate unbounded distributions to a suitably wide interval).
class OptimalSelectionDp {
  final double Function(double x) pdf;
  final double a;
  final double b;
  final int gridSize;

  /// Grid of x-values and the cumulative CDF/partial-expectation at each,
  /// used to evaluate F(t) and ∫_t^b x f(x) dx by linear interpolation.
  late final List<double> _xs;
  late final List<double> _cdf;
  late final List<double> _partialMean;

  /// V[n][k] and t[n][k] hold the optimal value and threshold tables after
  /// [solve] is called, for 0 <= k <= n <= N.
  late final List<List<double>> V;
  late final List<List<double>> threshold;

  OptimalSelectionDp(this.pdf,
      {this.a = 0, this.b = 1, this.gridSize = 20000}) {
    _buildGrid();
  }

  void _buildGrid() {
    final n = gridSize;
    final dx = (b - a) / n;
    _xs = List.generate(n + 1, (i) => a + i * dx);
    final fs = _xs.map(pdf).toList();

    _cdf = List.filled(n + 1, 0);
    _partialMean = List.filled(n + 1, 0);
    for (var i = 1; i <= n; i++) {
      final trapF = (fs[i - 1] + fs[i]) / 2 * dx;
      final trapM = (_xs[i - 1] * fs[i - 1] + _xs[i] * fs[i]) / 2 * dx;
      _cdf[i] = _cdf[i - 1] + trapF;
      _partialMean[i] = _partialMean[i - 1] + trapM;
    }
    // Normalize in case the pdf doesn't integrate to exactly 1 on [a, b].
    final total = _cdf[n];
    if (total > 0) {
      for (var i = 0; i <= n; i++) {
        _cdf[i] /= total;
        _partialMean[i] /= total;
      }
    }
  }

  /// Index of the largest grid point <= x.
  int _locate(double x) {
    if (x <= a) return 0;
    if (x >= b) return gridSize;
    final dx = (b - a) / gridSize;
    return ((x - a) / dx).floor().clamp(0, gridSize - 1);
  }

  double _interp(List<double> table, double x) {
    final i = _locate(x);
    if (i >= gridSize) return table[gridSize];
    final dx = (b - a) / gridSize;
    final frac = (x - _xs[i]) / dx;
    return table[i] + frac * (table[i + 1] - table[i]);
  }

  /// CDF F(x) for x in [a, b].
  double cdf(double x) => _interp(_cdf, x.clamp(a, b));

  /// ∫_a^x t f(t) dt for x in [a, b].
  double partialMean(double x) => _interp(_partialMean, x.clamp(a, b));

  double get mean => _partialMean[gridSize];

  /// Runs the backward induction for n = 1..N, k = 0..n, and populates
  /// [V] and [threshold].
  void solve(int N) {
    V = List.generate(N + 1, (_) => List.filled(N + 1, 0));
    threshold = List.generate(N + 1, (_) => List.filled(N + 1, 0));

    for (var n = 1; n <= N; n++) {
      V[n][0] = 0;
      V[n][n] = n * mean; // forced to accept every remaining draw
      threshold[n][n] = a;
      for (var k = 1; k < n; k++) {
        final t = (V[n - 1][k] - V[n - 1][k - 1]).clamp(a, b);
        threshold[n][k] = t;
        final ft = cdf(t);
        final tailExpectation = mean - partialMean(t);
        V[n][k] =
            V[n - 1][k] * ft + V[n - 1][k - 1] * (1 - ft) + tailExpectation;
      }
    }
  }
}

void main() {
  const N = 10;
  const K = 3;

  print('Uniform[0,1], N=$N, K=$K');
  final uniform = OptimalSelectionDp((x) => 1.0, a: 0, b: 1);
  uniform.solve(N);
  _printTable(uniform, N, K);

  print('\nExponential(rate=1), truncated to [0, 30], N=$N, K=$K');
  final exponential =
      OptimalSelectionDp((x) => exp(-x), a: 0, b: 30, gridSize: 30000);
  exponential.solve(N);
  _printTable(exponential, N, K);

  print('\nStandard normal, truncated to [-8, 8], N=$N, K=$K');
  final normal = OptimalSelectionDp((x) => exp(-x * x / 2) / sqrt(2 * pi),
      a: -8, b: 8, gridSize: 30000);
  normal.solve(N);
  _printTable(normal, N, K);
}

void _printTable(OptimalSelectionDp dp, int N, int K) {
  print('  E[sum of top $K of $N draws] = ${dp.V[N][K].toStringAsFixed(6)}');
  print('  thresholds t(n, k) for k=1..$K:');
  for (var n = K; n <= N; n++) {
    final row = [
      for (var k = 1; k <= K && k <= n; k++)
        dp.threshold[n][k].toStringAsFixed(4)
    ].join('  ');
    print('    n=$n: $row');
  }
}
