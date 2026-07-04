// Table-driven FirstRightProfit scenarios (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

/// One row in [firstRightProfitRateScenarios].
typedef FirstRightProfitRateScenario = ({
  String label,
  int score,
  double expected,
  String? refs,
});

/// Canonical scenarios for [computeFirstRightProfitRate].
const List<FirstRightProfitRateScenario> firstRightProfitRateScenarios = [
  (
    label: 'returns 0.0 at relationScore 0',
    score: 0,
    expected: 0.0,
    refs: null,
  ),
  (
    label: 'returns 0.75 at relationScore 75',
    score: 75,
    expected: 0.75,
    refs: null,
  ),
  (
    label: 'returns 1.0 at relationScore 100',
    score: 100,
    expected: kFirstRightMaxProfitRate,
    refs: null,
  ),
  (
    label: 'returns 0.0 at relationScore -25',
    score: -25,
    expected: 0.0,
    refs: null,
  ),
  (
    label: 'returns 1.0 at relationScore 150',
    score: 150,
    expected: kFirstRightMaxProfitRate,
    refs: null,
  ),
];

/// One row in [firstRightProfitScenarios].
typedef FirstRightProfitScenario = ({
  String label,
  int relationScore,
  int filledQuantity,
  double pricePerUnit,
  double expectedRate,
  double expectedTreasury,
  bool expectZero,
  String? refs,
});

/// Canonical scenarios for [computeFirstRightProfit].
const List<FirstRightProfitScenario> firstRightProfitScenarios = [
  (
    label: 'relationScore 0, qty 10 @ 5.0 → rate 0.0, treasury 0.0',
    relationScore: 0,
    filledQuantity: 10,
    pricePerUnit: 5.0,
    expectedRate: 0.0,
    expectedTreasury: 0.0,
    expectZero: true,
    refs: null,
  ),
  (
    label: 'relationScore 75, qty 10 @ 5.0 → rate 0.75, treasury 37.5',
    relationScore: 75,
    filledQuantity: 10,
    pricePerUnit: 5.0,
    expectedRate: 0.75,
    expectedTreasury: 37.5,
    expectZero: false,
    refs: null,
  ),
  (
    label: 'relationScore 100, qty 1 @ 1.0 → rate 1.0, treasury 1.0',
    relationScore: 100,
    filledQuantity: 1,
    pricePerUnit: 1.0,
    expectedRate: kFirstRightMaxProfitRate,
    expectedTreasury: 1.0,
    expectZero: false,
    refs: null,
  ),
  (
    label: 'relationScore 100, qty 4 @ 2.5 → rate 1.0, treasury 10.0',
    relationScore: 100,
    filledQuantity: 4,
    pricePerUnit: 2.5,
    expectedRate: kFirstRightMaxProfitRate,
    expectedTreasury: 10.0,
    expectZero: false,
    refs: null,
  ),
  (
    label: 'relationScore 100, qty 0 @ 5.0 → rate 0.0, treasury 0.0',
    relationScore: 100,
    filledQuantity: 0,
    pricePerUnit: 5.0,
    expectedRate: 0.0,
    expectedTreasury: 0.0,
    expectZero: true,
    refs: null,
  ),
  (
    label: 'relationScore 100, qty 10 @ 0.0 → rate 0.0, treasury 0.0',
    relationScore: 100,
    filledQuantity: 10,
    pricePerUnit: 0.0,
    expectedRate: 0.0,
    expectedTreasury: 0.0,
    expectZero: true,
    refs: null,
  ),
  (
    label: 'relationScore 100, qty -5 @ 5.0 → rate 0.0, treasury 0.0',
    relationScore: 100,
    filledQuantity: -5,
    pricePerUnit: 5.0,
    expectedRate: 0.0,
    expectedTreasury: 0.0,
    expectZero: true,
    refs: null,
  ),
  (
    label: 'relationScore 100, qty 5 @ -1.0 → rate 0.0, treasury 0.0',
    relationScore: 100,
    filledQuantity: 5,
    pricePerUnit: -1.0,
    expectedRate: 0.0,
    expectedTreasury: 0.0,
    expectZero: true,
    refs: null,
  ),
];

/// One row in [embassyKickbackScenarios].
typedef EmbassyKickbackScenario = ({
  String label,
  num relationScore,
  int filledQuantity,
  double pricePerUnit,
  double expected,
  String? refs,
});

/// Canonical scenarios for [computeEmbassyKickback].
const List<EmbassyKickbackScenario> embassyKickbackScenarios = [
  (
    label: 'relation 100, 10 @ 20.0 → 20.0',
    relationScore: 100,
    filledQuantity: 10,
    pricePerUnit: 20.0,
    expected: 20.0,
    refs: null,
  ),
  (
    label: 'relation 50, 10 @ 20.0 → 10.0',
    relationScore: 50,
    filledQuantity: 10,
    pricePerUnit: 20.0,
    expected: 10.0,
    refs: null,
  ),
  (
    label: 'relation 80.0, 4 @ 2.5 → 0.8',
    relationScore: 80.0,
    filledQuantity: 4,
    pricePerUnit: 2.5,
    expected: 0.8,
    refs: null,
  ),
  (
    label: 'relation 0, 10 @ 20.0 → 0.0',
    relationScore: 0,
    filledQuantity: 10,
    pricePerUnit: 20.0,
    expected: 0.0,
    refs: null,
  ),
  (
    label: 'relation 100, -5 @ 20.0 → 0.0',
    relationScore: 100,
    filledQuantity: -5,
    pricePerUnit: 20.0,
    expected: 0.0,
    refs: null,
  ),
  (
    label: 'relation 100, 10 @ 0.0 → 0.0',
    relationScore: 100,
    filledQuantity: 10,
    pricePerUnit: 0.0,
    expected: 0.0,
    refs: null,
  ),
  (
    label: 'relation 150, 10 @ 20.0 → 20.0',
    relationScore: 150,
    filledQuantity: 10,
    pricePerUnit: 20.0,
    expected: 20.0,
    refs: null,
  ),
];

/// Runs a [computeFirstRightProfitRate] scenario row.
void runFirstRightProfitRateScenario(FirstRightProfitRateScenario scenario) {
  final result = computeFirstRightProfitRate(scenario.score);
  if (scenario.expected == kFirstRightMaxProfitRate || scenario.expected == 0.0) {
    expect(result, scenario.expected);
  } else {
    expect(result, closeTo(scenario.expected, 1e-12));
  }
}

/// Runs a [computeFirstRightProfit] scenario row.
void runFirstRightProfitScenario(FirstRightProfitScenario scenario) {
  final result = computeFirstRightProfit(
    relationScore: scenario.relationScore,
    filledQuantity: scenario.filledQuantity,
    pricePerUnit: scenario.pricePerUnit,
  );
  if (scenario.expectZero) {
    expect(result, FirstRightProfit.zero);
    expect(result.profitTreasury, 0.0);
  } else {
    expect(result.profitRate, closeTo(scenario.expectedRate, 1e-12));
    expect(result.profitTreasury, closeTo(scenario.expectedTreasury, 1e-12));
  }
}

/// Runs a [computeEmbassyKickback] scenario row.
void runEmbassyKickbackScenario(EmbassyKickbackScenario scenario) {
  expect(
    computeEmbassyKickback(
      relationScore: scenario.relationScore,
      filledQuantity: scenario.filledQuantity,
      pricePerUnit: scenario.pricePerUnit,
    ),
    closeTo(scenario.expected, 1e-12),
  );
}
