// DealMatcher scenario row + runner (Refs #3836, #3939).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'deal_matcher_expectations.dart';
// dart format off
/// One row for DealMatcher scenario tables (Refs #3939 slice 63).
typedef DealMatcherScenario = ({String label, DealMatchInputs inputs, void Function(DealMatchResult result) verify, bool deterministicRerun, String? refs});
/// Compact expect-wired row (Refs #3939 slice 59).
DealMatcherScenario matcherRow({required String label, required DealMatchInputs inputs, required DealMatchExpectation expect, bool deterministicRerun = false, String? refs}) =>
    (label: label, inputs: inputs, verify: (result) => assertDealMatchExpectation(result, expect), deterministicRerun: deterministicRerun, refs: refs);
void runDealMatcherScenario(DealMatcherScenario scenario) {
  final result = DealMatcher.matchDeals(scenario.inputs);
  scenario.verify(result);
  if (scenario.deterministicRerun) {
    final rerun = DealMatcher.matchDeals(scenario.inputs);
    expect(result.filledDeals, equals(rerun.filledDeals));
    expect(result.unfilledBidsByFactionId.keys.toList()..sort(), equals(rerun.unfilledBidsByFactionId.keys.toList()..sort()));
  }
}
// dart format on
