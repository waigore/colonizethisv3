// dart format off
// Table-driven FirstRightProfit scenarios (Refs #3856, #3939 slices 14 / 45).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';
/// Data-driven expectations for [computeFirstRightProfitRate] scenario rows.
class FrrProfitRateExpectation {
  const FrrProfitRateExpectation({required this.expected});
  final double expected;
}
void assertFrrProfitRateExpectation(double result, FrrProfitRateExpectation expectation) {
  final expected = expectation.expected;
  if (expected == kFirstRightMaxProfitRate || expected == 0.0) {
    expect(result, expected);
  } else {
    expect(result, closeTo(expected, 1e-12));
  }
}
/// Data-driven expectations for [computeFirstRightProfit] scenario rows.
class FrrProfitExpectation {
  const FrrProfitExpectation({this.expectZero = false, this.profitRate, this.profitTreasury});
  final bool expectZero;
  final double? profitRate;
  final double? profitTreasury;
}
void assertFrrProfitExpectation(FirstRightProfit result, FrrProfitExpectation expectation) {
  if (expectation.expectZero) {
    expect(result, FirstRightProfit.zero);
    expect(result.profitTreasury, 0.0);
    return;
  }
  if (expectation.profitRate != null) {
    expect(result.profitRate, closeTo(expectation.profitRate!, 1e-12));
  }
  if (expectation.profitTreasury != null) {
    expect(result.profitTreasury, closeTo(expectation.profitTreasury!, 1e-12));
  }
}
/// Data-driven expectations for [computeEmbassyKickback] scenario rows.
class EmbassyKickbackExpectation {
  const EmbassyKickbackExpectation({required this.expected});
  final double expected;
}
void assertEmbassyKickbackExpectation(double result, EmbassyKickbackExpectation expectation) {
  expect(result, closeTo(expectation.expected, 1e-12));
}
/// One row for [computeFirstRightProfitRate] scenario tables.
typedef FirstRightProfitRateScenario = ({String label, int score, void Function(double result) verify, String? refs});
FirstRightProfitRateScenario frrProfitRateRow(String label, int score, double expected) => (label: label, score: score, refs: null, verify: (result) => assertFrrProfitRateExpectation(result, FrrProfitRateExpectation(expected: expected)));
/// Canonical scenarios for [computeFirstRightProfitRate].
List<FirstRightProfitRateScenario> firstRightProfitRateScenarios() => [frrProfitRateRow('returns 0.0 at relationScore 0', 0, 0.0), frrProfitRateRow('returns 0.75 at relationScore 75', 75, 0.75), frrProfitRateRow('returns 1.0 at relationScore 100', 100, kFirstRightMaxProfitRate), frrProfitRateRow('returns 0.0 at relationScore -25', -25, 0.0), frrProfitRateRow('returns 1.0 at relationScore 150', 150, kFirstRightMaxProfitRate)];
/// One row for [computeFirstRightProfit] scenario tables.
typedef FirstRightProfitScenario = ({String label, int relationScore, int filledQuantity, double pricePerUnit, void Function(FirstRightProfit result) verify, String? refs});
FirstRightProfitScenario frrProfitRow({required String label, required int relationScore, required int filledQuantity, required double pricePerUnit, bool expectZero = false, double? profitRate, double? profitTreasury}) => (label: label, relationScore: relationScore, filledQuantity: filledQuantity, pricePerUnit: pricePerUnit, refs: null, verify: (result) => assertFrrProfitExpectation(result, expectZero ? const FrrProfitExpectation(expectZero: true) : FrrProfitExpectation(profitRate: profitRate, profitTreasury: profitTreasury)));
/// Canonical scenarios for [computeFirstRightProfit].
List<FirstRightProfitScenario> firstRightProfitScenarios() => [
  frrProfitRow(label: 'relationScore 0, qty 10 @ 5.0 → rate 0.0, treasury 0.0', relationScore: 0, filledQuantity: 10, pricePerUnit: 5.0, expectZero: true),
  frrProfitRow(label: 'relationScore 75, qty 10 @ 5.0 → rate 0.75, treasury 37.5', relationScore: 75, filledQuantity: 10, pricePerUnit: 5.0, profitRate: 0.75, profitTreasury: 37.5),
  frrProfitRow(label: 'relationScore 100, qty 1 @ 1.0 → rate 1.0, treasury 1.0', relationScore: 100, filledQuantity: 1, pricePerUnit: 1.0, profitRate: kFirstRightMaxProfitRate, profitTreasury: 1.0),
  frrProfitRow(label: 'relationScore 100, qty 4 @ 2.5 → rate 1.0, treasury 10.0', relationScore: 100, filledQuantity: 4, pricePerUnit: 2.5, profitRate: kFirstRightMaxProfitRate, profitTreasury: 10.0),
  frrProfitRow(label: 'relationScore 100, qty 0 @ 5.0 → rate 0.0, treasury 0.0', relationScore: 100, filledQuantity: 0, pricePerUnit: 5.0, expectZero: true),
  frrProfitRow(label: 'relationScore 100, qty 10 @ 0.0 → rate 0.0, treasury 0.0', relationScore: 100, filledQuantity: 10, pricePerUnit: 0.0, expectZero: true),
  frrProfitRow(label: 'relationScore 100, qty -5 @ 5.0 → rate 0.0, treasury 0.0', relationScore: 100, filledQuantity: -5, pricePerUnit: 5.0, expectZero: true),
  frrProfitRow(label: 'relationScore 100, qty 5 @ -1.0 → rate 0.0, treasury 0.0', relationScore: 100, filledQuantity: 5, pricePerUnit: -1.0, expectZero: true),
];
/// One row for [computeEmbassyKickback] scenario tables.
typedef EmbassyKickbackScenario = ({String label, num relationScore, int filledQuantity, double pricePerUnit, void Function(double result) verify, String? refs});
EmbassyKickbackScenario embassyKickbackRow(String label, num relationScore, int filledQuantity, double pricePerUnit, double expected) => (label: label, relationScore: relationScore, filledQuantity: filledQuantity, pricePerUnit: pricePerUnit, refs: null, verify: (result) => assertEmbassyKickbackExpectation(result, EmbassyKickbackExpectation(expected: expected)));
/// Canonical scenarios for [computeEmbassyKickback].
List<EmbassyKickbackScenario> embassyKickbackScenarios() => [embassyKickbackRow('relation 100, 10 @ 20.0 → 20.0', 100, 10, 20.0, 20.0), embassyKickbackRow('relation 50, 10 @ 20.0 → 10.0', 50, 10, 20.0, 10.0), embassyKickbackRow('relation 80.0, 4 @ 2.5 → 0.8', 80.0, 4, 2.5, 0.8), embassyKickbackRow('relation 0, 10 @ 20.0 → 0.0', 0, 10, 20.0, 0.0), embassyKickbackRow('relation 100, -5 @ 20.0 → 0.0', 100, -5, 20.0, 0.0), embassyKickbackRow('relation 100, 10 @ 0.0 → 0.0', 100, 10, 0.0, 0.0), embassyKickbackRow('relation 150, 10 @ 20.0 → 20.0', 150, 10, 20.0, 20.0)];
/// Runs a [computeFirstRightProfitRate] scenario row.
void runFirstRightProfitRateScenario(FirstRightProfitRateScenario scenario) {
  scenario.verify(computeFirstRightProfitRate(scenario.score));
}
/// Runs a [computeFirstRightProfit] scenario row.
void runFirstRightProfitScenario(FirstRightProfitScenario scenario) {
  scenario.verify(computeFirstRightProfit(relationScore: scenario.relationScore, filledQuantity: scenario.filledQuantity, pricePerUnit: scenario.pricePerUnit));
}
/// Runs a [computeEmbassyKickback] scenario row.
void runEmbassyKickbackScenario(EmbassyKickbackScenario scenario) {
  scenario.verify(computeEmbassyKickback(relationScore: scenario.relationScore, filledQuantity: scenario.filledQuantity, pricePerUnit: scenario.pricePerUnit));
}
// dart format on
