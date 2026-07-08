// Table-driven FirstRightProfit scenarios (Refs #3856, #3939 phase 3 slice 14).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'frr_profit_expectations.dart';

/// One row for [computeFirstRightProfitRate] scenario tables.
class FirstRightProfitRateScenario {
  const FirstRightProfitRateScenario({
    required this.label,
    required this.score,
    required this.verify,
    this.refs,
  });

  FirstRightProfitRateScenario.expect({
    required String label,
    required int score,
    required FrrProfitRateExpectation expect,
    String? refs,
  }) : this(
          label: label,
          score: score,
          verify: (result) => assertFrrProfitRateExpectation(result, expect),
          refs: refs,
        );

  final String label;
  final int score;
  final void Function(double result) verify;
  final String? refs;
}

/// Canonical scenarios for [computeFirstRightProfitRate].
List<FirstRightProfitRateScenario> firstRightProfitRateScenarios() => [
  FirstRightProfitRateScenario.expect(
    label: 'returns 0.0 at relationScore 0',
    score: 0,
    expect: const FrrProfitRateExpectation(expected: 0.0),
  ),
  FirstRightProfitRateScenario.expect(
    label: 'returns 0.75 at relationScore 75',
    score: 75,
    expect: const FrrProfitRateExpectation(expected: 0.75),
  ),
  FirstRightProfitRateScenario.expect(
    label: 'returns 1.0 at relationScore 100',
    score: 100,
    expect: const FrrProfitRateExpectation(expected: kFirstRightMaxProfitRate),
  ),
  FirstRightProfitRateScenario.expect(
    label: 'returns 0.0 at relationScore -25',
    score: -25,
    expect: const FrrProfitRateExpectation(expected: 0.0),
  ),
  FirstRightProfitRateScenario.expect(
    label: 'returns 1.0 at relationScore 150',
    score: 150,
    expect: const FrrProfitRateExpectation(expected: kFirstRightMaxProfitRate),
  ),
];

/// One row for [computeFirstRightProfit] scenario tables.
class FirstRightProfitScenario {
  const FirstRightProfitScenario({
    required this.label,
    required this.relationScore,
    required this.filledQuantity,
    required this.pricePerUnit,
    required this.verify,
    this.refs,
  });

  FirstRightProfitScenario.expect({
    required String label,
    required int relationScore,
    required int filledQuantity,
    required double pricePerUnit,
    required FrrProfitExpectation expect,
    String? refs,
  }) : this(
          label: label,
          relationScore: relationScore,
          filledQuantity: filledQuantity,
          pricePerUnit: pricePerUnit,
          verify: (result) => assertFrrProfitExpectation(result, expect),
          refs: refs,
        );

  final String label;
  final int relationScore;
  final int filledQuantity;
  final double pricePerUnit;
  final void Function(FirstRightProfit result) verify;
  final String? refs;
}

/// Canonical scenarios for [computeFirstRightProfit].
List<FirstRightProfitScenario> firstRightProfitScenarios() => [
  FirstRightProfitScenario.expect(
    label: 'relationScore 0, qty 10 @ 5.0 → rate 0.0, treasury 0.0',
    relationScore: 0,
    filledQuantity: 10,
    pricePerUnit: 5.0,
    expect: const FrrProfitExpectation(expectZero: true),
  ),
  FirstRightProfitScenario.expect(
    label: 'relationScore 75, qty 10 @ 5.0 → rate 0.75, treasury 37.5',
    relationScore: 75,
    filledQuantity: 10,
    pricePerUnit: 5.0,
    expect: const FrrProfitExpectation(
      profitRate: 0.75,
      profitTreasury: 37.5,
    ),
  ),
  FirstRightProfitScenario.expect(
    label: 'relationScore 100, qty 1 @ 1.0 → rate 1.0, treasury 1.0',
    relationScore: 100,
    filledQuantity: 1,
    pricePerUnit: 1.0,
    expect: const FrrProfitExpectation(
      profitRate: kFirstRightMaxProfitRate,
      profitTreasury: 1.0,
    ),
  ),
  FirstRightProfitScenario.expect(
    label: 'relationScore 100, qty 4 @ 2.5 → rate 1.0, treasury 10.0',
    relationScore: 100,
    filledQuantity: 4,
    pricePerUnit: 2.5,
    expect: const FrrProfitExpectation(
      profitRate: kFirstRightMaxProfitRate,
      profitTreasury: 10.0,
    ),
  ),
  FirstRightProfitScenario.expect(
    label: 'relationScore 100, qty 0 @ 5.0 → rate 0.0, treasury 0.0',
    relationScore: 100,
    filledQuantity: 0,
    pricePerUnit: 5.0,
    expect: const FrrProfitExpectation(expectZero: true),
  ),
  FirstRightProfitScenario.expect(
    label: 'relationScore 100, qty 10 @ 0.0 → rate 0.0, treasury 0.0',
    relationScore: 100,
    filledQuantity: 10,
    pricePerUnit: 0.0,
    expect: const FrrProfitExpectation(expectZero: true),
  ),
  FirstRightProfitScenario.expect(
    label: 'relationScore 100, qty -5 @ 5.0 → rate 0.0, treasury 0.0',
    relationScore: 100,
    filledQuantity: -5,
    pricePerUnit: 5.0,
    expect: const FrrProfitExpectation(expectZero: true),
  ),
  FirstRightProfitScenario.expect(
    label: 'relationScore 100, qty 5 @ -1.0 → rate 0.0, treasury 0.0',
    relationScore: 100,
    filledQuantity: 5,
    pricePerUnit: -1.0,
    expect: const FrrProfitExpectation(expectZero: true),
  ),
];

/// One row for [computeEmbassyKickback] scenario tables.
class EmbassyKickbackScenario {
  const EmbassyKickbackScenario({
    required this.label,
    required this.relationScore,
    required this.filledQuantity,
    required this.pricePerUnit,
    required this.verify,
    this.refs,
  });

  EmbassyKickbackScenario.expect({
    required String label,
    required num relationScore,
    required int filledQuantity,
    required double pricePerUnit,
    required EmbassyKickbackExpectation expect,
    String? refs,
  }) : this(
          label: label,
          relationScore: relationScore,
          filledQuantity: filledQuantity,
          pricePerUnit: pricePerUnit,
          verify: (result) => assertEmbassyKickbackExpectation(result, expect),
          refs: refs,
        );

  final String label;
  final num relationScore;
  final int filledQuantity;
  final double pricePerUnit;
  final void Function(double result) verify;
  final String? refs;
}

/// Canonical scenarios for [computeEmbassyKickback].
List<EmbassyKickbackScenario> embassyKickbackScenarios() => [
  EmbassyKickbackScenario.expect(
    label: 'relation 100, 10 @ 20.0 → 20.0',
    relationScore: 100,
    filledQuantity: 10,
    pricePerUnit: 20.0,
    expect: const EmbassyKickbackExpectation(expected: 20.0),
  ),
  EmbassyKickbackScenario.expect(
    label: 'relation 50, 10 @ 20.0 → 10.0',
    relationScore: 50,
    filledQuantity: 10,
    pricePerUnit: 20.0,
    expect: const EmbassyKickbackExpectation(expected: 10.0),
  ),
  EmbassyKickbackScenario.expect(
    label: 'relation 80.0, 4 @ 2.5 → 0.8',
    relationScore: 80.0,
    filledQuantity: 4,
    pricePerUnit: 2.5,
    expect: const EmbassyKickbackExpectation(expected: 0.8),
  ),
  EmbassyKickbackScenario.expect(
    label: 'relation 0, 10 @ 20.0 → 0.0',
    relationScore: 0,
    filledQuantity: 10,
    pricePerUnit: 20.0,
    expect: const EmbassyKickbackExpectation(expected: 0.0),
  ),
  EmbassyKickbackScenario.expect(
    label: 'relation 100, -5 @ 20.0 → 0.0',
    relationScore: 100,
    filledQuantity: -5,
    pricePerUnit: 20.0,
    expect: const EmbassyKickbackExpectation(expected: 0.0),
  ),
  EmbassyKickbackScenario.expect(
    label: 'relation 100, 10 @ 0.0 → 0.0',
    relationScore: 100,
    filledQuantity: 10,
    pricePerUnit: 0.0,
    expect: const EmbassyKickbackExpectation(expected: 0.0),
  ),
  EmbassyKickbackScenario.expect(
    label: 'relation 150, 10 @ 20.0 → 20.0',
    relationScore: 150,
    filledQuantity: 10,
    pricePerUnit: 20.0,
    expect: const EmbassyKickbackExpectation(expected: 20.0),
  ),
];

/// Runs a [computeFirstRightProfitRate] scenario row.
void runFirstRightProfitRateScenario(FirstRightProfitRateScenario scenario) {
  scenario.verify(computeFirstRightProfitRate(scenario.score));
}

/// Runs a [computeFirstRightProfit] scenario row.
void runFirstRightProfitScenario(FirstRightProfitScenario scenario) {
  scenario.verify(
    computeFirstRightProfit(
      relationScore: scenario.relationScore,
      filledQuantity: scenario.filledQuantity,
      pricePerUnit: scenario.pricePerUnit,
    ),
  );
}

/// Runs a [computeEmbassyKickback] scenario row.
void runEmbassyKickbackScenario(EmbassyKickbackScenario scenario) {
  scenario.verify(
    computeEmbassyKickback(
      relationScore: scenario.relationScore,
      filledQuantity: scenario.filledQuantity,
      pricePerUnit: scenario.pricePerUnit,
    ),
  );
}
