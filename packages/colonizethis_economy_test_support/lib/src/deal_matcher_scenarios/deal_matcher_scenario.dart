// DealMatcher scenario row + runner (Refs #3836, #3939).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../scenario_runner.dart';
import 'deal_matcher_expectations.dart';

class DealMatcherScenario implements RefsScenario {
  const DealMatcherScenario({
    required this.label,
    required this.inputs,
    required this.verify,
    this.deterministicRerun = false,
    this.refs,
  });

  final String label;
  final DealMatchInputs inputs;
  final void Function(DealMatchResult result) verify;
  final bool deterministicRerun;
  final String? refs;
}

/// Compact expect-wired row (Refs #3939 slice 59).
DealMatcherScenario matcherRow({
  required String label,
  required DealMatchInputs inputs,
  required DealMatchExpectation expect,
  bool deterministicRerun = false,
  String? refs,
}) => DealMatcherScenario(
  label: label,
  inputs: inputs,
  verify: (result) => assertDealMatchExpectation(result, expect),
  deterministicRerun: deterministicRerun,
  refs: refs,
);

void runDealMatcherScenario(DealMatcherScenario scenario) {
  final result = DealMatcher.matchDeals(scenario.inputs);
  scenario.verify(result);
  if (scenario.deterministicRerun) {
    final rerun = DealMatcher.matchDeals(scenario.inputs);
    expect(result.filledDeals, equals(rerun.filledDeals));
    expect(
      result.unfilledBidsByFactionId.keys.toList()..sort(),
      equals(rerun.unfilledBidsByFactionId.keys.toList()..sort()),
    );
  }
}
