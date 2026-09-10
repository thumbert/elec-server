import 'package:test/test.dart';

import '../../../docs/basket_option/main.dart' as basket;

void main() {
  test('simulate produces positive correlated prices for each asset', () {
    final result = basket.simulate(
      start: (power: 80.0, gas: 3.0, rggi: 4.0),
      growthRate: (power: 80.0, gas: 3.0, rggi: 4.0),
      volatility: (power: 0.2, gas: 0.3, rggi: 0.1),
      correlationMatrix: [
        [1.0, 0.8, 0.5],
        [0.8, 1.0, 0.0],
        [0.5, 0.0, 1.0],
      ],
      numSimulations: 5,
      numSteps: 10,
    );

    expect(result.power, hasLength(5));
    expect(result.gas, hasLength(5));
    expect(result.rggi, hasLength(5));
  });
}
