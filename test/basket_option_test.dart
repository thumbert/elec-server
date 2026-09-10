import 'package:test/test.dart';

import '../docs/basket_option/main.dart' as basket;

void main() {
  test('simulate creates iterative price paths from the provided start values',
      () {
    final start = (power: 80.0, gas: 3.0, rggi: 4.0);
    final result = basket.simulate(
      start: start,
      growthRate: (power: 0.0005, gas: 0.0006, rggi: 0.0004),
      volatility: (power: 0.02, gas: 0.03, rggi: 0.01),
      correlationMatrix: [
        [1.0, 0.8, 0.5],
        [0.8, 1.0, 0.0],
        [0.5, 0.0, 1.0],
      ],
      numSimulations: 3,
      numSteps: 5,
    );

    expect(result.power, hasLength(3));
    expect(result.gas, hasLength(3));
    expect(result.rggi, hasLength(3));
    expect(result.power.first, hasLength(6));
    expect(result.gas.first, hasLength(6));
    expect(result.rggi.first, hasLength(6));
    expect(result.power.first.first, equals(start.power));
    expect(result.gas.first.first, equals(start.gas));
    expect(result.rggi.first.first, equals(start.rggi));
    expect(result.power.first.skip(1).every((value) => value > 0), isTrue);
    expect(result.gas.first.skip(1).every((value) => value > 0), isTrue);
    expect(result.rggi.first.skip(1).every((value) => value > 0), isTrue);
  });
}
