library test.db.risk_system.calculator_examples;

/// One leg
Map<String, dynamic> calc1() => <String, dynamic>{
      'userId': 'e42111',
      'calculatorName': 'isone Q1, 2021 5x16',
      'calculatorType': 'elec_swap',
      'term': 'Jan21-Mar21',
      'buy/sell': 'Buy',
      'comments': 'a simple calculator for winter times',
      'legs': [
        {
          'curveId': 'isone_energy_4000_da_lmp',
          'tzLocation': 'America/New_York',
          'bucket': '5x16',
          'cash/physical': 'cash',
          'quantity': {
            'value': 50.0,
          },
          'fixPrice': {
            'value': 50.5,
          },
        }
      ],
    };

/// One leg
Map<String, dynamic> calc2() => <String, dynamic>{
      'userId': 'e11111',
      'calculatorName': 'custom monthly quantities, 1 leg',
      'calculatorType': 'elec_swap',
      'term': 'Jan21-Mar21',
      'buy/sell': 'Buy',
      'comments': 'a simple calculator for winter times',
      'legs': [
        {
          'curveId': 'isone_energy_4000_da_lmp',
          'tzLocation': 'America/New_York',
          'bucket': '5x16',
          'quantity': {
            'value': [
              {'month': '2021-01', 'value': 50},
              {'month': '2021-02', 'value': 25},
              {'month': '2021-03', 'value': 10},
            ]
          },
          'fixPrice': {
            'value': [
              {'month': '2021-01', 'value': 70.5},
              {'month': '2021-02', 'value': 68.0},
              {'month': '2021-03', 'value': 47.5},
            ]
          },
        }
      ],
    };

/// Two legs
Map<String, dynamic> calc3() => <String, dynamic>{
      'userId': 'e11111',
      'calculatorName': 'custom monthly quantities, 2 legs',
      'calculatorType': 'elec_swap',
      'term': 'Jan21-Mar21',
      'asOfDate': '2020-05-29',
      'buy/sell': 'Buy',
      'comments': 'a simple calculator for winter times',
      'legs': [
        {
          'curveId': 'isone_energy_4000_da_lmp',
          'tzLocation': 'America/New_York',
          'bucket': 'peak',
          'quantity': {
            'value': 50,
          },
        },
        {
          'curveId': 'isone_energy_4000_da_lmp',
          'tzLocation': 'America/New_York',
          'bucket': 'offpeak',
          'quantity': {
            'value': 50,
          },
        },
      ],
    };
