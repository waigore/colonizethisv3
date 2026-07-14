// dart format off
// Compact First Right profit and embassy-kickback assertions (Refs #3939 phase 3 slice 14).
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
// dart format on
